import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'files.dart';
import 'format.dart';
import 'l10n.dart';
import 'model.dart';

/// Sync through a shared folder (Syncthing…). Same layout as the desktop app
/// (ledger-core `folder.rs`): **one file per device** — each device writes
/// only `ledger-<device>.json` and merges everybody else's `ledger-*.json`.
/// Nobody writes the same file, so Syncthing never sees a conflict.

const _prefix = 'ledger-';
const _suffix = '.json';

String deviceFileName(String deviceId) => '$_prefix$deviceId$_suffix';
bool isPeerFile(String name, String own) =>
    name.startsWith(_prefix) && name.endsWith(_suffix) && name != own;
bool isConflictCopy(String name) => name.contains('.sync-conflict-');

class FolderFile {
  const FolderFile(this.id, this.name, this.modified);
  final String id;
  final String name;
  final int modified;
}

/// Where the shared files live. Android: [SafFolder]. Tests: [MemoryFolder].
abstract class FolderBackend {
  Future<List<FolderFile>> list();
  Future<String> read(FolderFile f);
  Future<void> write(String name, String content);
  Future<void> delete(FolderFile f);
}

/// A folder picked with Android's document tree picker (see FolderChannel.kt).
class SafFolder implements FolderBackend {
  SafFolder(this.tree);
  final String tree;
  static const ch = MethodChannel('ledger/folder');

  /// Opens the system folder picker. Returns (uri, name) or null.
  static Future<(String, String)?> pick() async {
    final r = await ch.invokeMapMethod<String, dynamic>('pick');
    return r == null ? null : (r['uri'] as String, r['name'] as String);
  }

  /// Folder name, or null when the permission was lost.
  Future<String?> name() => ch.invokeMethod<String>('name', {'tree': tree});
  Future<void> release() => ch.invokeMethod('release', {'tree': tree});

  @override
  Future<List<FolderFile>> list() async {
    final r = await ch.invokeListMethod<Map>('list', {'tree': tree}) ?? [];
    return [
      for (final m in r)
        FolderFile(
          m['id'] as String,
          m['name'] as String,
          (m['modified'] as num?)?.toInt() ?? 0,
        ),
    ];
  }

  @override
  Future<String> read(FolderFile f) async =>
      await ch.invokeMethod<String>('read', {'tree': tree, 'id': f.id}) ?? '';

  @override
  Future<void> write(String name, String content) => ch.invokeMethod('write', {
    'tree': tree,
    'name': name,
    'content': content,
  });

  @override
  Future<void> delete(FolderFile f) =>
      ch.invokeMethod('delete', {'tree': tree, 'id': f.id});
}

/// A plain directory (Linux desktop build): same files as the Slint app uses.
class IoFolder implements FolderBackend {
  IoFolder(this.path);
  final String path;

  @override
  Future<List<FolderFile>> list() async {
    final dir = Directory(path);
    if (!await dir.exists()) return [];
    return [
      await for (final e in dir.list())
        if (e is File)
          FolderFile(
            e.path,
            e.uri.pathSegments.last,
            (await e.stat()).modified.millisecondsSinceEpoch,
          ),
    ];
  }

  @override
  Future<String> read(FolderFile f) => File(f.id).readAsString();

  /// Atomic: temp file + rename, so Syncthing never ships half a file.
  @override
  Future<void> write(String name, String content) async {
    await Directory(path).create(recursive: true);
    final tmp = File('$path/.$name.tmp');
    await tmp.writeAsString(content, flush: true);
    await tmp.rename('$path/$name');
  }

  @override
  Future<void> delete(FolderFile f) => File(f.id).delete();
}

/// Backend for a stored folder reference: a path (Linux) or a SAF tree URI (Android).
FolderBackend folderFor(String uri) =>
    uri.startsWith('/') ? IoFolder(uri) : SafFolder(uri);

/// Lets the user choose the sync folder. Returns (uri or path, display name).
Future<(String, String)?> pickSyncFolder() async {
  if (!_linuxDesktop) return SafFolder.pick();
  final home = Platform.environment['HOME'] ?? '';
  final start = Directory('$home/Sync/Ledger').existsSync()
      ? '$home/Sync/Ledger/'
      : '$home/';
  final path = await zenity([
    '--file-selection',
    '--directory',
    '--title=${S.current.chooseFolderTitle}',
    '--filename=$start',
  ]);
  if (path == null) return null;
  return (path, path.split('/').where((x) => x.isNotEmpty).last);
}

/// In-memory folder, shared by simulated devices in tests.
class MemoryFolder implements FolderBackend {
  final files = <String, String>{};
  final stamps = <String, int>{};
  var _clock = 0;

  @override
  Future<List<FolderFile>> list() async => [
    for (final n in files.keys) FolderFile(n, n, stamps[n] ?? 0),
  ];
  @override
  Future<String> read(FolderFile f) async => files[f.name]!;
  @override
  Future<void> write(String name, String content) async {
    files[name] = content;
    stamps[name] = ++_clock;
  }

  @override
  Future<void> delete(FolderFile f) async {
    files.remove(f.name);
    stamps.remove(f.name);
  }
}

