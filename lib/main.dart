import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'format.dart';
import 'l10n.dart';
import 'model.dart';
import 'screens/accounts.dart';
import 'screens/home.dart';
import 'screens/home_alt.dart';
import 'screens/journal.dart';
import 'screens/ledger.dart';
import 'screens/reports.dart';
import 'screens/settings.dart';
import 'sheets.dart';
import 'sync.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  useDeviceLanguage();
  final state = AppState();
  await state.load();
  runApp(LedgerApp(state: state));
}

/// Before [AppState.load]: a first launch creates the accounts, and their names
/// must be in the language the app is about to show.
void useDeviceLanguage() => S.current = S(
  S.resolve(
    null,
    WidgetsBinding.instance.platformDispatcher.locale.languageCode,
  ),
);

final messengerKey = GlobalKey<ScaffoldMessengerState>();

class LedgerApp extends StatefulWidget {
  const LedgerApp({super.key, required this.state, this.sync});
  final AppState state;

  /// Injected in tests; created (and loaded) here otherwise.
  final SyncService? sync;

  @override
  State<LedgerApp> createState() => _LedgerAppState();
}

/// Picks the theme (and, for Organic, light/dark from the user's choice or
/// the system's) and the language; sets [C.t] / [S.current] and rebuilds the
/// whole tree when either changes.
class _LedgerAppState extends State<LedgerApp> with WidgetsBindingObserver {
  late final SyncService _sync;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.state.addListener(_onState);
    _sync = widget.sync ?? SyncService(widget.state, onMessage: _message);
    if (widget.sync == null) _sync.load().then((_) => _onResume());
    _sync.addListener(_restartPoll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.state.removeListener(_onState);
    _sync.removeListener(_restartPoll);
    _poll?.cancel();
    if (widget.sync == null) _sync.dispose();
    super.dispose();
  }

