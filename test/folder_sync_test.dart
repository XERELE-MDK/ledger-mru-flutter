import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_mru/main.dart';
import 'package:ledger_mru/model.dart';
import 'package:ledger_mru/sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A simulated device: its own book + sync service, on a shared folder.
Future<(AppState, SyncService)> device(
  String id,
  MemoryFolder folder, {
  LedgerFile? from,
}) async {
  final s = AppState();
  await s.load();
  if (from != null) s.importFile(from);
  final sync = SyncService(s, backendFor: (_) => folder);
  await sync.load();
  sync.deviceId = id;
  return (s, sync);
}

/// Runs a callback in the middle of a read or a write.
class _SlowFolder extends MemoryFolder {
  void Function()? duringRead, duringWrite;

  @override
  Future<String> read(FolderFile f) async {
    final text = await super.read(f);
    final cb = f.name.startsWith('ledger-desktop') ? duringRead : null;
    if (cb != null) duringRead = null;
    cb?.call();
    return text;
  }

  @override
  Future<void> write(String name, String content) async {
    final cb = duringWrite;
    duringWrite = null;
    cb?.call();
    await super.write(name, content);
  }
}

Entry entry(String memo, double amt) => Entry(
  id: newEntryId(),
  date: '2026-11-20',
  memo: memo,
  lines: [Line('food', amt, 0), Line('cash', 0, amt)],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('two devices converge through one folder, one file each', () async {
    final folder = MemoryFolder();
    final (phone, phoneSync) = await device('android-aaaaaa', folder);
    final (pc, pcSync) = await device(
      'desktop-bbbbbb',
      folder,
      from: phone.snapshot(),
    );

    final fromPhone = entry('Taxi', 300);
    phone.addEntry(fromPhone);
    final fromPc = entry('Bread', 50);
    pc.addEntry(fromPc);
    final victim = pc.entries[2].id;
    pc.deleteEntry(victim);

    await phoneSync.connect('mem', 'Sync', folder: folder);
    final r = await pcSync.connect('mem', 'Sync', folder: folder);
    expect((r!.entriesAdded, r.entriesRemoved), (1, 0));
    final r2 = await phoneSync.syncNow();
    expect((r2!.entriesAdded, r2.entriesRemoved), (1, 1));

    for (final s in [phone, pc]) {
      expect(s.entries.any((e) => e.id == fromPhone.id), isTrue);
      expect(s.entries.any((e) => e.id == fromPc.id), isTrue);
      expect(s.entries.any((e) => e.id == victim), isFalse);
    }
    expect((await phoneSync.syncNow())!.isNoop, isTrue);
    expect((await pcSync.syncNow())!.isNoop, isTrue);
    expect(folder.files.keys.toList()..sort(), [
      'ledger-android-aaaaaa.json',
      'ledger-desktop-bbbbbb.json',
    ]);
    expect(phoneSync.status, startsWith('Synced at'));
    expect(phoneSync.peers, 1);
    phoneSync.dispose();
    pcSync.dispose();
  });

  test('a file written by the desktop app (Rust) merges in', () async {
    final folder = MemoryFolder();
    await folder.write(
      'ledger-desktop-rust01.json',
      File('test/fixtures/merge_b.json').readAsStringSync(),
    );
    final (phone, sync) = await device('android-cccccc', folder);
    final preview = await sync.preview(folder);
    expect(preview.peers, ['ledger-desktop-rust01.json']);
    expect(
      describeMerge(preview.report),
      '+2 entries, +1 account, 1 account updated',
    );
    await sync.connect('mem', 'Sync', folder: folder);
    // The phone only had the demo, which stays out of the folder.
    expect(phone.entries.map((e) => e.id).toSet(), {'e1', 'e4'});
    expect(folder.files.containsKey('ledger-android-cccccc.json'), isTrue);
    sync.dispose();
  });

  test(
    '"use folder data" replaces this phone\'s entries, keeps its settings',
    () async {
      final folder = MemoryFolder();
      await folder.write(
        'ledger-desktop-rust01.json',
        File('test/fixtures/merge_b.json').readAsStringSync(),
      );
      final (phone, sync) = await device('android-dddddd', folder);
      phone.setTheme('dark');
      await sync.connect('mem', 'Sync', folder: folder, useFolderData: true);
      expect(phone.entries.map((e) => e.id).toList()..sort(), ['e1', 'e4']);
      expect(phone.theme, 'dark');
      sync.dispose();
    },
  );

  test(
    'conflict copies are merged then removed; broken files are skipped',
    () async {
      final folder = MemoryFolder();
      final (phone, sync) = await device('android-eeeeee', folder);
      final other = phone.snapshot();
      final extra = entry('Fuel', 900);
      final otherWithExtra = LedgerFile(
        accounts: other.accounts,
        entries: [...other.entries, extra],
      );
      final otherState = AppState()..importFile(otherWithExtra);
      await folder.write(
        'ledger-desktop-x.sync-conflict-20261121-101010-ABC.json',
        otherState.exportJson(),
      );
      await folder.write('ledger-broken.json', '{ not json');
      await folder.write('notes.txt', 'ignored');
      await sync.connect('mem', 'Sync', folder: folder);
      expect(phone.entries.any((e) => e.id == extra.id), isTrue);
      expect(folder.files.keys.any(isConflictCopy), isFalse);
      expect(sync.error, contains('ledger-broken.json'));
      sync.dispose();
    },
  );

  test('a local edit rewrites this phone\'s file shortly after', () async {
    final folder = MemoryFolder();
    final (phone, sync) = await device('android-ffffff', folder);
    await sync.connect('mem', 'Sync', folder: folder);
    final e = entry('Coffee', 40);
    phone.addEntry(e);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(folder.files['ledger-android-ffffff.json'], contains(e.id));
    sync.dispose();
  });

  test('undoing a deletion survives sync', () async {
    final folder = MemoryFolder();
    final (a, sa) = await device('android-aaaaaa', folder);
    final (b, sb) = await device('linux-bbbbbb', folder, from: a.snapshot());
    await sa.connect('mem', 'Sync', folder: folder);
    await sb.connect('mem', 'Sync', folder: folder);
    final n = a.entries.length;
    final e = a.entries[3];
    bool same(Entry x) =>
        x.date == e.date && x.memo == e.memo && x.amount == e.amount;

    a.deleteEntry(e.id);
    await sa.writeOwn();
    await sb.syncNow(); // the deletion has travelled…
    a.restoreEntry(e); // …when the user hits Undo
    for (var i = 0; i < 3; i++) {
      await sa.syncNow();
      await sb.syncNow();
    }
    for (final s in [a, b]) {
      expect(s.entries.length, n);
      expect(s.entries.where(same), hasLength(1));
      expect(s.entries.any((x) => x.id == e.id), isFalse);
    }
    for (final s in [sa, sb]) {
      s.dispose();
    }
  });

  test('joining a folder does not bring the demo', () async {
    final folder = MemoryFolder();
    final (pc, spc) = await device('desktop-aaaaaa', folder);
    final demo = pc.entries.length;
    expect(pc.entries.every((e) => isDemoEntry(e.id)), isTrue);
    expect(isDemoEntry(newEntryId()), isFalse);

    // Real data in the folder, plus one demo entry that phone made its own.
    final (phone, sphone) = await device(
      'android-bbbbbb',
      folder,
      from: LedgerFile(
        accounts: pc.accounts,
        entries: [pc.entries.first, entry('Real', 50)],
      ),
    );
    // First device in an empty folder: nothing to protect, nothing dropped.
    await sphone.connect('mem', 'Sync', folder: folder);
    expect(phone.entries, hasLength(2));

    pc.addEntry(entry('Typed here', 7));
    expect(demo, greaterThan(2));
    await spc.connect('mem', 'Sync', folder: folder);
    await sphone.syncNow();
    for (final s in [pc, phone]) {
      expect(s.entries, hasLength(3));
      expect(s.entries.where((e) => isDemoEntry(e.id)), hasLength(1));
      expect(s.deletedEntries, isEmpty); // left out, not deleted everywhere
    }
    spc.dispose();
    sphone.dispose();
  });

  test('idle devices stop writing', () async {
    final folder = MemoryFolder();
    final (a, sa) = await device('android-aaaaaa', folder);
    final (b, sb) = await device('linux-bbbbbb', folder, from: a.snapshot());
    a.addEntry(entry('Bread', 50));
    b.addEntry(entry('Taxi', 300));
    await sa.connect('mem', 'Sync', folder: folder);
    await sb.connect('mem', 'Sync', folder: folder);
    Future<void> poll() async {
      for (final s in [sa, sb]) {
        await s.syncNow(onlyIfChanged: true);
      }
    }

    await poll();
    await poll();
    final settled = {...folder.stamps};
    for (var i = 0; i < 5; i++) {
      await poll();
      await sa.syncNow();
      await sb.writeOwn();
    }
    expect(folder.stamps, settled);
    expect(a.entries.length, b.entries.length);

    // A real edit still travels, then everything is quiet again.
    final e = entry('Fuel', 900);
    a.addEntry(e);
    await sa.writeOwn();
    await poll();
    await poll();
    expect(b.entries.any((x) => x.id == e.id), isTrue);
    final after = {...folder.stamps};
    await poll();
    expect(folder.stamps, after);

    // A missing or altered file of ours is put back.
    await folder.delete(FolderFile(sa.ownName, sa.ownName, 0));
    await sa.syncNow();
    expect(folder.files[sa.ownName], a.exportJson());
    folder.files[sa.ownName] = '{ cut sho';
    await sa.writeOwn();
    expect(folder.files[sa.ownName], a.exportJson());
    for (final s in [sa, sb]) {
      s.dispose();
    }
  });

  test('an entry typed while a sync is reading is not lost', () async {
    final folder = _SlowFolder();
    final (a, sa) = await device('android-aaaaaa', folder);
    final other = AppState()
      ..importFile(
        LedgerFile(
          accounts: a.accounts,
          entries: [...a.entries, entry('From the PC', 70)],
        ),
      );
    await sa.connect('mem', 'Sync', folder: folder);
    await folder.write('ledger-desktop-x.json', other.exportJson());

    final typed = entry('Typed meanwhile', 12);
    folder.duringRead = () => a.addEntry(typed);
    await sa.syncNow();
    expect(a.entries.any((e) => e.memo == 'From the PC'), isTrue);
    expect(a.entries.any((e) => e.id == typed.id), isTrue);
    expect(folder.files[sa.ownName], contains(typed.id));

    // Typed at the very end, while our file is being written: sent soon after.
    final late = entry('Typed last', 13);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    await folder.delete(FolderFile(sa.ownName, sa.ownName, 0));
    folder.duringWrite = () => a.addEntry(late); // no other write is pending
    await sa.syncNow();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(folder.files[sa.ownName], contains(late.id));
    sa.dispose();
  });

  testWidgets('Settings → Choose sync folder → Merge, through the real UI', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    // Android's folder picker + document calls, backed by an in-memory folder.
    final folder = MemoryFolder();
    await folder.write(
      'ledger-desktop-rust01.json',
      File('test/fixtures/merge_b.json').readAsStringSync(),
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SafFolder.ch,
      (call) async {
        final a = (call.arguments as Map?) ?? {};
        switch (call.method) {
          case 'pick':
            return {'uri': 'content://tree/Sync', 'name': 'Sync'};
          case 'list':
            return [
              for (final f in await folder.list())
                {'id': f.id, 'name': f.name, 'modified': f.modified},
            ];
          case 'read':
            return folder.files[a['id']];
          case 'write':
            await folder.write(a['name'] as String, a['content'] as String);
            return true;
          case 'delete':
            folder.files.remove(a['id']);
            return true;
          case 'name':
            return 'Sync';
          default:
            return true;
        }
      },
    );
    final s = AppState();
    await s.load();
    final sync = SyncService(s);
    await sync.load();
    final before = s.entries.length;
    await tester.pumpWidget(LedgerApp(state: s, sync: sync));
    s.setSettingsOpen(true); // Import / Sync live in Settings
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Reset to demo data'), 300);
    await tester.ensureVisible(find.text('Choose sync folder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose sync folder'));
    await tester.pumpAndSettle();
    expect(find.text('“Sync” already has data'), findsOneWidget);
    expect(find.textContaining('$before demo entries'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
    await tester.pumpAndSettle();
    // The folder's 2 entries; this phone's demo stays out of it.
    expect(before, greaterThan(2));
    expect(s.entries.map((e) => e.id).toSet(), {'e1', 'e4'});
    expect(sync.on, isTrue);
    expect(find.textContaining('Synced at'), findsOneWidget);
    expect(
      folder.files.keys.where((k) => k.startsWith('ledger-android-')).length,
      1,
    );
    await sync.disconnect();
    await tester.pumpAndSettle();
    expect(find.text('Choose sync folder'), findsOneWidget);
    sync.dispose();
  });
}
