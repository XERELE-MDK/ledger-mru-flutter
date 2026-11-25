import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'format.dart';
import 'l10n.dart';

const typeOrder = ['asset', 'liability', 'equity', 'income', 'expense'];
const normalSide = {
  'asset': 'dr',
  'expense': 'dr',
  'liability': 'cr',
  'equity': 'cr',
  'income': 'cr',
};
// Type labels, group labels and hints live in l10n.dart (S.typeLabel…).

class Account {
  Account({
    required this.id,
    required this.name,
    required this.type,
    this.budget = 0,
    this.updatedAt = 0,
  });
  final String id;
  final String name;
  final String type;
  final double budget;

  /// Last edit in ms since the epoch (0 = demo / never edited). Newest wins on merge.
  final int updatedAt;

  Account copyWith({
    String? name,
    String? type,
    double? budget,
    int? updatedAt,
  }) => Account(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    budget: budget ?? this.budget,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  bool sameAs(Account o) =>
      id == o.id &&
      name == o.name &&
      type == o.type &&
      budget == o.budget &&
      updatedAt == o.updatedAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    if (budget > 0) 'budget': budget,
    if (updatedAt != 0) 'updatedAt': updatedAt,
  };
  factory Account.fromJson(Map<String, dynamic> j) => Account(
    id: j['id'] as String,
    name: j['name'] as String,
    type: j['type'] as String,
    budget: (j['budget'] as num?)?.toDouble() ?? 0,
    updatedAt: (j['updatedAt'] as num?)?.toInt() ?? 0,
  );
}

/// "This id was deleted at …" — lets a deletion travel to the other device.
class Tombstone {
  const Tombstone(this.id, this.at);
  final String id;

  /// ms since the epoch
  final int at;
  Map<String, dynamic> toJson() => {'id': id, 'at': at};
  factory Tombstone.fromJson(Map<String, dynamic> j) =>
      Tombstone(j['id'] as String, (j['at'] as num).toInt());
}

int nowMs() => DateTime.now().millisecondsSinceEpoch;

final _rand = Random();

/// A new, practically unique entry id: time + 16 random bits.
String newEntryId() =>
    'e${nowMs()}-${_rand.nextInt(0x10000).toRadixString(16).padLeft(4, '0')}';

/// Is this one of the demo entries ("s20261125-12", see [seedData])?
bool isDemoEntry(String id) => RegExp(r'^s\d{8}-\d+$').hasMatch(id);

bool sameEntry(Entry a, Entry b) {
  if (a.id != b.id || a.date != b.date || a.memo != b.memo) return false;
  if (a.lines.length != b.lines.length) return false;
  for (var i = 0; i < a.lines.length; i++) {
    final (x, y) = (a.lines[i], b.lines[i]);
    if (x.a != y.a || x.dr != y.dr || x.cr != y.cr) return false;
  }
  return true;
}

class Line {
  const Line(this.a, this.dr, this.cr);
  final String a;
  final double dr;
  final double cr;
  Map<String, dynamic> toJson() => {'a': a, 'dr': dr, 'cr': cr};
  factory Line.fromJson(Map<String, dynamic> j) => Line(
    j['a'] as String,
    (j['dr'] as num).toDouble(),
    (j['cr'] as num).toDouble(),
  );
}

class Entry {
  const Entry({
    required this.id,
    required this.date,
    required this.memo,
    required this.lines,
  });
  final String id;
  final String date; // YYYY-MM-DD
  final String memo;
  final List<Line> lines;
  double get amount => lines.fold(0.0, (t, l) => t + l.dr);
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'memo': memo,
    'lines': lines.map((l) => l.toJson()).toList(),
  };
  factory Entry.fromJson(Map<String, dynamic> j) => Entry(
    id: j['id'] as String,
    date: j['date'] as String,
    memo: j['memo'] as String,
    lines: (j['lines'] as List)
        .map((l) => Line.fromJson(l as Map<String, dynamic>))
        .toList(),
  );
}

