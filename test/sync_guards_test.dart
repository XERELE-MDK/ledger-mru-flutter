// With sync on, some actions would be undone by the other devices, or reach
// them by mistake. Checked through the real interface, in every language.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_mru/l10n.dart';
import 'package:ledger_mru/main.dart';
import 'package:ledger_mru/model.dart';
import 'package:ledger_mru/screens/home.dart';
import 'package:ledger_mru/sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() => S.current = S('en'));

  Future<(AppState, SyncService)> open(
    WidgetTester tester,
    MemoryFolder folder, {
    required bool connected,
    String lang = 'en',
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final s = AppState();
    await s.load();
    s.setLang(lang);
    final sync = SyncService(s, backendFor: (_) => folder);
    await sync.load();
    if (connected) await sync.connect('mem', 'Sync', folder: folder);
    await tester.pumpWidget(
      LedgerApp(key: ValueKey('$lang$connected'), state: s, sync: sync),
    );
    s.setSettingsOpen(true);
    await tester.pumpAndSettle();
    return (s, sync);
  }

  Future<void> tapIn(WidgetTester tester, String label) async {
    await tester.scrollUntilVisible(
      find.text(S.current.resetDemo),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text(label).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).first);
    await tester.pumpAndSettle();
  }

  testWidgets('reset to demo: refused while sync is on', (tester) async {
    for (final lang in languages) {
      final (s, sync) = await open(
        tester,
        MemoryFolder(),
        connected: true,
        lang: lang,
      );
      s.addEntry(
        const Entry(
          id: 'mine',
          date: '2026-11-20',
          memo: 'x',
          lines: [Line('food', 5, 0), Line('cash', 0, 5)],
        ),
      );
      await tapIn(tester, S.current.resetDemo);
      expect(tester.takeException(), isNull, reason: lang);
      expect(find.text(S.current.resetNeedsSyncOff), findsOneWidget);
      expect(find.text(S.current.reset), findsNothing);
      await tester.tap(find.text(S.current.gotIt));
      await tester.pumpAndSettle();
      expect(s.entries.any((e) => e.id == 'mine'), isTrue);
      await sync.disconnect();
      sync.dispose();
      await tester.pumpAndSettle();
    }
    final (s, sync) = await open(tester, MemoryFolder(), connected: false);
    s.deleteEntry(s.entries.first.id);
    await tapIn(tester, S.current.resetDemo);
    await tester.tap(find.text(S.current.reset));
    await tester.pumpAndSettle();
    expect(s.deletedEntries, isEmpty);
    sync.dispose();
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('import: Replace only while sync is off', (tester) async {
    final raw = File('test/fixtures/merge_b.json').readAsStringSync();
    const ch = MethodChannel('ledger/files');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(ch, (_) async => raw);
    addTearDown(() => messenger.setMockMethodCallHandler(ch, null));
    for (final connected in [true, false]) {
      final (s, sync) = await open(
        tester,
        MemoryFolder(),
        connected: connected,
      );
      await tapIn(tester, S.current.import);
      expect(
        find.widgetWithText(TextButton, S.current.replace),
        connected ? findsNothing : findsOneWidget,
      );
      expect(
        find.text(S.current.replaceNeedsSyncOff),
        connected ? findsOneWidget : findsNothing,
      );
      expect(find.widgetWithText(FilledButton, S.current.merge), findsOne);
      await tester.tap(find.text(S.current.cancel));
      await tester.pumpAndSettle();
      expect(s.entries.every((e) => isDemoEntry(e.id)), isTrue);
      await sync.disconnect();
      sync.dispose();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('undoing a connection leaves the folder', (tester) async {
    final folder = MemoryFolder();
    await folder.write(
      'ledger-desktop-x.json',
      File('test/fixtures/merge_b.json').readAsStringSync(),
    );
    const ch = SafFolder.ch;
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(ch, (call) async {
      final a = (call.arguments as Map?) ?? {};
      return switch (call.method) {
        'pick' => {'uri': 'content://tree/Sync', 'name': 'Sync'},
        'list' => [
          for (final f in await folder.list())
            {'id': f.id, 'name': f.name, 'modified': f.modified},
        ],
        'read' => folder.files[a['id']],
        'write' => await () async {
          await folder.write(a['name'] as String, a['content'] as String);
          return true;
        }(),
        _ => true,
      };
    });
    addTearDown(() => messenger.setMockMethodCallHandler(ch, null));
    final (s, sync) = await open(tester, folder, connected: false);
    final before = s.entries.map((e) => e.id).toList();
    await tapIn(tester, S.current.chooseSyncFolder);
    await tester.tap(find.widgetWithText(FilledButton, S.current.merge));
    await tester.pumpAndSettle();
    expect(sync.on, isTrue);
    await tester.tap(find.text(S.current.undo));
    await tester.pumpAndSettle();
    expect(sync.on, isFalse);
    expect(s.entries.map((e) => e.id), before);
    sync.dispose();
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('the Undo bar closes by itself', (tester) async {
    final (s, sync) = await open(tester, MemoryFolder(), connected: false);
    s.setSettingsOpen(false);
    await tester.pumpAndSettle();
    final n = s.entries.length;
    await tester.drag(find.byType(ListView).first, const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(EntryRow).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.delete));
    await tester.pumpAndSettle();
    expect(s.entries.length, n - 1);
    expect(find.text(S.current.undo), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text(S.current.undo), findsNothing);
    sync.dispose();
  });
}