  void _message(String m) => messengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m)));

  /// While the app is open, look at the shared folder every 20 s:
  /// Syncthing may have dropped a newer file from the other device.
  void _restartPoll() {
    if (_sync.on && _poll == null) {
      _poll = Timer.periodic(
        const Duration(seconds: 20),
        (_) => _sync.quietSync(),
      );
    } else if (!_sync.on) {
      _poll?.cancel();
      _poll = null;
    }
  }

  void _onResume() {
    _restartPoll();
    _sync.quietSync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) {
      _onResume();
    } else if (s == AppLifecycleState.paused) {
      _poll?.cancel();
      _poll = null;
      _sync.writeOwn(); // leave our latest file for Syncthing
    }
  }

  bool get _organicDark => switch (widget.state.theme) {
    'dark' => true,
    'light' => false,
    _ =>
      WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark,
  };

  AppTheme get _theme =>
      themeFor(widget.state.palette, organicDark: _organicDark);

  String get _lang => S.resolve(
    widget.state.lang,
    WidgetsBinding.instance.platformDispatcher.locale.languageCode,
  );

  bool get _stale => !identical(_theme, C.t) || _lang != S.current.lang;

  void _onState() {
    if (_stale) setState(() {});
  }

  @override
  void didChangePlatformBrightness() {
    if (_stale) setState(() {});
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (_stale) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    C.t = _theme;
    if (S.current.lang != _lang) S.current = S(_lang);
    return AppScope(
      state: widget.state,
      child: SyncScope(
        sync: _sync,
        child: MaterialApp(
          // New key on switch: every widget reads C.* / S.current again.
          key: ValueKey('${C.t.id}-${C.dark}-${S.current.lang}'),
          title: 'Ledger',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(),
          // Material's own texts (date picker, OK / Cancel…) in the same language.
          locale: Locale(S.current.lang),
          supportedLocales: [for (final l in languages) Locale(l)],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          scaffoldMessengerKey: messengerKey,
          home: const Shell(),
        ),
      ),
    );
  }
}

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final tab = s.tab;
    final t = S.current;
    final titles = {
      AppTab.home: t.titleOverview,
      AppTab.journal: t.tabJournal,
      AppTab.ledger: t.tabLedger,
      AppTab.reports: t.tabReports,
      AppTab.accounts: t.tabAccounts,
    };
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: C.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: C.surface,
        systemNavigationBarIconBrightness: C.dark
            ? Brightness.light
            : Brightness.dark,
      ),
      child: PopScope(
        canPop: tab == AppTab.home && !s.settingsOpen,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (s.settingsOpen) {
            s.setSettingsOpen(false);
          } else {
            s.setTab(AppTab.home);
          }
        },
        child: Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _Header(
                  title: s.settingsOpen ? t.settings : titles[tab]!,
                  showMonth: tab != AppTab.accounts && !s.settingsOpen,
                  settings: s.settingsOpen,
                ),
                if (s.damagedNotice)
                  const _DamagedNotice()
                else if (tab == AppTab.home &&
                    !s.settingsOpen &&
                    s.onlyDemo &&
                    !s.demoSeen &&
                    // It would reach the other devices: only from Settings.
                    !SyncScope.of(context).on)
                  const _DemoCard(),
                Expanded(
                  child: GestureDetector(
                    // Swipe left/right to change month on the month-based tabs.
                    onHorizontalDragEnd:
                        tab == AppTab.accounts ||
                            tab == AppTab.ledger ||
                            s.settingsOpen
                        ? null
                        : (d) {
                            final v = d.primaryVelocity ?? 0;
                            if (v.abs() > 400) s.shiftMonth(v < 0 ? 1 : -1);
                          },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: KeyedSubtree(
                        key: ValueKey(s.settingsOpen ? 'settings' : tab),
                        child: s.settingsOpen
                            ? const SettingsScreen()
                            : switch (tab) {
                                AppTab.home => switch (s.homeStyle) {
                                  'editorial' => const EditorialHome(),
                                  'taccount' => const TAccountHome(),
                                  'pebbles' => const PebblesHome(),
                                  _ => const HomeScreen(),
                                },
                                AppTab.journal => const JournalScreen(),
                                AppTab.ledger => const LedgerScreen(),
                                AppTab.reports => const ReportsScreen(),
                                AppTab.accounts => const AccountsScreen(),
                              },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: tab == AppTab.accounts || s.settingsOpen
              ? null
              : FloatingActionButton(
                  onPressed: () => showAddSheet(context),
                  tooltip: t.newEntry,
                  backgroundColor: C.accent,
                  foregroundColor: C.bg,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(Icons.add_rounded, size: 30),
                ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab.index,
            onDestinationSelected: (i) {
              s.settingsOpen = false;
              s.setTab(AppTab.values[i]);
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home_rounded),
                label: t.tabHome,
              ),
              NavigationDestination(
                icon: const Icon(Icons.menu_book_outlined),
                selectedIcon: const Icon(Icons.menu_book_rounded),
                label: t.tabJournal,
              ),
              NavigationDestination(
                icon: const Icon(Icons.layers_outlined),
                selectedIcon: const Icon(Icons.layers_rounded),
                label: t.tabLedger,
              ),
              NavigationDestination(
                icon: const Icon(Icons.bar_chart_rounded),
                selectedIcon: const Icon(Icons.bar_chart_rounded),
                label: t.tabReports,
              ),
              NavigationDestination(
                icon: const Icon(Icons.format_list_bulleted_rounded),
                selectedIcon: const Icon(Icons.format_list_bulleted_rounded),
                label: t.tabAccounts,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fresh install: says what the entries are, and how to begin for real.
class _DemoCard extends StatelessWidget {
  const _DemoCard();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: Panel(
      color: C.g100,
      radius: 24,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(S.current.demoCard, style: body(13, color: C.g900, height: 1.4)),
          Wrap(
            alignment: WrapAlignment.end,
            children: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: C.g800),
                onPressed: AppScope.read(context).dismissDemoCard,
                child: Text(S.current.later),
              ),
              TextButton(
                onPressed: () => startEmpty(context),
                child: Text(S.current.startEmpty(true)),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// "Your data could not be read" — stays until dismissed.
class _DamagedNotice extends StatelessWidget {
  const _DamagedNotice();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Panel(
        color: C.a100,
        radius: 24,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              S.current.damagedText,
              style: body(13, color: C.a900, height: 1.4),
            ),
            if (s.savingOff) ...[
              const SizedBox(height: 6),
              Text(
                S.current.damagedSavingOff,
                style: body(
                  13,
                  weight: FontWeight.w700,
                  color: C.a900,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                if (s.damagedCopies.isNotEmpty)
                  TextButton(
                    onPressed: () => saveDamagedCopy(context),
                    child: Text(S.current.saveCopy),
                  ),
                TextButton(
                  onPressed: s.dismissDamagedNotice,
                  child: Text(S.current.gotIt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.showMonth,
    this.settings = false,
  });
  final String title;
  final bool showMonth;

  /// Settings page: a back arrow instead of the gear.
  final bool settings;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    Widget arrow(IconData i, int off, String tip) => IconButton(
      onPressed: () => s.shiftMonth(off),
      tooltip: tip,
      icon: Icon(i, size: 20, color: C.text),
      style: IconButton.styleFrom(
        minimumSize: const Size(34, 34),
        padding: EdgeInsets.zero,
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 16, 12),
      child: SizedBox(
        height: 40,
        child: Row(
          children: [
            if (settings)
              IconButton(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => s.setSettingsOpen(false),
                icon: Icon(Icons.arrow_back_rounded, color: C.text),
              ),
            Expanded(
              // Wide display faces (Caprasimo, Comfortaa) shrink rather than cut.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(title, style: heading(25), maxLines: 1),
              ),
            ),
            if (showMonth)
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: C.surface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    arrow(
                      Icons.chevron_left_rounded,
                      -1,
                      S.current.previousMonth,
                    ),
                    GestureDetector(
                      // Tap the month label to jump back to the current month.
                      onTap: s.goToCurrentMonth,
                      child: SizedBox(
                        width: 84,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            ymShort(s.month),
                            textAlign: TextAlign.center,
                            style: body(13, weight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                    arrow(Icons.chevron_right_rounded, 1, S.current.nextMonth),
                  ],
                ),
              ),
            if (!settings) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: S.current.settings,
                onPressed: () => openSettings(context),
                icon: Icon(Icons.settings_rounded, color: C.text, size: 22),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
