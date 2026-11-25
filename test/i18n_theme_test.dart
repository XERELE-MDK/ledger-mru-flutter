import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_mru/format.dart';
import 'package:ledger_mru/l10n.dart';
import 'package:ledger_mru/main.dart';
import 'package:ledger_mru/model.dart';
import 'package:ledger_mru/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

double contrast(Color a, Color b) {
  final (x, y) = (a.computeLuminance(), b.computeLuminance());
  return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
}

void main() {
  tearDown(() => S.current = S('en'));

  group('amounts typed by people (bugs found on 23/11)', () {
    test('"1,250" means one thousand two hundred fifty, not 1.25', () {
      expect(parseAmount('1,250'), 1250);
      expect(parseAmount('12,345,678'), 12345678);
      expect(parseAmount('1,250.50'), 1250.5); // used to give 0
      expect(parseAmount('1.250,50'), 1250.5);
      expect(parseAmount('1 250,50'), 1250.5);
      expect(
        parseAmount('1 250'),
        1250,
      ); // narrow no-break space (French display)
      expect(parseAmount('12,5'), 12.5);
      expect(parseAmount('0,75'), .75);
      expect(parseAmount('1250.5'), 1250.5);
      expect(parseAmount('1.250.000'), 1250000);
    });
    test('infinite, negative and junk amounts are refused', () {
      for (final bad in [
        '1e400',
        'inf',
        'Infinity',
        '-5',
        'abc',
        '',
        '1e5',
        '9999999999999',
      ]) {
        expect(parseAmount(bad), 0, reason: bad);
      }
    });
  });

  group('formats follow the language', () {
    test('English', () {
      S.current = S('en');
      expect(f0(1250), '1,250');
      expect(f2(1250.5, false), '1,250.5');
      expect(ymLong('2026-11'), 'November 2026');
      expect(dayLong('2026-11-20'), 'Fri 20 Nov');
    });
    test('French', () {
      S.current = S('fr');
      expect(f0(1250), '1 250');
      expect(f2(1250.5, true), '1 250,50');
      expect(f0(-380), '−380');
      expect(ymLong('2026-11'), 'novembre 2026');
      expect(dayLong('2026-11-20'), 'ven. 20 nov.');
      // What the French display shows can be typed back.
      expect(parseAmount(f2(1250.5, true)), 1250.5);
    });
    test('Japanese', () {
      S.current = S('ja');
      expect(ymLong('2026-11'), '2026年11月');
      expect(dayLong('2026-11-20'), '11月20日(金)');
      expect(dayShort('2026-11-20'), '11月20日');
    });
    test('device language is used when none is chosen', () {
      expect(S.resolve(null, 'fr'), 'fr');
      expect(S.resolve(null, 'de'), 'en');
      expect(S.resolve('ja', 'fr'), 'ja');
    });
    test('dates must be real calendar dates in imported files', () {
      const acc =
          '{"id":"cash","name":"Cash","type":"asset"},{"id":"food","name":"Food","type":"expense"}';
      final bad =
          '{"accounts":[$acc],"entries":[{"id":"x","date":"2026-13-45","memo":"M","lines":[{"a":"food","dr":1,"cr":0},{"a":"cash","dr":0,"cr":1}]}]}';
      expect(() => LedgerFile.parse(bad), throwsA(isA<FormatException>()));
    });
  });

  group('themes', () {
    final all = [organicLight, organicDark, ...themes];

    test('every theme stays readable (WCAG contrast)', () {
      for (final t in all) {
        expect(
          contrast(t.text, t.bg),
          greaterThanOrEqualTo(7),
          reason: '${t.id} text/bg',
        );
        expect(
          contrast(t.text, t.surface),
          greaterThanOrEqualTo(4.5),
          reason: '${t.id} text/surface',
        );
        expect(
          contrast(t.n[6], t.surface),
          greaterThanOrEqualTo(3),
          reason: '${t.id} muted/surface',
        );
        expect(
          contrast(t.hero[2], t.hero[0]),
          greaterThanOrEqualTo(4.5),
          reason: '${t.id} hero',
        );
        expect(
          contrast(t.bg, t.accent),
          greaterThanOrEqualTo(2.2),
          reason: '${t.id} button label',
        );
      }
    });

    test('every theme font is shipped with the app', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final t in all) {
        for (final f in {t.headingFont, t.bodyFont}) {
          expect(pubspec, contains('family: $f\n'), reason: f);
        }
      }
      for (final m in RegExp(
        r'asset: (assets/fonts/\S+)',
      ).allMatches(pubspec)) {
        expect(File(m.group(1)!).existsSync(), isTrue, reason: m.group(1));
      }
    });

    test('all ramps have 9 steps and theme ids are unique', () {
      for (final t in all) {
        expect(
          [t.n.length, t.a.length, t.g.length, t.hero.length],
          [9, 9, 9, 5],
        );
      }
      expect({for (final t in themes) t.id}.length, themes.length);
    });
  });

  test(
    'language, theme and home style are saved; files without them keep ours',
    () async {
      SharedPreferences.setMockInitialValues({});
      final s = AppState();
      await s.load();
      s.setLang('ja');
      s.setPalette('sakura');
      s.setHomeStyle('pebbles');
      final again = AppState();
      await again.load();
      expect(
        (again.lang, again.palette, again.homeStyle),
        ('ja', 'sakura', 'pebbles'),
      );
      // A file from the desktop app has no such keys: Replace keeps this device's.
      again.importFile(
        LedgerFile(accounts: again.accounts, entries: again.entries),
      );
      expect(
        (again.lang, again.palette, again.homeStyle),
        ('ja', 'sakura', 'pebbles'),
      );
    },
  );

  testWidgets('every home style × theme × language renders without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2340); // 360 × 780 dp phone
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final s = AppState();
    await s.load();
    await tester.pumpWidget(LedgerApp(state: s));
    for (final lang in languages) {
      s.setLang(lang);
      for (final palette in ['organic', ...themes.map((t) => t.id)]) {
        s.setPalette(palette);
        for (final style in ['overview', 'editorial', 'taccount', 'pebbles']) {
          s.setHomeStyle(style);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$lang / $palette / $style',
          );
        }
        // The other tabs and Settings, too.
        for (final tab in AppTab.values) {
          s.setTab(tab);
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$lang / $palette / $tab',
          );
        }
        s.setSettingsOpen(true);
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '$lang / $palette / settings',
        );
        s.setSettingsOpen(false);
        s.setTab(AppTab.home);
      }
    }
  });

  testWidgets('changing theme or language keeps Settings open', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final s = AppState();
    await s.load();
    await tester.pumpWidget(LedgerApp(state: s));
    await tester.tap(find.byIcon(Icons.settings_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Français'));
    await tester.pumpAndSettle();
    expect(find.text('Paramètres'), findsOneWidget);
    expect(find.text('Langue'.toUpperCase()), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Cappuccino'), 200);
    await tester.tap(find.text('Cappuccino'));
    await tester.pumpAndSettle();
    expect(s.palette, 'cappuccino');
    expect(find.text('Paramètres'), findsOneWidget); // still in Settings
    expect(C.t.bodyFont, 'Nunito');
    // Back arrow returns to the tabs.
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Aperçu'), findsOneWidget);
  });
}
