import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../format.dart';
import '../l10n.dart';
import '../model.dart';
import '../sheets.dart';
import '../theme.dart';
import '../widgets.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      children: [
        Segmented<String>(
          options: [
            ('tb', S.current.trialBalance),
            ('mom', S.current.monthly),
            ('bud', S.current.budgets),
          ],
          value: s.report,
          onChanged: s.setReport,
        ),
        const SizedBox(height: 14),
        switch (s.report) {
          'mom' => const _Monthly(),
          'bud' => const _Budgets(),
          _ => const _TrialBalance(),
        },
      ],
    );
  }
}

class _TrialBalance extends StatelessWidget {
  const _TrialBalance();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final ym = s.month;
    final end = '$ym-31';
    double tDr = 0, tCr = 0;
    final rows = <(Account, double)>[];
    for (final a in s.sortedAccounts) {
      final r = s.rawBal(a.id, end);
      if (r.abs() < 0.005) continue;
      if (r > 0) {
        tDr += r;
      } else {
        tCr += -r;
      }
      rows.add((a, r));
    }
    final balanced = (tDr - tCr).abs() < 0.01;
    const w = [80.0, 80.0];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  S.current.balancesAsAt(
                    S.current.lang == 'ja'
                        ? '${ym.substring(0, 4)}年${dayShort('$ym-${pad2(daysIn(ym))}')}'
                        : '${dayShort('$ym-${pad2(daysIn(ym))}')} ${ym.substring(0, 4)}',
                  ),
                  style: body(12, color: C.n700),
                ),
              ),
              Tag(
                balanced ? S.current.balanced : S.current.outOfBalance,
                tone: TagTone.accent2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Panel(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              THead(
                [S.current.colAccount, S.current.colDebit, S.current.colCredit],
                widths: w,
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
              ),
              for (final (a, r) in rows)
                TRow(
                  widths: w,
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 2,
                  ),
                  style: body(12.5, num: true),
                  first: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.name, style: body(12.5, weight: FontWeight.w600)),
                      Text(
                        S.current.typeLabel(a.type),
                        style: body(11, color: C.n700),
                      ),
                    ],
                  ),
                  cells: [
                    Text(r > 0 ? s.fmt(r) : ''),
                    Text(r < 0 ? s.fmt(-r) : ''),
                  ],
                ),
              TRow(
                widths: w,
                padding: const EdgeInsets.fromLTRB(2, 10, 2, 6),
                border: BorderSide(color: C.text, width: 2),
                style: body(13, weight: FontWeight.w700, num: true),
                first: Text(S.current.total),
                cells: [Text(s.fmt(tDr)), Text(s.fmt(tCr))],
              ),
            ],
          ),
        ),
        if (s.hints) ...[const SizedBox(height: 10), Hint(S.current.tbHint)],
      ],
    );
  }
}

class _Monthly extends StatelessWidget {
  const _Monthly();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final ym = s.month;
    final raw = [
      for (var i = 5; i >= 0; i--)
        (() {
          final m = ymShift(ym, -i);
          final t = s.totals(s.entriesIn(m));
          return (m: m, inc: t.inc, exp: t.exp);
        })(),
    ];
    final mx = raw.fold(1.0, (v, x) => math.max(v, math.max(x.inc, x.exp)));
    final withData = raw.where((x) => x.inc != 0 || x.exp != 0).toList();
    final avgExp = withData.isEmpty
        ? 0
        : withData.fold(0.0, (t, x) => t + x.exp) / withData.length;
    final summary = withData.isEmpty
        ? S.current.noEntries6
        : S.current.avgSpend(f0(avgExp), compareText(s));
    const w = [76.0, 76.0, 76.0];

