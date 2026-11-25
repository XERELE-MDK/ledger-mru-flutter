import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_mru/main.dart';
import 'package:ledger_mru/model.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Import → Merge → Undo through the real UI, with Android's file picker mocked.
void main() {
  testWidgets('import a desktop file, merge it, then undo', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final picked = File('test/fixtures/merge_b.json').readAsStringSync();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('ledger/files'),
      (call) async => call.method == 'open' ? picked : true,
    );
    SharedPreferences.setMockInitialValues({});
    final s = AppState();
    await s.load();
    final before = s.entries.length;
    await tester.pumpWidget(LedgerApp(state: s));
    s.setSettingsOpen(true); // Import / Sync live in Settings
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(find.text('Reset to demo data'), 300);
    await tester.ensureVisible(find.text('Import'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();
    expect(find.text('Import this file?'), findsOneWidget);
    expect(find.text('Merge (recommended)'), findsOneWidget);
    expect(
      find.textContaining('+2 entries, +1 account, 1 account updated'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Merge'));
    await tester.pumpAndSettle();
    expect(s.entries.length, before + 2);
    expect(s.byId['gift']?.name, 'Gifts');
    expect(s.byId['food']?.budget, 6000);
    expect(find.textContaining('Merged: +2 entries'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(s.entries.length, before);
    expect(s.byId['gift'], isNull);
    expect(s.byId['food']?.budget, 5000);
  });
}