/// Result of reading the folder: merged book + what it changes locally.
class FolderMerge {
  FolderMerge(this.merged, this.report, this.peers, this.skipped, this.files);
  final LedgerFile merged;
  final MergeReport report;
  final List<String> peers;
  final List<String> skipped;

  /// The peer files and their parsed content (for "use the folder's data").
  final List<(FolderFile, LedgerFile)> files;
}

void _addReport(MergeReport a, MergeReport b) {
  a.entriesAdded += b.entriesAdded;
  a.entriesRemoved += b.entriesRemoved;
  a.accountsAdded += b.accountsAdded;
  a.accountsUpdated += b.accountsUpdated;
  a.accountsRemoved += b.accountsRemoved;
  a.accountsKeptInUse += b.accountsKeptInUse;
  a.conflicts += b.conflicts;
}

/// Merges every peer file of [folder] into [local], without writing anything.
Future<FolderMerge> readFolder(
  FolderBackend folder,
  String ownName,
  LedgerFile local,
) async {
  var acc = local;
  final total = MergeReport();
  final peers = <String>[], skipped = <String>[];
  final files = <(FolderFile, LedgerFile)>[];
  final list =
      (await folder.list()).where((f) => isPeerFile(f.name, ownName)).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
  for (final f in list) {
    try {
      final parsed = LedgerFile.parse(await folder.read(f));
      final (m, r) = mergeFiles(acc, parsed);
      _addReport(total, r);
      acc = m;
      peers.add(f.name);
      files.add((f, parsed));
    } catch (_) {
      skipped.add(f.name); // half-synced or foreign file: try again next time
    }
  }
  return FolderMerge(acc, total, peers, skipped, files);
}

/// Demo entries of [mine] that no other device of the folder has. When others
/// already keep data there, these must not end up in their ledgers.
Set<String> demoOnlyHere(
  Iterable<Entry> mine,
  List<(FolderFile, LedgerFile)> peers,
) {
  if (peers.isEmpty) return const {};
  final theirs = {
    for (final (_, f) in peers)
      for (final e in f.entries) e.id,
  };
  return {
    for (final e in mine)
      if (isDemoEntry(e.id) && !theirs.contains(e.id)) e.id,
  };
}

/// Keeps this phone's file in the shared folder and pulls the others in.
class SyncService extends ChangeNotifier {
  SyncService(
    this.state, {
    this.onMessage,
    FolderBackend Function(String uri)? backendFor,
  }) : _backendFor = backendFor ?? folderFor;

  final AppState state;

  /// Shows a short message to the user (snack bar).
  final void Function(String message)? onMessage;
  final FolderBackend Function(String uri) _backendFor;

  static const _kDevice = 'ledger-device-id';
  static const _kFolder = 'ledger-sync-folder';
  static const _kFolderName = 'ledger-sync-folder-name';

  SharedPreferences? _prefs;
  String deviceId = '';
  String? folderUri;
  String? folderName;
  FolderBackend? _folder;
  DateTime? lastSync;
  int peers = 0;
  String? error;
  bool busy = false;
  Timer? _writeTimer;
  int _seenStamp = -1;