enum AppTab { home, journal, ledger, reports, accounts }

/// Demo data — three months of a realistic household in MRU.
({List<Account> accounts, List<Entry> entries}) seedData() {
  final now = DateTime.now();
  final today = now.day;
  final t = S.current;
  Account acc(String id, String type, [double budget = 0]) =>
      Account(id: id, name: t.demoAccount(id), type: type, budget: budget);
  final accounts = [
    acc('cash', 'asset'),
    acc('bank', 'asset'),
    acc('wallet', 'asset'),
    acc('savings', 'asset'),
    acc('loan', 'liability'),
    acc('opening', 'equity'),
    acc('salary', 'income'),
    acc('side', 'income'),
    acc('rent', 'expense', 8000),
    acc('food', 'expense', 5000),
    acc('transport', 'expense', 1500),
    acc('utilities', 'expense', 1200),
    acc('phone', 'expense', 600),
    acc('eating', 'expense', 1500),
    acc('family', 'expense', 3000),
    acc('health', 'expense', 800),
  ];
  String ym(int off) {
    final d = DateTime(now.year, now.month + off, 1);
    return '${d.year}-${pad2(d.month)}';
  }

  final entries = <Entry>[];
  final tag = dateStr(now).replaceAll('-', '');
  var n = 0;
  entries.add(
    Entry(
      id: 's$tag-${n++}',
      date: '${ym(-2)}-01',
      memo: t.demoMemo('opening'),
      lines: const [
        Line('cash', 3000, 0),
        Line('bank', 21000, 0),
        Line('wallet', 1500, 0),
        Line('opening', 0, 25500),
      ],
    ),
  );
  const plan = <(int, String, String, String, List<double>)>[
    (2, 'rent', 'rent', 'bank', [8000, 8000, 8000]),
    (3, 'atm', 'cash', 'bank', [4000, 4500, 4000]),
    (4, 'salary', 'bank', 'salary', [25000, 25000, 25000]),
    (5, 'bill', 'utilities', 'wallet', [1080, 1150, 1240]),
    (6, 'phone', 'phone', 'wallet', [500, 500, 500]),
    (6, 'savings', 'savings', 'bank', [3000, 3000, 2500]),
    (7, 'groceries', 'food', 'cash', [1150, 1320, 1260]),
    (8, 'taxi', 'transport', 'cash', [300, 250, 400]),
    (10, 'family', 'family', 'bank', [3000, 3000, 3000]),
    (12, 'lunch', 'eating', 'cash', [450, 600, 380]),
    (14, 'groceries', 'food', 'cash', [1240, 1100, 1380]),
    (15, 'topup', 'wallet', 'bank', [2000, 2000, 2000]),
    (16, 'taxi', 'transport', 'wallet', [350, 400, 300]),
    (17, 'repaid', 'loan', 'wallet', [0, 0, 1000]),
    (18, 'pharmacy', 'health', 'cash', [0, 320, 950]),
    (19, 'website', 'wallet', 'side', [0, 4000, 2500]),
    (21, 'groceries', 'food', 'cash', [1180, 1260, 1200]),
    (23, 'dinner', 'eating', 'wallet', [700, 520, 600]),
    (24, 'borrowed', 'cash', 'loan', [0, 2000, 0]),
    (26, 'taxi', 'transport', 'cash', [280, 350, 300]),
    (28, 'groceries', 'food', 'cash', [1300, 1210, 1250]),
  ];
  for (final (i, off) in const [-2, -1, 0].indexed) {
    final m = ym(off);
    for (final (d, memo, dr, cr, amts) in plan) {
      final amt = amts[i];
      if (amt == 0) continue;
      if (off == 0 && d > today) continue;
      entries.add(
        Entry(
          id: 's$tag-${n++}',
          date: '$m-${pad2(d)}',
          memo: t.demoMemo(memo),
          lines: [Line(dr, amt, 0), Line(cr, 0, amt)],
        ),
      );
    }
  }
  return (accounts: accounts, entries: entries);
}

