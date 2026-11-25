// The stored ledger cannot be read: the user's data must survive, the app must
// still open, and the demo must not leak into the shared sync folder.

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_mru/l10n.dart';
import 'package:ledger_mru/main.dart';
import 'package:ledger_mru/model.dart';
import 'package:ledger_mru/sync.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// Storage that refuses to write one key (full disk…).
class _Refuses extends InMemorySharedPreferencesStore {
  _Refuses(super.data, {required this.byThrowing}) : super.withData();
  final bool byThrowing;

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key != 'flutter.${AppState.damagedKey}') {
      return super.setValue(valueType, key, value);
    }
    if (byThrowing) throw StateError('disk full');
    return false;
  }
}

const _key = 'ledger-mru-v1';

/// Broken in different ways: not JSON, wrong root, missing parts, wrong types.
const _damaged = [
  '{broken',
  '',
  '[]',
  '"text"',
  '{"entries":[]}',
  '{"accounts":[{"id":1}]}',
  '{"accounts":[],"entries":[{"id":"e1","date":"2026-11-20","memo":"m",'
      '"lines":[{"a":"cash","dr":null,"cr":0}]}]}',
];

Future<AppState> _load(Map<String, Object> stored) async {
  SharedPreferences.setMockInitialValues(stored);
  final s = AppState();
  await s.load();
  return s;
}

Future<AppState> _relaunch() async {
  final s = AppState();
  await s.load();
  return s;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => S.current = S('en'));

  test('the app opens on demo data and keeps an exact copy', () async {
    for (final raw in _damaged) {
      final s = await _load({_key: raw});
      expect(s.entries, isNotEmpty, reason: raw);
      expect(s.damagedNotice, isTrue, reason: raw);
      expect(s.damagedCopies, [raw]);
      // Using the app no longer destroys anything.
      s.setHints(false);
      s.addEntry(
        const Entry(
          id: 'new',
          date: '2026-11-20',
          memo: 'x',
          lines: [Line('food', 5, 0), Line('cash', 0, 5)],
        ),
      );
      final again = await _relaunch();
      expect(again.damagedCopies, [raw], reason: raw);
      expect(again.damagedNotice, isFalse, reason: 'told once');
      expect(again.entries.any((e) => e.id == 'new'), isTrue);
    }
  });

  test('a value of the wrong type does not stop the app', () async {
    final s = await _load({_key: 42});
    expect(s.entries, isNotEmpty);
    expect(s.savingOff, isFalse);
  });

  test('a second accident keeps both copies', () async {
    await _load({_key: '{first'});
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, '{second');
    final s = await _relaunch();
    expect(s.damagedCopies, ['{first', '{second']);
  });

  test('healthy data and a first launch raise no alarm', () async {
    final first = await _load({});
    expect(first.damagedNotice, isFalse);
    expect(first.damagedCopies, isEmpty);
    final ok = await _load({_key: first.exportJson()});
    expect(ok.damagedNotice, isFalse);
    expect(ok.entries.length, first.entries.length);
  });

  test('if the copy cannot be kept, nothing is overwritten', () async {
    for (final byThrowing in [false, true]) {
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesStorePlatform.instance = _Refuses({
        'flutter.$_key': '{broken',
      }, byThrowing: byThrowing);
      final s = await _relaunch();
      s.setHints(false);
      final p = await SharedPreferences.getInstance();
      expect(p.getString(_key), '{broken');
      // The user is told, and can still put the data in a file.
      expect((s.damagedNotice, s.savingOff), (true, true));
      expect(s.damagedCopies, ['{broken']);
    }
  });

  test('sync: the demo stays home and the folder keeps the real data', () async {
    final folder = MemoryFolder();
    // A working phone, synced, with one real entry.
    final before = await _load({});
    const real = Entry(
      id: 'real',
      date: '2026-11-20',
      memo: 'Rent',
      lines: [Line('rent', 8000, 0), Line('bank', 0, 8000)],
    );
    before.importFile(
      LedgerFile(accounts: before.accounts, entries: const [real]),
    );
    final sync = SyncService(before, backendFor: (_) => folder);
    await sync.load();
    final oldName = sync.ownName;
    await sync.connect('uri', 'Ledger');
    sync.dispose();

    // Then its storage breaks.
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, '{broken');
    final s = await _relaunch();
    final sync2 = SyncService(s, backendFor: (_) => folder);
    await sync2.load();
    expect(sync2.on, isFalse);
    s.setHints(false);
    await sync2.writeOwn();
    await sync2.syncNow();
    expect(folder.files.keys, [oldName]);
    expect(
      (jsonDecode(folder.files[oldName]!) as Map)['entries'],
      hasLength(1),
    );

    // Reconnecting: our old file counts as another device's, so it comes back.
    expect(sync2.ownName, isNot(oldName));
    await sync2.connect('uri', 'Ledger', useFolderData: true);
    expect(s.entries.map((e) => e.id), ['real']);
    sync2.dispose();

    // Next launch: everything is normal, sync included.
    final s3 = await _relaunch();
    final sync3 = SyncService(s3, backendFor: (_) => folder);
    await sync3.load();
    expect((s3.damagedNotice, sync3.on), (false, true));
    sync3.dispose();
  });

  testWidgets('the user is told, and can save the copy', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    MethodCall? saved;
    const ch = MethodChannel('ledger/files');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(ch, (c) async {
      saved = c;
      return true;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(ch, null));

    for (final lang in languages) {
      final s = await _load({_key: '{broken'});
      s.setLang(lang);
      await tester.pumpWidget(LedgerApp(key: ValueKey(lang), state: s));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: lang);
      expect(find.text(S.current.damagedText), findsOneWidget);

      saved = null;
      await tester.tap(find.text(S.current.saveCopy));
      await tester.pumpAndSettle();
      expect((saved!.arguments as Map)['content'], '{broken');

      await tester.tap(find.text(S.current.gotIt));
      await tester.pumpAndSettle();
      expect(find.text(S.current.damagedText), findsNothing);

      // Still reachable later, from Settings → Data.
      s.setSettingsOpen(true);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text(S.current.saveCopy),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull, reason: lang);
    }
  });
}
