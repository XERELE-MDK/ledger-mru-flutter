// Opening balances: same rules, and same amounts, as ledger-core (Rust).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_mru/format.dart';
import 'package:ledger_mru/l10n.dart';
import 'package:ledger_mru/main.dart';
import 'package:ledger_mru/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => S.current = S('en'));

  Future<AppState> empty() async {
    final s = AppState();
    await s.load();
    s.removeDemo();
    return s;
  }

  test('amounts match the cases shared with ledger-core', () {
    final cases =
        jsonDecode(File('test/fixtures/amounts.json').readAsStringSync())
            as List;
    expect(cases.length, greaterThan(25));
    for (final c in cases.cast<List<dynamic>>()) {
      expect(parseAmount(c[0] as String), c[1], reason: '"${c[0]}"');
    }
  });

  test('they balance, and can be changed', () async {
    final s = await empty();
    expect(
      s.setOpening('2026-11-01', {'cash': '', 'bank': ' 0,00 '}),
      isNotNull,
    );
    expect(s.setOpening('2026-11-01', {'cash': 'abc'}), contains('Cash'));
    expect(s.entries, isEmpty);

    // Have 3 000 + 21 000.50, owe 2 000 → equity 22 000.50.
    expect(
      s.setOpening('2026-11-01', {
        'cash': '3,000',
        'bank': '21 000,50',
        'loan': '2000',
        'food': '99',
        'nope': '7',
      }),
      isNull,
    );
    final e = s.entries.single;
    expect(isOpeningEntry(e.id), isTrue);
    expect(isDemoEntry(e.id), isFalse);
    expect(isOpeningEntry(newEntryId()), isFalse);
    expect(isOpeningEntry('opening'), isFalse);
    expect(s.month, '2026-11');
    expect(s.rawBal('cash', '2026-11-31'), 3000);
    expect(s.rawBal('loan', '2026-11-31'), -2000);
    expect(s.rawBal('opening', '2026-11-31'), -22000.5);
    expect(s.totals(s.entries), (inc: 0.0, exp: 0.0)); // not income
    expect(
      [for (final r in s.openingRows) (r.account.id, r.amount)],
      [
        ('cash', 3000.0),
        ('bank', 21000.5),
        ('wallet', 0.0),
        ('savings', 0.0),
        ('loan', 2000.0),
      ],
    );
    expect(s.openingDate, '2026-11-01');
    LedgerFile.parse(s.exportJson()); // valid for the other apps

    // Changing replaces, everywhere; the user's own equity entries stay.
    final phone = s.snapshot();
    s.addEntry(
      const Entry(
        id: 'e1',
        date: '2026-11-02',
        memo: 'Gift',
        lines: [Line('cash', 10, 0), Line('opening', 0, 10)],
      ),
    );
    expect(s.setOpening('2026-11-01', {'loan': '500'}), isNull);
    expect(s.entries, hasLength(2));
    expect(s.rawBal('opening', '9999'), 490);
    expect(mergeFiles(phone, s.snapshot()).$1.entries, hasLength(2));
    // Having exactly what you owe needs no equity line; all zeros removes it.
    s.setOpening('2026-11-01', {'cash': '500', 'loan': '500'});
    expect(s.entries.last.lines, hasLength(2));
    expect(s.setOpening('2026-11-01', {'cash': ''}), isNull);
    expect(s.entries.map((e) => e.id), ['e1']);
    expect(s.openingDate, isNull);
    // Cents that do not add up in binary still balance.
    s.setOpening('2026-11-01', {'cash': '0.1', 'bank': '0.2', 'loan': '0.3'});
    expect(s.entries.last.lines, hasLength(3));
    LedgerFile.parse(s.exportJson());
    // No equity account left: one is created.
    s.importFile(
      LedgerFile(
        accounts: s.accounts.where((a) => a.type != 'equity').toList(),
        entries: const [],
      ),
    );
    expect(s.setOpening('2026-11-01', {'cash': '5'}), isNull);
    expect(s.accounts.where((a) => a.type == 'equity'), hasLength(1));
    LedgerFile.parse(s.exportJson());
  });

  testWidgets('through the interface, in every language', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    for (final lang in languages) {
      SharedPreferences.setMockInitialValues({});
      final s = await empty();
      s.setLang(lang);
      await tester.pumpWidget(LedgerApp(key: UniqueKey(), state: s));
      await tester.pumpAndSettle();
      final l = S.current;
      Finder field(String id) => find.byKey(ValueKey('opening-$id'));

      // From the card of an empty book: nothing typed is an error.
      expect(find.text(l.emptyCard), findsOneWidget);
      await tester.tap(find.text(l.openingBalances));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: lang);
      await tester.tap(find.text(l.save));
      await tester.pumpAndSettle();
      expect(find.text(l.errOpeningEmpty), findsOneWidget);
      await tester.enterText(field('cash'), '3 000');
      await tester.enterText(field('loan'), '500');
      await tester.pumpAndSettle();
      expect(find.text(l.errOpeningEmpty), findsNothing);
      await tester.tap(find.text(l.save));
      await tester.pumpAndSettle();
      expect(find.text(l.emptyCard), findsNothing);
      expect(s.rawBal('cash', '9999'), 3000);
      expect(s.openingDate, todayStr());

      // From Accounts: filled in, editable, removable.
      s.setTab(AppTab.accounts);
      await tester.pumpAndSettle();
      Future<void> reopen() async {
        await tester.scrollUntilVisible(
          find.widgetWithText(OutlinedButton, l.openingBalances),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(OutlinedButton, l.openingBalances),
        );
        await tester.pumpAndSettle();
      }

      await reopen();
      final shown = tester.widget<TextField>(field('cash')).controller!.text;
      expect(parseAmount(shown), 3000, reason: '$lang "$shown"');
      await tester.tap(find.text(l.save)); // unchanged: same balances
      await tester.pumpAndSettle();
      expect(s.rawBal('cash', '9999'), 3000);
      expect(s.entries, hasLength(1));
      await tester.pump(const Duration(seconds: 3));
      await reopen();
      await tester.enterText(field('cash'), '');
      await tester.enterText(field('loan'), '0');
      await tester.tap(find.text(l.save));
      await tester.pumpAndSettle();
      expect(s.entries, isEmpty);
      expect(tester.takeException(), isNull, reason: lang);
      await tester.pump(const Duration(seconds: 3));
    }
  });
}