class AppState extends ChangeNotifier {
  static const _key = 'ledger-mru-v1';

  /// Stored ledgers that could not be read, kept exactly as they were.
  static const damagedKey = 'ledger-mru-damaged';
  SharedPreferences? _prefs;

  /// Copies of unreadable data (oldest first); normally empty.
  List<String> damagedCopies = const [];

  /// The data could not be read at this launch: demo data is showing.
  bool damagedNow = false;

  /// [damagedNow], until the user dismisses the message.
  bool damagedNotice = false;

  /// Saving would destroy data of which no copy could be kept.
  bool savingOff = false;

  List<Account> accounts = [];
  List<Entry> entries = [];
  String mode = 'simple'; // 'simple' | 'pro'
  bool hints = true;
  bool khoums = false;
  String theme =
      'system'; // 'system' | 'light' | 'dark' — brightness of Organic
  /// Interface language ('fr' | 'en' | 'ja'); null = the device's.
  String? lang;

  /// Complete theme (colours + fonts): 'organic' | 'cappuccino' | 'amoled' | …
  String palette = 'organic';

  /// Home screen: 'overview' | 'editorial' | 'taccount' | 'pebbles'.
  String homeStyle = 'overview';
  List<Tombstone> deletedEntries = [];
  List<Tombstone> deletedAccounts = [];

  // UI state (not persisted)
  String month = todayStr().substring(0, 7);
  AppTab tab = AppTab.home;
  String report = 'tb'; // tb | mom | bud
  String ledgerAcc = 'cash';

  /// Settings page shown instead of the tabs (UI state, survives the
  /// MaterialApp rebuild that a theme/language change triggers).
  bool settingsOpen = false;

  void dismissDamagedNotice() {
    damagedNotice = false;
    notifyListeners();
  }

  void setSettingsOpen(bool v) {
    settingsOpen = v;
    notifyListeners();
  }

