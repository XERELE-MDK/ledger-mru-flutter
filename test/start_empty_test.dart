// "Start with an empty book": removes the demo, nothing else — and every
// screen copes with a book that has no entry at all.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_mru/l10n.dart';
import 'package:ledger_mru/main.dart';
import 'package:ledger_mru/model.dart';
import 'package:ledger_mru/sync.dart';
import 'package:ledger_mru/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

const mine = Entry(
  id: 'mine',
  date: '2026-11-20',
  memo: 'Mine',
  lines: [Line('food', 5, 0), Line('cash', 0, 5)],
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() {
    S.current = S('en');
    C.t = organicLight;
  });

  Future<(AppState, SyncService)> open(
    WidgetTester tester, {
    String lang = 'en',
    bool synced = false,
    bool own = false,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final folder = MemoryFolder();
    final s = AppState();
    await s.load();
    s.setLang(lang);
    if (own) s.addEntry(mine);
    final sync = SyncService(s, backendFor: (_) => folder);
    await sync.load();
    if (synced) await sync.connect('mem', 'Sync', folder: folder);
    await tester.pumpWidget(LedgerApp(key: UniqueKey(), state: s, sync: sync));
    await tester.pumpAndSettle();
    return (s, sync);
  }

  test(
    'only the demo goes; it holds when merged and after a restart',
    () async {
      final s = AppState();
      await s.load();
      final demo = s.snapshot();
      s.addEntry(mine);
      final accounts = s.accounts.map((a) => a.toJson().toString()).toList();
      expect(s.onlyDemo, isFalse);
      expect(s.demoCount, demo.entries.length);
      s.removeDemo();
      expect(s.entries.map((e) => e.id), ['mine']);
      expect(s.demoCount, 0);
      expect(s.accounts.map((a) => a.toJson().toString()), accounts);
      // Against a device that still has the same demo, both ways.
      expect(mergeFiles(s.snapshot(), demo).$1.entries.map((e) => e.id), [
        'mine',
      ]);
      expect(mergeFiles(demo, s.snapshot()).$1.entries.map((e) => e.id), [
        'mine',
      ]);
      final n = s.deletedEntries.length;
      s.removeDemo();
      expect(s.deletedEntries.length, n);

      final again = AppState();
      await again.load();
      expect(again.entries.map((e) => e.id), ['mine']);
      again.deleteEntry('mine');
      final empty = AppState();
      await empty.load();
      expect(
        empty.entries,
        isEmpty,
        reason: 'an empty book is not a first launch',
      );
      expect((empty.onlyDemo, empty.damagedNotice), (false, false));
    },
  );

  testWidgets('a first launch creates the accounts in the device language', (
    tester,
  ) async {
    final pd = tester.binding.platformDispatcher;
    addTearDown(pd.clearLocaleTestValue);
    for (final (locale, cash) in [
      (const Locale('fr', 'MR'), 'Espèces'),
      (const Locale('ja'), '現金'),
      (const Locale('ar', 'MR'), 'Cash'), // not supported: English
    ]) {
      SharedPreferences.setMockInitialValues({});
      pd.localeTestValue = locale;
      useDeviceLanguage();
      final s = AppState();
      await s.load();
      expect(s.byId['cash']!.name, cash);
    }
  });

  test('the demo in two languages is not a conflict', () async {
    S.current = S('fr');
    final fr = AppState();
    await fr.load();
    SharedPreferences.setMockInitialValues({});
    S.current = S('en');
    final en = AppState();
    await en.load();
    for (final (a, b) in [(fr, en), (en, fr)]) {
      final (m, r) = mergeFiles(a.snapshot(), b.snapshot());
      expect(r.isNoop, isTrue, reason: describeMerge(r));
      expect(m.accounts.first.name, a.accounts.first.name);
    }
    // An edit wins everywhere, and real conflicts are still counted.
    fr.upsertAccount(fr.byId['cash']!.copyWith(name: 'Poche'));
    final merged = mergeFiles(en.snapshot(), fr.snapshot()).$1;
    expect(merged.accounts.firstWhere((a) => a.id == 'cash').name, 'Poche');
    LedgerFile one(String name, String memo) => LedgerFile(
      accounts: [Account(id: 'c', name: name, type: 'asset', updatedAt: 5)],
      entries: [
        Entry(id: 'e1', date: '2026-11-20', memo: memo, lines: const []),
      ],
    );
    expect(mergeFiles(one('A', 'x'), one('B', 'x')).$2.conflicts, 1);
    expect(mergeFiles(one('A', 'x'), one('A', 'y')).$2.conflicts, 1);
  });

  testWidgets('from the first-launch card, then Undo', (tester) async {
    for (final lang in languages) {
      SharedPreferences.setMockInitialValues({});
      final (s, sync) = await open(tester, lang: lang);
      final n = s.entries.length;
      expect(find.text(S.current.demoCard), findsOneWidget);
      await tester.tap(find.text(S.current.startEmpty(true)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: lang);
      expect(find.textContaining('$n'), findsWidgets);
      await tester.tap(find.text(S.current.cancel));
      await tester.pumpAndSettle();
      expect(s.entries.length, n);

      await tester.tap(find.text(S.current.startEmpty(true)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(S.current.remove));
      await tester.pumpAndSettle();
      expect(s.entries, isEmpty);
      expect(find.text(S.current.demoCard), findsNothing);
      await tester.tap(find.text(S.current.undo));
      await tester.pumpAndSettle();
      expect(s.entries.length, n);
      expect(s.deletedEntries, isEmpty);
      expect(find.text(S.current.demoCard), findsOneWidget);

      await tester.tap(find.text(S.current.later));
      await tester.pumpAndSettle();
      expect(find.text(S.current.demoCard), findsNothing);
      sync.dispose();
    }
  });

  testWidgets('the card shows only for a pure demo, on Home, sync off', (
    tester,
  ) async {
    var (s, sync) = await open(tester);
    s.setTab(AppTab.journal);
    await tester.pumpAndSettle();
    expect(find.text(S.current.demoCard), findsNothing);
    s.setTab(AppTab.home);
    s.setSettingsOpen(true);
    await tester.pumpAndSettle();
    expect(find.text(S.current.demoCard), findsNothing);
    sync.dispose();
    (s, sync) = await open(tester, own: true);
    expect(find.text(S.current.demoCard), findsNothing);
    sync.dispose();
    SharedPreferences.setMockInitialValues({});
    (s, sync) = await open(tester, synced: true);
    expect(s.onlyDemo, isTrue);
    expect(find.text(S.current.demoCard), findsNothing);
    sync.dispose();
  });

  testWidgets('from Settings: own entries stay; with sync, no Undo', (
    tester,
  ) async {
    for (final synced in [false, true]) {
      SharedPreferences.setMockInitialValues({});
      final (s, sync) = await open(tester, own: true, synced: synced);
      s.setSettingsOpen(true);
      await tester.pumpAndSettle();
      final button = find.text(S.current.startEmpty(false));
      await tester.scrollUntilVisible(
        button,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.textContaining('Your 1 own entry stays.'), findsOneWidget);
      expect(
        find.textContaining(S.current.startEmptySynced),
        synced ? findsOneWidget : findsNothing,
      );
      await tester.tap(find.text(S.current.remove));
      await tester.pumpAndSettle();
      expect(s.entries.map((e) => e.id), ['mine']);
      expect(find.text(S.current.undo), synced ? findsNothing : findsOneWidget);
      expect(button, findsNothing);
      sync.dispose();
      await tester.pump(const Duration(seconds: 5));
    }
  });

  testWidgets('every screen × language works with no entry at all', (
    tester,
  ) async {
    final (s, sync) = await open(tester);
    s.removeDemo();
    for (final lang in languages) {
      s.setLang(lang);
      for (final mode in ['simple', 'pro']) {
        s.setMode(mode);
        for (final style in ['overview', 'editorial', 'taccount', 'pebbles']) {
          s.setHomeStyle(style);
          for (final tab in AppTab.values) {
            s.setTab(tab);
            for (final report in ['tb', 'mom', 'bud']) {
              if (report != 'tb' && tab != AppTab.reports) continue;
              s.setReport(report);
              await tester.pumpAndSettle();
              expect(
                tester.takeException(),
                isNull,
                reason: '$lang $mode $style $tab $report',
              );
              expect(find.textContaining('NaN'), findsNothing);
              expect(find.textContaining('Infinity'), findsNothing);
            }
          }
        }
      }
    }
    // Opening balances, as the hint says: Dr cash / Cr opening balance.
    s.addEntry(
      const Entry(
        id: 'o',
        date: '2026-11-01',
        memo: 'Opening',
        lines: [Line('cash', 3000, 0), Line('opening', 0, 3000)],
      ),
    );
    s.setTab(AppTab.home);
    s.setHomeStyle('overview');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(s.rawBal('cash', '9999-12-31'), 3000);
    sync.dispose();
  });
}
