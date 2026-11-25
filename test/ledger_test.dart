import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_mru/format.dart';
import 'package:ledger_mru/main.dart';
import 'package:ledger_mru/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('format', () {
    test('f0 groups thousands and uses a true minus', () {
      expect(f0(25500), '25,500');
      expect(f0(-1240.4), '−1,240');
      expect(f0(0), '0');
    });
    test('f2 shows khoums only when needed or asked', () {
      expect(f2(1250.5, false), '1,250.5');
      expect(f2(1250.05, false), '1,250.05');
      expect(f2(1250, false), '1,250');
      expect(f2(1250, true), '1,250.00');
    });
    test('parseAmount accepts comma decimals and spaces', () {
      expect(parseAmount('1 250,50'), 1250.5);
      expect(parseAmount('abc'), 0);
    });
    test('month helpers', () {
      expect(ymShift('2026-01', -1), '2025-12');
      expect(daysIn('2028-02'), 29);
      expect(dayLong('2026-11-20'), 'Fri 20 Nov');
    });
  });

  group('ledger', () {
    late AppState s;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      s = AppState();
      await s.load();
    });

    test('demo data: every entry balances and the trial balance is even', () {
      for (final e in s.entries) {
        final dr = e.lines.fold(0.0, (t, l) => t + l.dr);
        final cr = e.lines.fold(0.0, (t, l) => t + l.cr);
        expect(dr, cr, reason: e.memo);
      }
      final sum = s.accounts.fold(
        0.0,
        (t, a) => t + s.rawBal(a.id, '9999-12-31'),
      );
      expect(sum.abs() < 0.01, isTrue);
    });

    test('adding an expense moves money from the asset to the category', () {
      final before = s.rawBal('cash', '9999-12-31');
      s.addEntry(
        const Entry(
          id: 't1',
          date: '2030-01-05',
          memo: 'Taxi',
          lines: [Line('transport', 300, 0), Line('cash', 0, 300)],
        ),
      );
      expect(s.rawBal('cash', '9999-12-31'), before - 300);
      expect(s.month, '2030-01');
      expect(s.totals(s.entriesIn('2030-01')).exp, 300);
      expect(describe(s, s.entries.last).kind, Kind.expense);
    });

    test('accounts with entries cannot be deleted', () {
      expect(s.accountInUse('cash'), isTrue);
    });

    test('state persists across reloads', () async {
      s.setMode('pro');
      s.setTheme('dark');
      s.addEntry(
        const Entry(
          id: 't2',
          date: '2030-02-01',
          memo: 'Gift',
          lines: [Line('cash', 500, 0), Line('side', 0, 500)],
        ),
      );
      final again = AppState();
      await again.load();
      expect(again.mode, 'pro');
      expect(again.theme, 'dark');
      expect(again.entries.any((e) => e.id == 't2'), isTrue);
    });
  });

  testWidgets('app boots, switches tabs and opens the new-entry sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final s = AppState();
    await s.load();
    final before = s.entries.length;
    await tester.pumpWidget(LedgerApp(state: s));
    await tester.pumpAndSettle();
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Where it went'), findsOneWidget);

    for (final label in ['Journal', 'Ledger', 'Reports', 'Accounts']) {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Home'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('New entry'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '450');
    await tester.tap(find.text('Save entry'));
    await tester.pumpAndSettle();
    expect(find.text('New entry'), findsNothing);
    expect(s.entries.length, before + 1);
    expect(s.entries.last.amount, 450);
  });
}