  bool get isPro => mode == 'pro';

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    String? raw;
    LedgerFile? file;
    try {
      raw = _prefs!.getString(_key);
    } catch (_) {} // not text: nothing of ours to lose
    try {
      damagedCopies = _prefs!.getStringList(damagedKey) ?? const [];
    } catch (_) {
      damagedCopies = const [];
    }
    if (raw != null) {
      try {
        file = LedgerFile.fromMap(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    if (file != null) {
      _apply(file);
    } else {
      final s = seedData();
      accounts = s.accounts;
      entries = s.entries;
      if (raw != null) await _keepDamaged(raw);
    }
    _invalidate();
  }

  /// The stored ledger is unreadable: puts a copy aside *before* anything can
  /// be saved over it. If that fails, saving stays off for this launch.
  Future<void> _keepDamaged(String raw) async {
    damagedNow = damagedNotice = true;
    savingOff = true;
    if (!damagedCopies.contains(raw)) damagedCopies = [...damagedCopies, raw];
    try {
      savingOff = !await _prefs!.setStringList(damagedKey, damagedCopies);
    } catch (_) {}
    _save(); // the next launch starts from here, not from the damaged data
  }

  Map<String, dynamic> _toJson() => {
    'accounts': accounts.map((a) => a.toJson()).toList(),
    'entries': entries.map((e) => e.toJson()).toList(),
    'mode': mode,
    'hints': hints,
    'khoums': khoums,
    'theme': theme,
    // Newer per-device settings (the desktop app ignores unknown keys).
    'palette': palette,
    'homeStyle': homeStyle,
    if (lang != null) 'lang': lang,
    if (deletedEntries.isNotEmpty)
      'deletedEntries': deletedEntries.map((t) => t.toJson()).toList(),
    if (deletedAccounts.isNotEmpty)
      'deletedAccounts': deletedAccounts.map((t) => t.toJson()).toList(),
  };

  void _save() {
    if (savingOff) return;
    _prefs?.setString(_key, jsonEncode(_toJson()));
  }

  void _apply(LedgerFile f) {
    accounts = f.accounts;
    entries = f.entries;
    mode = f.mode;
    hints = f.hints;
    khoums = f.khoums;
    theme = f.theme;
    // Files from the desktop app (or older versions) have no such keys:
    // keep this device's choice then.
    lang = f.lang ?? lang;
    palette = f.palette ?? palette;
    homeStyle = f.homeStyle ?? homeStyle;
    deletedEntries = f.deletedEntries;
    deletedAccounts = f.deletedAccounts;
  }

  // ---------- export / import (same JSON as the desktop app) ----------

  /// Pretty JSON of the whole book, ready to share with the desktop app.
  String exportJson() => const JsonEncoder.withIndent('  ').convert(_toJson());

  /// Current book as a file (used to undo an import).
  LedgerFile snapshot() => LedgerFile.fromMap(
    jsonDecode(jsonEncode(_toJson())) as Map<String, dynamic>,
  );

  /// Merges an imported file into the current book (settings stay local).
  MergeReport mergeWith(LedgerFile other) {
    final (merged, report) = mergeFiles(snapshot(), other);
    if (!report.isNoop) importFile(merged);
    return report;
  }

  /// What [mergeWith] would do, without changing anything.
  MergeReport previewMerge(LedgerFile other) =>
      mergeFiles(snapshot(), other).$2;

  /// Replaces everything with an imported (already validated) file.
  void importFile(LedgerFile f) {
    _apply(f);
    if (!accounts.any((a) => a.id == ledgerAcc)) {
      ledgerAcc = accounts.isEmpty ? 'cash' : accounts.first.id;
    }
    _changed();
  }

  void _changed({bool persist = true}) {
    _invalidate();
    if (persist) _save();
    notifyListeners();
  }

  // ---------- navigation ----------
  void setTab(AppTab t) {
    tab = t;
    notifyListeners();
  }

  void shiftMonth(int off) {
    month = ymShift(month, off);
    notifyListeners();
  }

  void goToCurrentMonth() {
    month = todayStr().substring(0, 7);
    notifyListeners();
  }

  void setReport(String r) {
    report = r;
    notifyListeners();
  }

  void setLedgerAcc(String id) {
    ledgerAcc = id;
    notifyListeners();
  }

  void setMode(String m) {
    mode = m;
    _changed();
  }

  void setHints(bool v) {
    hints = v;
    _changed();
  }

  void setLang(String v) {
    lang = v;
    _changed();
  }

  void setPalette(String v) {
    palette = v;
    _changed();
  }

  void setHomeStyle(String v) {
    homeStyle = v;
    _changed();
  }

  void setTheme(String v) {
    theme = v;
    _changed();
  }

  void setKhoums(bool v) {
    khoums = v;
    _changed();
  }

  // ---------- mutations ----------
  void addEntry(Entry e) {
    entries = [...entries, e];
    month = e.date.substring(0, 7);
    _changed();
  }

  /// Removes the entry and records a tombstone so the deletion syncs.
  void deleteEntry(String id) {
    entries = entries.where((e) => e.id != id).toList();
    deletedEntries = [
      ...deletedEntries.where((t) => t.id != id),
      Tombstone(id, nowMs()),
    ];
    _changed();
  }

  /// Undo of [deleteEntry]: the entry comes back under a new id.
  ///
  /// The tombstone stays. Another device may already have it, and a tombstone
  /// always wins: under its old id the entry would vanish again, everywhere.
  void restoreEntry(Entry e) {
    entries = [
      ...entries,
      Entry(id: newEntryId(), date: e.date, memo: e.memo, lines: e.lines),
    ];
    _changed();
  }

  /// Takes entries out of this device's book without deleting them elsewhere
  /// (no tombstone): for demo entries that must not join a shared folder.
  void leaveOut(Set<String> ids) {
    if (ids.isEmpty) return;
    entries = entries.where((e) => !ids.contains(e.id)).toList();
    _changed();
  }

  int get demoCount => entries.where((e) => isDemoEntry(e.id)).length;

  /// Nothing but demo entries in the book (a fresh install).
  bool get onlyDemo =>
      entries.isNotEmpty && entries.every((e) => isDemoEntry(e.id));

  /// First-launch card dismissed (until the next launch).
  bool demoSeen = false;

  void dismissDemoCard() {
    demoSeen = true;
    notifyListeners();
  }

  /// "Start with an empty book": removes the demo entries, and only those. The
  /// user's own entries, the accounts and their budgets stay. Tombstones make
  /// it hold when other devices have the same demo.
  void removeDemo() {
    final ids = {
      for (final e in entries)
        if (isDemoEntry(e.id)) e.id,
    };
    if (ids.isEmpty) return;
    entries = entries.where((e) => !ids.contains(e.id)).toList();
    final at = nowMs();
    deletedEntries = [
      ...deletedEntries.where((t) => !ids.contains(t.id)),
      for (final id in ids) Tombstone(id, at),
    ];
    _changed();
  }

  /// Creates or updates an account; stamps it so the newest edit wins on merge.
  void upsertAccount(Account a) {
    a = a.copyWith(updatedAt: nowMs());
    final i = accounts.indexWhere((x) => x.id == a.id);
    accounts = i < 0 ? [...accounts, a] : ([...accounts]..[i] = a);
    deletedAccounts = deletedAccounts.where((t) => t.id != a.id).toList();
    _changed();
  }

  /// Account id from its name, like the desktop app ("Fuel" → "fuel", "fuel-2").
  String newAccountId(String name) {
    var base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (base.isEmpty) base = 'account';
    var id = base;
    for (var k = 2; accounts.any((a) => a.id == id); k++) {
      id = '$base-$k';
    }
    return id;
  }

  bool accountInUse(String id) =>
      entries.any((e) => e.lines.any((l) => l.a == id));

  void deleteAccount(String id) {
    accounts = accounts.where((a) => a.id != id).toList();
    deletedAccounts = [
      ...deletedAccounts.where((t) => t.id != id),
      Tombstone(id, nowMs()),
    ];
    if (ledgerAcc == id) ledgerAcc = 'cash';
    _changed();
  }

  void resetDemo() {
    final s = seedData();
    accounts = s.accounts;
    entries = s.entries;
    deletedEntries = [];
    deletedAccounts = [];
    mode = 'simple';
    ledgerAcc = 'cash';
    _changed();
  }

  // ---------- derived data ----------
  List<Account>? _sortedAcc;
  Map<String, Account>? _byId;
  List<Entry>? _sortedEntries;

  void _invalidate() {
    _sortedAcc = null;
    _byId = null;
    _sortedEntries = null;
  }

  /// Accounts ordered asset → liability → equity → income → expense (stable).
  List<Account> get sortedAccounts => _sortedAcc ??= () {
    final idx = {for (final (i, a) in accounts.indexed) a.id: i};
    return [...accounts]..sort((a, b) {
      final t = typeOrder.indexOf(a.type).compareTo(typeOrder.indexOf(b.type));
      return t != 0 ? t : idx[a.id]!.compareTo(idx[b.id]!);
    });
  }();

  Map<String, Account> get byId =>
      _byId ??= {for (final a in accounts) a.id: a};

  String nameOf(String id) => byId[id]?.name ?? S.current.deletedAccount;
  String? typeOf(String id) => byId[id]?.type;

  /// All entries sorted by date (stable on insertion order).
  List<Entry> get sortedEntries => _sortedEntries ??= () {
    final idx = {for (final (i, e) in entries.indexed) e.id: i};
    return [...entries]..sort((a, b) {
      final c = a.date.compareTo(b.date);
      return c != 0 ? c : idx[a.id]!.compareTo(idx[b.id]!);
    });
  }();

  List<Entry> entriesIn(String ym) =>
      sortedEntries.where((e) => e.date.startsWith(ym)).toList();

  ({double inc, double exp}) totals(Iterable<Entry> es) {
    double inc = 0, exp = 0;
    for (final e in es) {
      for (final l in e.lines) {
        final t = typeOf(l.a);
        if (t == 'income') inc += l.cr - l.dr;
        if (t == 'expense') exp += l.dr - l.cr;
      }
    }
    return (inc: inc, exp: exp);
  }

  /// Raw debit-minus-credit balance of [id] up to and including date [to].
  double rawBal(String id, String to) {
    double r = 0;
    for (final e in sortedEntries) {
      if (e.date.compareTo(to) > 0) break;
      for (final l in e.lines) {
        if (l.a == id) r += l.dr - l.cr;
      }
    }
    return r;
  }

  /// Balance shown on the account's normal side.
  double normalBal(Account a, double raw) =>
      normalSide[a.type] == 'dr' ? raw : -raw;

  /// Spending per expense account in [ym], largest first, positives only.
  List<({String id, String name, double amt})> spendingIn(String ym) {
    final spend = <String, double>{};
    for (final e in entriesIn(ym)) {
      for (final l in e.lines) {
        if (typeOf(l.a) == 'expense') {
          spend[l.a] = (spend[l.a] ?? 0) + l.dr - l.cr;
        }
      }
    }
    final list =
        spend.entries
            .where((x) => x.value > 0)
            .map((x) => (id: x.key, name: nameOf(x.key), amt: x.value))
            .toList()
          ..sort((a, b) => b.amt.compareTo(a.amt));
    return list;
  }

  String fmt(num n) => f2(n, khoums);
}

/// How an entry reads in simple mode.
enum Kind { expense, income, transfer }

class EntryView {
  EntryView(this.entry, this.kind, this.title, this.sub);
  final Entry entry;
  final Kind kind;
  final String title;
  final String sub;
}

EntryView describe(AppState s, Entry e) {
  Line? inL, exL;
  for (final l in e.lines) {
    final t = s.typeOf(l.a);
    if (t == 'income' && inL == null) inL = l;
    if (t == 'expense' && exL == null) exL = l;
  }
  if (exL != null) {
    final o = e.lines.where((l) => l.cr > 0 && !identical(l, exL)).firstOrNull;
    return EntryView(
      e,
      Kind.expense,
      s.nameOf(exL.a),
      o != null ? S.current.fromAccount(s.nameOf(o.a)) : '',
    );
  }
  if (inL != null) {
    final o = e.lines.where((l) => l.dr > 0).firstOrNull;
    return EntryView(
      e,
      Kind.income,
      s.nameOf(inL.a),
      o != null ? S.current.intoAccount(s.nameOf(o.a)) : '',
    );
  }
  final d = e.lines.where((l) => l.dr > 0).toList();
  final c = e.lines.where((l) => l.cr > 0).toList();
  final title = d.length == 1 && c.length == 1
      ? '${s.nameOf(c[0].a)} → ${s.nameOf(d[0].a)}'
      : e.memo;
  return EntryView(e, Kind.transfer, title, S.current.transferLower);
}

/// Notifier scope so any widget can read the state.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
    : super(notifier: state);
  static AppState of(BuildContext c) =>
      c.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  static AppState read(BuildContext c) =>
      c.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

/// A parsed and validated ledger file (Android or desktop export).
class LedgerFile {
  LedgerFile({
    required this.accounts,
    required this.entries,
    this.mode = 'simple',
    this.hints = true,
    this.khoums = false,
    this.theme = 'system',
    this.lang,
    this.palette,
    this.homeStyle,
    this.deletedEntries = const [],
    this.deletedAccounts = const [],
  });

  final List<Account> accounts;
  final List<Entry> entries;
  final List<Tombstone> deletedEntries;
  final List<Tombstone> deletedAccounts;
  final String mode;
  final bool hints;
  final bool khoums;
  final String theme;
  final String? lang, palette, homeStyle;

  factory LedgerFile.fromMap(Map<String, dynamic> d) => LedgerFile(
    accounts: (d['accounts'] as List)
        .map((a) => Account.fromJson(a as Map<String, dynamic>))
        .toList(),
    entries: ((d['entries'] as List?) ?? [])
        .map((e) => Entry.fromJson(e as Map<String, dynamic>))
        .toList(),
    mode: (d['mode'] as String?) ?? 'simple',
    hints: (d['hints'] as bool?) ?? true,
    khoums: (d['khoums'] as bool?) ?? false,
    theme: (d['theme'] as String?) ?? 'system',
    lang: d['lang'] as String?,
    palette: d['palette'] as String?,
    homeStyle: d['homeStyle'] as String?,
    deletedEntries: ((d['deletedEntries'] as List?) ?? [])
        .map((t) => Tombstone.fromJson(t as Map<String, dynamic>))
        .toList(),
    deletedAccounts: ((d['deletedAccounts'] as List?) ?? [])
        .map((t) => Tombstone.fromJson(t as Map<String, dynamic>))
        .toList(),
  );

  /// Parses and checks a file before anything is replaced.
  /// Throws [FormatException] with a message meant for the user.
  static LedgerFile parse(String raw) {
    final Object? d;
    try {
      d = jsonDecode(raw);
    } on FormatException {
      throw FormatException(S.current.errNotJson);
    }
    if (d is! Map<String, dynamic> || d['accounts'] is! List) {
      throw FormatException(S.current.errNotLedger);
    }
    final LedgerFile f;
    try {
      f = LedgerFile.fromMap(d);
    } catch (_) {
      throw FormatException(S.current.errMalformed);
    }
    final ids = {for (final a in f.accounts) a.id};
    if (ids.length != f.accounts.length) {
      throw FormatException(S.current.errDupId);
    }
    if (f.accounts.any((a) => !typeOrder.contains(a.type))) {
      throw FormatException(S.current.errUnknownType);
    }
    final date = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    for (final e in f.entries) {
      // A real calendar date: "2026-13-45" matches the pattern but is not one.
      if (!date.hasMatch(e.date) || dateStr(parseDate(e.date)) != e.date) {
        throw FormatException(S.current.errBadDate(e.memo));
      }
      final dr = e.lines.fold(0.0, (t, l) => t + l.dr);
      final cr = e.lines.fold(0.0, (t, l) => t + l.cr);
      if ((dr - cr).abs() >= 0.005) {
        throw FormatException(S.current.errUnbalanced(e.memo, e.date));
      }
      final unknown = e.lines.where((l) => !ids.contains(l.a)).firstOrNull;
      if (unknown != null) {
        throw FormatException(S.current.errUnknownAccount(e.memo));
      }
    }
    return f;
  }
}

// ───────────────────────── Merge (sync) ─────────────────────────

/// What a merge changed, from the local book's point of view.
class MergeReport {
  int entriesAdded = 0;
  int entriesRemoved = 0;
  int accountsAdded = 0;
  int accountsUpdated = 0;
  int accountsRemoved = 0;

  /// Deleted on one side but still used by entries: kept.
  int accountsKeptInUse = 0;

  /// Same id, different content (should not happen: entries are immutable).
  int conflicts = 0;

  bool get isNoop =>
      entriesAdded +
          entriesRemoved +
          accountsAdded +
          accountsUpdated +
          accountsRemoved +
          accountsKeptInUse +
          conflicts ==
      0;
}

List<Tombstone> _unionTombstones(List<Tombstone> a, List<Tombstone> b) {
  final out = <String, int>{for (final t in a) t.id: t.at};
  for (final t in b) {
    out[t.id] = max(out[t.id] ?? t.at, t.at);
  }
  return [for (final e in out.entries) Tombstone(e.key, e.value)];
}

/// Merges [other] into [local] — commutative on data, idempotent. Same rules
/// as `Book::merge` in the desktop app's ledger-core (Rust):
/// * entries: union by id, minus tombstoned ids (entries are immutable);
/// * accounts: union by id, newest `updatedAt` wins; an account tombstone
///   wins over older edits, unless entries still use the account;
/// * settings (mode, hints, khoums, theme) stay local: they are per device.
(LedgerFile, MergeReport) mergeFiles(LedgerFile local, LedgerFile other) {
  final r = MergeReport();
  final deletedEntries = _unionTombstones(
    local.deletedEntries,
    other.deletedEntries,
  );
  var deletedAccounts = _unionTombstones(
    local.deletedAccounts,
    other.deletedAccounts,
  );
  final gone = {for (final t in deletedEntries) t.id};
  final localIds = {for (final e in local.entries) e.id};

  // entries
  final entries = local.entries.where((e) => !gone.contains(e.id)).toList();
  r.entriesRemoved = local.entries.length - entries.length;
  final byId = {for (final e in entries) e.id: e};
  for (final e in other.entries) {
    final x = byId[e.id];
    if (x != null) {
      // The same demo entry in two languages is no conflict: each keeps its own.
      if (!isDemoEntry(e.id) && !sameEntry(x, e)) r.conflicts++;
    } else if (!gone.contains(e.id) && !localIds.contains(e.id)) {
      entries.add(e);
      byId[e.id] = e;
      r.entriesAdded++;
    }
  }

  // accounts: newest version of each id
  final accounts = [...local.accounts];
  for (final a in other.accounts) {
    final i = accounts.indexWhere((x) => x.id == a.id);
    if (i < 0) {
      accounts.add(a);
      r.accountsAdded++;
    } else if (a.updatedAt > accounts[i].updatedAt) {
      // Only a visible change counts (not a bare timestamp bump).
      final x = accounts[i];
      if (x.name != a.name || x.type != a.type || x.budget != a.budget) {
        r.accountsUpdated++;
      }
      accounts[i] = a;
    } else if (a.updatedAt == accounts[i].updatedAt &&
        a.updatedAt != 0 && // never edited: the name is just a translation
        !accounts[i].sameAs(a)) {
      r.conflicts++;
    }
  }

  // account tombstones
  bool used(String id) => entries.any((e) => e.lines.any((l) => l.a == id));
  final kept = <Account>[];
  for (final a in accounts) {
    final t = deletedAccounts.where((t) => t.id == a.id).firstOrNull;
    if (t == null || t.at < a.updatedAt) {
      kept.add(a);
    } else if (used(a.id)) {
      // Still referenced: keep it, and make the decision stick.
      kept.add(a.copyWith(updatedAt: t.at + 1));
      r.accountsKeptInUse++;
    }
  }
  final keptIds = {for (final a in kept) a.id};
  r.accountsRemoved = local.accounts
      .where((a) => !keptIds.contains(a.id))
      .length;
  final localAccIds = {for (final a in local.accounts) a.id};
  r.accountsAdded -= other.accounts
      .where((a) => !localAccIds.contains(a.id) && !keptIds.contains(a.id))
      .length;
  deletedAccounts = deletedAccounts
      .where((t) => !kept.any((a) => a.id == t.id && a.updatedAt > t.at))
      .toList();

  return (
    LedgerFile(
      accounts: kept,
      entries: entries,
      mode: local.mode,
      hints: local.hints,
      khoums: local.khoums,
      theme: local.theme,
      lang: local.lang,
      palette: local.palette,
      homeStyle: local.homeStyle,
      deletedEntries: deletedEntries,
      deletedAccounts: deletedAccounts,
    ),
    r,
  );
}