    Widget legend(Color c, String t) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(t, style: body(12)),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  legend(C.g500, S.current.income),
                  const SizedBox(width: 14),
                  legend(C.a500, S.current.outcome),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 150,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final x in raw)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            _Col(frac: x.inc / mx, color: C.g500),
                            const SizedBox(width: 3),
                            _Col(frac: x.exp / mx, color: C.a500),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final x in raw)
                    Expanded(
                      child: Text(
                        monthAbbr(x.m),
                        textAlign: TextAlign.center,
                        style: body(
                          11,
                          weight: x.m == ym ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        THead([
          S.current.colMonth,
          S.current.colIn,
          S.current.colOut,
          S.current.colKept,
        ], widths: w),
        for (final x in raw)
          TRow(
            widths: w,
            style: body(12.5, num: true),
            first: Text(
              ymShort(x.m),
              style: TextStyle(
                fontWeight: x.m == ym ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
            cells: [
              Text(f0(x.inc)),
              Text(f0(x.exp)),
              Text(
                f0(x.inc - x.exp),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: x.inc - x.exp < 0 ? C.a700 : C.g700,
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        Panel(
          color: C.g200,
          radius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Text(summary, style: body(13, color: C.g900, height: 1.45)),
        ),
      ],
    );
  }
}

/// "You spent N MRU more/less than last month."
String compareText(AppState s) {
  final prevM = ymShift(s.month, -1);
  final prev = s.totals(s.entriesIn(prevM));
  final cur = s.totals(s.entriesIn(s.month));
  if (prev.inc == 0 && prev.exp == 0) return S.current.noDataLastMonth;
  final d = cur.exp - prev.exp;
  if (d > 0) return S.current.spentMore(f0(d));
  if (d < 0) return S.current.spentLess(f0(-d));
  return S.current.sameSpending;
}

class _Col extends StatelessWidget {
  const _Col({required this.frac, required this.color});
  final double frac;
  final Color color;
  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: frac.clamp(0.0, 1.0),
    child: Container(
      width: 14,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    ),
  );
}

class _Budgets extends StatelessWidget {
  const _Budgets();

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final spend = {for (final c in s.spendingIn(s.month)) c.id: c.amt};
    final budAcc = s.sortedAccounts
        .where((a) => a.type == 'expense' && a.budget > 0)
        .toList();
    double bTot = 0, bSp = 0;
    for (final a in budAcc) {
      bTot += a.budget;
      bSp += spend[a.id] ?? 0;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                S.current.spentOfBudget(ymLong(s.month)),
                style: body(12, color: C.n700),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(f0(bSp), style: heading(26)),
                  const SizedBox(width: 6),
                  Text(
                    '/ ${f0(bTot)} MRU',
                    style: body(14, color: C.n700, num: true),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Bar(
                fraction: bSp / (bTot == 0 ? 1 : bTot),
                color: C.g600,
                height: 10,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final a in budAcc)
          Builder(
            builder: (context) {
              final sp = spend[a.id] ?? 0;
              final p = sp / a.budget;
              final over = p > 1, close = !over && p >= .8;
              final bar = over ? C.a600 : (close ? C.a400 : C.g500);
              final col = over || close ? C.a700 : C.g700;
              final status = over
                  ? S.current.overBudget(f0(sp - a.budget))
                  : close
                  ? S.current.closeToLimit(f0(a.budget - sp))
                  : S.current.left(f0(a.budget - sp));
              return Tappable(
                radius: 18,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                onTap: () => showAccountSheet(context, a.id),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            a.name,
                            style: body(13.5, weight: FontWeight.w600),
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: f0(sp)),
                              TextSpan(
                                text: ' / ${f0(a.budget)}',
                                style: TextStyle(color: C.n700),
                              ),
                            ],
                          ),
                          style: body(13.5, num: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Bar(fraction: p, color: bar),
                    const SizedBox(height: 6),
                    Text(
                      status,
                      style: body(12, weight: FontWeight.w600, color: col),
                    ),
                  ],
                ),
              );
            },
          ),
        if (budAcc.isEmpty)
          Hint(
            S.current.noBudgets,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        if (s.hints && budAcc.isNotEmpty)
          Hint(
            S.current.tapToEditBudget,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
      ],
    );
  }
}