  bool get on => _folder != null;
  String get ownName => deviceFileName(deviceId);

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    if (state.damagedNow) {
      // The demo must never reach the shared folder, nor replace the copy of
      // the real data this device left there. With a new device id, that copy
      // becomes another device's file: reconnecting offers to bring it back.
      for (final k in [_kDevice, _kFolder, _kFolderName]) {
        await _prefs!.remove(k);
      }
    }
    deviceId = _prefs!.getString(_kDevice) ?? '';
    if (deviceId.isEmpty) {
      final platform = _linuxDesktop ? 'linux' : 'android';
      deviceId =
          '$platform-${Random().nextInt(0x1000000).toRadixString(16).padLeft(6, '0')}';
      await _prefs!.setString(_kDevice, deviceId);
    }
    folderUri = _prefs!.getString(_kFolder);
    folderName = _prefs!.getString(_kFolderName);
    if (folderUri != null) _folder = _backendFor(folderUri!);
    state.addListener(_onLocalChange);
  }

  @override
  void dispose() {
    state.removeListener(_onLocalChange);
    _writeTimer?.cancel();
    super.dispose();
  }

  /// Local edit → rewrite our file shortly after (debounced).
  void _onLocalChange() {
    if (!on) return;
    _writeTimer?.cancel();
    _writeTimer = Timer(const Duration(milliseconds: 1200), writeOwn);
  }

  Future<void> writeOwn() async {
    final f = _folder;
    if (f == null) return;
    if (busy) return _onLocalChange(); // after the sync in progress
    try {
      await _writeIfChanged(f, await f.list());
      error = null;
    } catch (e) {
      error = S.current.cannotWriteFolder(e);
    }
    notifyListeners();
  }

  /// Writes our file only when its content differs: a new date on the same
  /// content would make every other device sync and rewrite its own file in
  /// turn, endlessly.
  Future<void> _writeIfChanged(FolderBackend f, List<FolderFile> files) async {
    String? onDisk;
    try {
      final own = files.where((x) => x.name == ownName).firstOrNull;
      if (own != null) onDisk = await f.read(own);
    } catch (_) {} // unreadable: write it again
    // After the await: the latest data, not what it was before reading.
    final json = state.exportJson();
    if (json != onDisk) await f.write(ownName, json);
  }

  /// What connecting to [folder] would do, before deciding.
  Future<FolderMerge> preview(FolderBackend folder) =>
      readFolder(folder, ownName, state.snapshot());

  /// Starts syncing with [uri]. [useFolderData]: replace this phone's data by
  /// the folder's (keeps local settings) instead of merging.
  Future<MergeReport?> connect(
    String uri,
    String name, {
    FolderBackend? folder,
    bool useFolderData = false,
  }) async {
    final f = folder ?? _backendFor(uri);
    final r = await readFolder(f, ownName, state.snapshot());
    if (!useFolderData) {
      state.leaveOut(demoOnlyHere(state.entries, r.files));
    } else {
      if (r.files.isNotEmpty) {
        var acc = r.files.first.$2;
        for (final (_, b) in r.files.skip(1)) {
          acc = mergeFiles(acc, b).$1;
        }
        state.importFile(
          LedgerFile(
            accounts: acc.accounts,
            entries: acc.entries,
            deletedEntries: acc.deletedEntries,
            deletedAccounts: acc.deletedAccounts,
            mode: state.mode,
            hints: state.hints,
            khoums: state.khoums,
            theme: state.theme,
          ),
        );
      }
    }
    _folder = f;
    folderUri = uri;
    folderName = name;
    await _prefs?.setString(_kFolder, uri);
    await _prefs?.setString(_kFolderName, name);
    return syncNow();
  }

  Future<void> disconnect() async {
    _writeTimer?.cancel();
    final f = _folder;
    _folder = null;
    folderUri = null;
    folderName = null;
    lastSync = null;
    peers = 0;
    await _prefs?.remove(_kFolder);
    await _prefs?.remove(_kFolderName);
    if (f is SafFolder) await f.release();
    notifyListeners();
  }

  /// Pulls the other devices' files in, then writes ours. Returns what changed.
  Future<MergeReport?> syncNow({bool onlyIfChanged = false}) async {
    final f = _folder;
    if (f == null || busy) return null;
    busy = true;
    notifyListeners();
    try {
      final files = await f.list();
      // Fingerprint of the peers' names + dates: cheap change detection.
      final stamp = Object.hashAll([
        for (final x in files.where((x) => isPeerFile(x.name, ownName)))
          '${x.name}:${x.modified}',
      ]);
      if (onlyIfChanged && stamp == _seenStamp) return null;
      final r = await readFolder(f, ownName, state.snapshot());
      if (!r.report.isNoop) {
        // Merge again, into the data as it is *now*: the user may have typed
        // something while the files were being read. No await from here on.
        var merged = state.snapshot();
        for (final (_, peer) in r.files) {
          merged = mergeFiles(merged, peer).$1;
        }
        state.importFile(merged);
      }
      for (final (file, _) in r.files) {
        if (isConflictCopy(file.name)) await f.delete(file);
      }
      await _writeIfChanged(f, files);
      _seenStamp = stamp;
      peers = r.peers.where((p) => !isConflictCopy(p)).length;
      lastSync = DateTime.now();
      error = r.skipped.isEmpty ? null : S.current.skippedFile(r.skipped.first);
      return r.report;
    } catch (e) {
      error = S.current.syncFailed(e);
      return null;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  /// Background-friendly sync (app resumed, timer): tells the user only
  /// when something actually changed.
  Future<void> quietSync() async {
    final r = await syncNow(onlyIfChanged: true);
    if (r != null && !r.isNoop) {
      onMessage?.call(S.current.synced(describeMerge(r)));
    }
  }

  String get status {
    final l = S.current;
    if (!on) return l.off;
    final others = l.otherDevices(peers);
    final t = lastSync;
    return t == null
        ? l.connected(others)
        : l.syncedAt('${pad2(t.hour)}:${pad2(t.minute)}', others);
  }
}

/// "+3 entries, −1 entry, 1 account updated" (same wording as the desktop app).
String describeMerge(MergeReport r) => S.current.mergeSummary(
  added: r.entriesAdded,
  removed: r.entriesRemoved,
  accAdded: r.accountsAdded,
  accUpdated: r.accountsUpdated,
  accRemoved: r.accountsRemoved,
  keptInUse: r.accountsKeptInUse,
  conflicts: r.conflicts,
);

/// Lets any widget reach the sync service.
class SyncScope extends InheritedNotifier<SyncService> {
  const SyncScope({super.key, required SyncService sync, required super.child})
    : super(notifier: sync);
  static SyncService of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<SyncScope>()!.notifier!;
  static SyncService read(BuildContext c) =>
      c.getInheritedWidgetOfExactType<SyncScope>()!.notifier!;
}

/// Linux desktop build (zenity dialogs, plain folders). Uses the *target*
/// platform, not the host OS: widget tests run on Linux but target Android.
bool get _linuxDesktop => defaultTargetPlatform == TargetPlatform.linux;
