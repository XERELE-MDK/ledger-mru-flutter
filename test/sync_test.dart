import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_mru/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Export / import between the Android app and the desktop app (Rust).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'a desktop export (written by ledger-core) imports with the same figures',
    () async {
      final raw = File('test/fixtures/desktop_export.json').readAsStringSync();
      final f = LedgerFile.parse(raw);
      expect(f.accounts.length, 16);
      expect(f.entries.length, 55);
      expect(f.theme, 'system');

      final s = AppState();
      await s.load();
      s.importFile(f);
      final t = s.totals(s.entriesIn('2026-11'));
      expect((t.inc, t.exp), (27500, 18610));
      expect(s.rawBal('cash', '2026-11-31'), -380);
      expect(s.byId['rent']!.budget, 8000);
    },
  );

  test('export → import round trip keeps everything', () async {
    final a = AppState();
    await a.load();
    a.setMode('pro');
    a.setKhoums(true);
    final json = a.exportJson();
    final b = AppState();
    await b.load();
    b.resetDemo();
    b.importFile(LedgerFile.parse(json));
    expect(b.entries.length, a.entries.length);
    expect(b.mode, 'pro');
    expect(b.khoums, isTrue);
  });

  test('bad files are refused with a readable reason', () {
    expect(() => LedgerFile.parse('not json'), throwsA(isA<FormatException>()));
    expect(
      () => LedgerFile.parse('{"foo":1}'),
      throwsA(isA<FormatException>()),
    );
    const acc =
        '{"id":"cash","name":"Cash","type":"asset"},{"id":"food","name":"Food","type":"expense"}';
    String withEntry(String lines) =>
        '{"accounts":[$acc],"entries":[{"id":"x","date":"2026-11-02","memo":"M","lines":[$lines]}]}';
    expect(
      () => LedgerFile.parse(
        withEntry('{"a":"food","dr":10,"cr":0},{"a":"cash","dr":0,"cr":9}'),
      ),
      throwsA(
        predicate(
          (e) => e is FormatException && e.message.contains('not balanced'),
        ),
      ),
    );
    expect(
      () => LedgerFile.parse(
        withEntry('{"a":"food","dr":10,"cr":0},{"a":"nope","dr":0,"cr":10}'),
      ),
      throwsA(
        predicate(
          (e) => e is FormatException && e.message.contains('unknown account'),
        ),
      ),
    );
    expect(
      LedgerFile.parse(
        withEntry('{"a":"food","dr":10,"cr":0},{"a":"cash","dr":0,"cr":10}'),
      ).entries.length,
      1,
    );
  });

  test('writes the Android fixture read by ledger-core (when asked)', () async {
    final path = Platform.environment['LEDGER_WRITE_FIXTURE'];
    final s = AppState();
    await s.load();
    s.setMode('pro');
    s.setTheme('dark');
    s.setKhoums(true);
    s.upsertAccount(
      Account(id: 'fuel', name: 'Fuel', type: 'expense', budget: 2000),
    );
    s.addEntry(
      const Entry(
        id: 'android-test',
        date: '2026-11-20',
        memo: 'Café Nouakchott',
        lines: [Line('eating', 1250.5, 0), Line('cash', 0, 1250.5)],
      ),
    );
    s.deleteEntry(s.entries.first.id); // a tombstone must travel too
    final json = s.exportJson();
    expect(LedgerFile.parse(json).entries.length, s.entries.length);
    if (path != null) File(path).writeAsStringSync(json);
  });

  group('merge (same fixtures and expectations as ledger-core)', () {
    LedgerFile fx(String name) =>
        LedgerFile.parse(File('test/fixtures/$name').readAsStringSync());
    // Entry ids + account summaries, sorted (lists compare deeply in expect).
    List<String> shape(LedgerFile f) => [
      ...[for (final e in f.entries) e.id]..sort(),
      '|',
      ...[for (final a in f.accounts) '${a.id}|${a.name}|${a.budget}']..sort(),
    ];

    test('merge(A, B) gives the shared expected result', () {
      final exp =
          jsonDecode(
                File('test/fixtures/merge_expected.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      final (m, r) = mergeFiles(fx('merge_a.json'), fx('merge_b.json'));
      expect(
        [for (final e in m.entries) e.id]..sort(),
        (exp['entryIds'] as List).cast<String>(),
      );
      final names = (exp['accounts'] as Map).cast<String, String>();
      expect(m.accounts.length, names.length);
      for (final MapEntry(:key, :value) in names.entries) {
        expect(m.accounts.firstWhere((a) => a.id == key).name, value);
      }
      expect(
        m.accounts.firstWhere((a) => a.id == 'food').budget,
        (exp['foodBudget'] as num).toDouble(),
      );
      final rep = exp['report'] as Map<String, dynamic>;
      expect(
        [
          r.entriesAdded,
          r.entriesRemoved,
          r.accountsAdded,
          r.accountsUpdated,
          r.accountsRemoved,
          r.accountsKeptInUse,
          r.conflicts,
        ],
        [
          rep['entriesAdded'],
          rep['entriesRemoved'],
          rep['accountsAdded'],
          rep['accountsUpdated'],
          rep['accountsRemoved'],
          rep['accountsKeptInUse'],
          rep['conflicts'],
        ],
      );
      expect((m.mode, m.theme), ('simple', 'light')); // settings stay local
    });

    test('commutative and idempotent', () {
      final (a, b) = (fx('merge_a.json'), fx('merge_b.json'));
      final (ab, _) = mergeFiles(a, b);
      final (ba, _) = mergeFiles(b, a);
      expect(shape(ab), shape(ba));
      expect(mergeFiles(ab, b).$2.isNoop, isTrue);
      expect(mergeFiles(ab, a).$2.isNoop, isTrue);
      expect(mergeFiles(ab, ab).$2.isNoop, isTrue);
      expect(shape(mergeFiles(ba, ab).$1), shape(ab));
    });

    test(
      'a deletion and a new entry travel from the PC to the phone',
      () async {
        final phone = AppState();
        await phone.load();
        final pc = AppState();
        await pc.load();
        pc.importFile(phone.snapshot());
        final victim = pc.entries[3].id;
        pc.deleteEntry(victim);
        pc.addEntry(
          Entry(
            id: newEntryId(),
            date: '2026-11-20',
            memo: 'Fuel',
            lines: const [Line('transport', 99, 0), Line('cash', 0, 99)],
          ),
        );
        final preview = phone.previewMerge(pc.snapshot());
        expect((preview.entriesAdded, preview.entriesRemoved), (1, 1));
        final before = phone.entries.length;
        phone.mergeWith(pc.snapshot());
        expect(phone.entries.length, before); // +1 −1
        expect(phone.entries.any((e) => e.id == victim), isFalse);
        expect(phone.deletedEntries.any((t) => t.id == victim), isTrue);
        // survives a save / reload
        final again = AppState();
        await again.load();
        expect(again.deletedEntries.any((t) => t.id == victim), isTrue);
      },
    );

    test('timestamp-only changes are not reported as updates', () async {
      final s = AppState();
      await s.load();
      final a = s.snapshot();
      final b = LedgerFile(
        accounts: [
          a.accounts.first.copyWith(updatedAt: 5),
          ...a.accounts.skip(1),
        ],
        entries: a.entries,
      );
      final (m, r) = mergeFiles(a, b);
      expect(r.accountsUpdated, 0);
      expect(m.accounts.first.updatedAt, 5);
    });

    test('new ids: unique entries, desktop-style account ids', () async {
      expect(newEntryId(), isNot(newEntryId()));
      final s = AppState();
      await s.load();
      expect(s.newAccountId('Fuel'), 'fuel');
      expect(s.newAccountId('Cash'), 'cash-2');
      expect(s.newAccountId('Water & électricité'), 'water-lectricit');
    });
  });
}
