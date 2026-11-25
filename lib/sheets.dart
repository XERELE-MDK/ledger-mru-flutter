import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'files.dart';
import 'format.dart';
import 'l10n.dart';
import 'model.dart';
import 'screens/journal.dart' show entryLines;
import 'theme.dart';
import 'widgets.dart';

void toast(BuildContext context, String msg, {SnackBarAction? action}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      content: Text(
        msg,
        textAlign: action == null ? TextAlign.center : TextAlign.start,
      ),
      duration: Duration(milliseconds: action == null ? 1800 : 4000),
      action: action,
      persist: false, // Flutter keeps snack bars with an action forever
      width: action == null ? 200 : null,
    ),
  );
}

/// Lets the user put the latest unreadable data in a file of their choice.
Future<void> saveDamagedCopy(BuildContext context) async {
  final s = AppScope.read(context);
  try {
    final ok = await Files.save(
      'ledger-mru-damaged-${todayStr()}.json',
      s.damagedCopies.last,
    );
    if (ok && context.mounted) toast(context, S.current.copySaved);
  } catch (e) {
    if (context.mounted) toast(context, S.current.exportFailed(e));
  }
}

Future<T?> _sheet<T>(BuildContext context, Widget child) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) => AppScope(
        state: AppScope.read(context),
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
          child: SafeArea(top: false, child: child),
        ),
      ),
    );

/// Sheet layout: handle + scrollable fields, with the action buttons pinned
/// below so they stay reachable on short screens and above the keyboard.
class SheetBody extends StatelessWidget {
  const SheetBody({super.key, required this.children, required this.footer});
  final List<Widget> children;
  final Widget footer;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 10, bottom: 14),
        child: SheetHandle(),
      ),
      Flexible(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
        child: footer,
      ),
    ],
  );
}

// ───────────────────────── New entry ─────────────────────────

Future<void> showAddSheet(BuildContext context) =>
    _sheet(context, const _AddEntry());

class _AddEntry extends StatefulWidget {
  const _AddEntry();
  @override
  State<_AddEntry> createState() => _AddEntryState();
}

class _AddEntryState extends State<_AddEntry> {
  late AppState s;
  Kind kind = Kind.expense;
  String? cat, via, dr, cr;
  late String date;
  final amount = TextEditingController();
  final memo = TextEditingController();
  String err = '';

  List<Account> catOpts(Kind k) {
    final t = switch (k) {
      Kind.expense => ['expense'],
      Kind.income => ['income'],
      Kind.transfer => ['asset', 'liability'],
    };
    return s.accounts.where((a) => t.contains(a.type)).toList();
  }

  List<Account> get viaOpts => s.accounts
      .where((a) => a.type == 'asset' || a.type == 'liability')
      .toList();

  @override
  void initState() {
    super.initState();
    s = AppScope.read(context);
    final exp = catOpts(Kind.expense).firstOrNull;
    final v = viaOpts.firstOrNull;
    cat = exp?.id;
    via = v?.id;
    dr = exp?.id;
    cr = v?.id;
    final t = todayStr();
    date = t.substring(0, 7) == s.month ? t : '${s.month}-01';
  }

  @override
  void dispose() {
    amount.dispose();
    memo.dispose();
    super.dispose();
  }

  void setKind(Kind k) {
    final opts = catOpts(k);
    var c = opts.firstOrNull;
    if (k == Kind.transfer) c = opts.where((o) => o.id != via).firstOrNull ?? c;
    setState(() {
      kind = k;
      cat = c?.id;
      err = '';
    });
  }

  (String?, String?) sides() {
    if (s.isPro) return (dr, cr);
    if (kind == Kind.income) return (via, cat);
    return (cat, via);
  }

  void save() {
    final amt = parseAmount(amount.text);
    if (!(amt > 0)) return setState(() => err = S.current.errAmount);
    final (d, c) = sides();
    if (d == null || c == null) {
      return setState(() => err = S.current.errBothAccounts);
    }
    if (d == c) {
      return setState(() => err = S.current.errSameAccount);
    }
    var m = memo.text.trim();
    if (m.isEmpty) {
      m = !s.isPro
          ? (kind == Kind.transfer
                ? S.current.transferTo(s.nameOf(d))
                : s.nameOf(kind == Kind.income ? c : d))
          : '${s.nameOf(d)} / ${s.nameOf(c)}';
    }
    s.addEntry(
      Entry(
        id: newEntryId(),
        date: date,
        memo: m,
        lines: [Line(d, amt, 0), Line(c, 0, amt)],
      ),
    );
    final nav = Navigator.of(context);
    toast(context, S.current.entrySaved);
    nav.pop();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: parseDate(date),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => date = dateStr(picked));
  }

  @override
  Widget build(BuildContext context) {
    s = AppScope.of(context);
    final acc = s.sortedAccounts;
    final (pDr, pCr) = sides();
    final pAmt = parseAmount(amount.text);
    final gap = const SizedBox(height: 14);

    return SheetBody(
      footer: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.current.cancel),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton(
              onPressed: save,
              child: Text(S.current.saveEntry),
            ),
          ),
        ],
      ),
      children: [
        Row(
          children: [
            Expanded(child: Text(S.current.newEntry, style: heading(20))),
            Tag(s.isPro ? S.current.modePro : S.current.modeSimple),
          ],
        ),
        gap,
        if (!s.isPro) ...[
          Segmented<Kind>(
            options: [
              (Kind.expense, S.current.expense),
              (Kind.income, S.current.incomeKind),
              (Kind.transfer, S.current.transfer),
            ],
            value: kind,
            onChanged: setKind,
          ),
          gap,
          FieldLabel(switch (kind) {
            Kind.expense => S.current.category,
            Kind.income => S.current.source,
            Kind.transfer => S.current.moveTo,
          }),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final a in catOpts(kind))
                Chip2(
                  label: a.name,
                  selected: a.id == cat,
                  onTap: () => setState(() {
                    cat = a.id;
                    err = '';
                  }),
                ),
            ],
          ),
          gap,
          FieldLabel(switch (kind) {
            Kind.expense => S.current.paidWith,
            Kind.income => S.current.receivedIn,
            Kind.transfer => S.current.moveFrom,
          }),
          PillSelect<String>(
            value: via,
            items: [for (final a in viaOpts) (a.id, a.name)],
            onChanged: (v) => setState(() {
              via = v;
              err = '';
            }),
          ),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FieldLabel(S.current.debitDr),
                    PillSelect<String>(
                      value: dr,
                      items: [
                        for (final a in acc)
                          (a.id, '${a.name} · ${S.current.typeLabel(a.type)}'),
                      ],
                      onChanged: (v) => setState(() {
                        dr = v;
                        err = '';
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FieldLabel(S.current.creditCr),
                    PillSelect<String>(
                      value: cr,
                      items: [
                        for (final a in acc)
                          (a.id, '${a.name} · ${S.current.typeLabel(a.type)}'),
                      ],
                      onChanged: (v) => setState(() {
                        cr = v;
                        err = '';
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        gap,
        FieldLabel(S.current.amountMru),
        TextField(
          controller: amount,
          autofocus: false,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
          ],
          style: heading(24),
          decoration: InputDecoration(
            hintText: '0',
            hintStyle: heading(24, color: C.n500),
            contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          onChanged: (_) => setState(() => err = ''),
        ),
        // What was understood, in this language's format ("1,250" → 1 250).
        if (amount.text.trim().isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 18),
            child: Text(
              pAmt > 0
                  ? S.current.amountPreview(s.fmt(pAmt))
                  : S.current.errAmount,
              style: body(12, color: pAmt > 0 ? C.n700 : C.a700, num: true),
            ),
          ),
        gap,
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FieldLabel(S.current.date),
                  Material(
                    color: C.surface,
                    shape: StadiumBorder(side: BorderSide(color: C.divider)),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: pickDate,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(dayShort(date), style: body(14)),
                            ),
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 16,
                              color: C.n700,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FieldLabel(S.current.note),
                  TextField(
                    controller: memo,
                    textCapitalization: TextCapitalization.sentences,
                    style: body(14),
                    decoration: InputDecoration(
                      hintText: kind == Kind.income
                          ? S.current.hintIncome
                          : S.current.hintExpense,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (s.hints) ...[
          gap,
          Panel(
            radius: 20,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: DefaultTextStyle.merge(
              style: body(12, num: true),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(S.current.willBeRecorded, style: caps(10.5)),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${S.current.drShort} ${pDr != null ? s.nameOf(pDr) : '—'}',
                        ),
                      ),
                      Text(
                        s.fmt(pAmt),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${S.current.crShort} ${pCr != null ? s.nameOf(pCr) : '—'}',
                            style: TextStyle(color: C.n700),
                          ),
                        ),
                        Text(
                          s.fmt(pAmt),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: C.n700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (err.isNotEmpty) ...[
          gap,
          Text(
            err,
            style: body(13, weight: FontWeight.w600, color: C.a700),
          ),
        ],
      ],
    );
  }
}

// ───────────────────────── Entry detail ─────────────────────────

Future<void> showEntrySheet(BuildContext context, String id) =>
    _sheet(context, _EntryDetail(id: id));

class _EntryDetail extends StatelessWidget {
  const _EntryDetail({required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final e = s.entries.where((x) => x.id == id).firstOrNull;
    if (e == null) return const SizedBox(height: 40);
    return SheetBody(
      footer: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(foregroundColor: C.a700),
              onPressed: () {
                final messengerCtx = Navigator.of(context).context;
                s.deleteEntry(e.id);
                Navigator.pop(context);
                toast(
                  messengerCtx,
                  S.current.entryDeleted,
                  action: SnackBarAction(
                    label: S.current.undo,
                    onPressed: () => s.restoreEntry(e),
                  ),
                );
              },
              child: Text(S.current.delete),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(S.current.done),
            ),
          ),
        ],
      ),
      children: [
        Text(e.memo, style: heading(20)),
        Text(dayLong(e.date), style: body(13, color: C.n700)),
        const SizedBox(height: 14),
        Panel(
          radius: 24,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              THead(
                [S.current.colAccount, S.current.colDebit, S.current.colCredit],
                widths: const [80, 80],
                padding: const EdgeInsets.only(bottom: 6),
              ),
              ...entryLines(
                s,
                e,
                size: 13,
                numWidth: 80,
                divided: true,
                boldName: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── Account editor ─────────────────────────

Future<void> showAccountSheet(BuildContext context, String? id) =>
    _sheet(context, _AccountEditor(id: id));

class _AccountEditor extends StatefulWidget {
  const _AccountEditor({required this.id});
  final String? id;
  @override
  State<_AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends State<_AccountEditor> {
  late AppState s;
  final name = TextEditingController();
  final budget = TextEditingController();
  String type = 'expense';
  String err = '';

  @override
  void initState() {
    super.initState();
    s = AppScope.read(context);
    final a = widget.id == null ? null : s.byId[widget.id];
    if (a != null) {
      name.text = a.name;
      type = a.type;
      budget.text = a.budget > 0
          ? (a.budget == a.budget.roundToDouble()
                ? a.budget.toInt().toString()
                : a.budget.toString())
          : '';
    }
  }

  @override
  void dispose() {
    name.dispose();
    budget.dispose();
    super.dispose();
  }

  void save() {
    final n = name.text.trim();
    if (n.isEmpty) return setState(() => err = S.current.errAccountName);
    final b = type == 'expense' ? parseAmount(budget.text) : 0.0;
    final existing = widget.id == null ? null : s.byId[widget.id];
    final acc = existing != null
        ? existing.copyWith(name: n, type: type, budget: b)
        : Account(id: s.newAccountId(n), name: n, type: type, budget: b);
    s.upsertAccount(acc);
    toast(context, S.current.accountSaved);
    Navigator.pop(context);
  }

  void delete() {
    final id = widget.id!;
    if (s.accountInUse(id)) {
      return setState(() => err = S.current.errAccountInUse);
    }
    s.deleteAccount(id);
    toast(context, S.current.accountDeleted);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    return SheetBody(
      footer: Row(
        children: [
          if (widget.id != null) ...[
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: C.a700),
                onPressed: delete,
                child: Text(S.current.delete),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            flex: 2,
            child: FilledButton(onPressed: save, child: Text(S.current.save)),
          ),
        ],
      ),
      children: [
        Text(
          widget.id != null ? S.current.editAccount : S.current.newAccount,
          style: heading(20),
        ),
        gap,
        FieldLabel(S.current.name),
        TextField(
          controller: name,
          textCapitalization: TextCapitalization.sentences,
          style: body(14),
          decoration: InputDecoration(hintText: S.current.hintAccount),
          onChanged: (_) => setState(() => err = ''),
        ),
        gap,
        FieldLabel(S.current.type),
        PillSelect<String>(
          value: type,
          items: [for (final t in typeOrder) (t, S.current.typeOption(t))],
          onChanged: (v) => setState(() {
            type = v;
            err = '';
          }),
        ),
        if (type == 'expense') ...[
          gap,
          FieldLabel(S.current.monthlyBudget),
          TextField(
            controller: budget,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
            ],
            style: body(14, num: true),
            decoration: const InputDecoration(hintText: '0'),
          ),
        ],
        if (err.isNotEmpty) ...[
          gap,
          Text(
            err,
            style: body(13, weight: FontWeight.w600, color: C.a700),
          ),
        ],
      ],
    );
  }
}

// ───────────────────────── Opening balances ─────────────────────────

Future<void> showOpeningSheet(BuildContext context) =>
    _sheet(context, const _Opening());

/// What the user has and owes at the start, one amount per account.
class _Opening extends StatefulWidget {
  const _Opening();
  @override
  State<_Opening> createState() => _OpeningState();
}

class _OpeningState extends State<_Opening> {
  final fields = <String, TextEditingController>{};
  late String date;
  String err = '';

  @override
  void initState() {
    super.initState();
    final s = AppScope.read(context);
    date = s.openingDate ?? todayStr();
    for (final r in s.openingRows) {
      fields[r.account.id] = TextEditingController(
        text: r.amount == 0 ? '' : f2(r.amount, false),
      );
    }
  }

  @override
  void dispose() {
    for (final f in fields.values) {
      f.dispose();
    }
    super.dispose();
  }

  void save() {
    final s = AppScope.read(context);
    final had = s.openingDate != null;
    final e = s.setOpening(date, {
      for (final f in fields.entries) f.key: f.value.text,
    });
    if (e != null) return setState(() => err = e);
    toast(
      context,
      had && s.openingDate == null
          ? S.current.openingRemoved
          : S.current.openingSaved,
    );
    Navigator.pop(context);
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: parseDate(date),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => date = dateStr(picked));
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    const gap = SizedBox(height: 14);
    return SheetBody(
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Above the buttons: visible even when the list is scrolled.
          if (err.isNotEmpty) ...[
            Text(
              err,
              style: body(13, weight: FontWeight.w600, color: C.a700),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(S.current.cancel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: save,
                  child: Text(S.current.save),
                ),
              ),
            ],
          ),
        ],
      ),
      children: [
        Text(S.current.openingBalances, style: heading(20)),
        const SizedBox(height: 6),
        Hint(S.current.openingText, padding: EdgeInsets.zero),
        gap,
        FieldLabel(S.current.date),
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 170,
            child: Material(
              color: C.surface,
              shape: StadiumBorder(side: BorderSide(color: C.divider)),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: pickDate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          S.current.lang == 'ja'
                              ? '${date.substring(0, 4)}年${dayShort(date)}'
                              : '${dayShort(date)} ${date.substring(0, 4)}',
                          style: body(14),
                        ),
                      ),
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: C.n700,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        gap,
        for (final r in s.openingRows)
          if (fields[r.account.id] case final field?)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.account.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: body(14, weight: FontWeight.w600),
                        ),
                        Text(
                          S.current.typeHint(r.account.type),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: body(11.5, color: C.n700),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      key: ValueKey('opening-${r.account.id}'),
                      controller: field,
                      textAlign: TextAlign.right,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
                      ],
                      style: body(15, weight: FontWeight.w700, num: true),
                      decoration: const InputDecoration(hintText: '0'),
                      onChanged: (_) => setState(() => err = ''),
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
