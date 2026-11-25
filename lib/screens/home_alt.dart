// The three alternative home screens of the prototype (1b, 1c, 1d), chosen in
// Settings → Home screen. Same data and calculations as the Overview (1a).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../format.dart';
import '../l10n.dart';
import '../model.dart';
import '../sheets.dart';
import '../theme.dart';
import '../widgets.dart';
import 'reports.dart' show compareText;

/// Readable ink on a coloured shape (dark text on light fills and vice versa).
Color inkOn(Color c) =>
    c.computeLuminance() > .38 ? const Color(0xFF1B1714) : Colors.white;

// ───────────────────────── 1b · Editorial ─────────────────────────

/// The month as one sentence, a stacked category bar and a comparison.
class EditorialHome extends StatelessWidget {
  const EditorialHome({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final l = S.current;
    final ym = s.month;
    final t = s.totals(s.entriesIn(ym));
    final net = t.inc - t.exp;
    final cats = s.spendingIn(ym);
    final exp = t.exp == 0 ? 1.0 : t.exp;
    final parts = l.editorialParts(
      inc: f0(t.inc),
      exp: f0(t.exp),
      kept: f0(net.abs()),
      short: net < 0,
    );
    final big = heading(30, height: 1.25);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 110),
      children: [
        Text(
          ymLong(ym).toUpperCase(),
          style: caps(12, color: C.a700, weight: FontWeight.w700),
        ),
        const SizedBox(height: 18),
        Text.rich(
          TextSpan(
            style: big,
            children: [
              TextSpan(text: parts[0]),
              TextSpan(
                text: parts[1],
                style: TextStyle(color: C.g700),
              ),
              TextSpan(text: parts[2]),
              TextSpan(
                text: parts[3],
                style: TextStyle(color: C.a600),
              ),
              TextSpan(text: parts[4]),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: net < 0 ? C.a200 : C.g200,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(parts[5], style: big),
                ),
              ),
              TextSpan(text: parts[6]),
            ],
          ),
        ),
        const SizedBox(height: 26),
        if (cats.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 22,
              child: Row(
                children: [
                  for (final (i, c) in cats.indexed) ...[
                    if (i > 0) const SizedBox(width: 3),
                    Expanded(
                      flex: math.max(1, (c.amt / exp * 1000).round()),
                      child: Container(
                        decoration: BoxDecoration(
                          color: C.pal[i % C.pal.length],
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, box) => Wrap(
              runSpacing: 8,
              children: [
                for (final (i, c) in cats.indexed)
                  SizedBox(
                    width: box.maxWidth / 2,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: C.pal[i % C.pal.length],
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: body(13),
                            ),
                          ),
                          Text(
                            '${(c.amt / exp * 100).round()}${l.lang == 'fr' ? ' %' : '%'}',
                            style: body(13, weight: FontWeight.w700, num: true),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ] else
          Text(l.noSpending, style: body(13, color: C.n700)),
        const SizedBox(height: 24),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l.comparedWith(monthName(ymShift(ym, -1))),
                style: body(12, color: C.n700),
              ),
              const SizedBox(height: 6),
              Text(
                compareText(s),
                style: body(15, weight: FontWeight.w600, height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => showAddSheet(context),
          child: Text(l.recordSomething),
        ),
      ],
    );
  }
}

// ───────────────────────── 1c · T-account ─────────────────────────

/// The month as a debit / credit page: income on the left, spending on the
/// right, the difference carried down so both sides balance.
class TAccountHome extends StatelessWidget {
  const TAccountHome({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final l = S.current;
    final ym = s.month;
    final mE = s.entriesIn(ym);
    final t = s.totals(mE);
    final net = t.inc - t.exp;

    final incomes = <String, double>{};
    for (final e in mE) {
      for (final ln in e.lines) {
        if (s.typeOf(ln.a) == 'income') {
          incomes[ln.a] = (incomes[ln.a] ?? 0) + ln.cr - ln.dr;
        }
      }
    }
    final left = [
      for (final MapEntry(:key, :value) in incomes.entries)
        (s.nameOf(key), value, false),
      if (net < 0) (l.shortfallCd, -net, true),
    ];
    final right = [
      for (final c in s.spendingIn(ym)) (c.name, c.amt, false),
      if (net > 0) (l.keptCd, net, true),
    ];
    // Trial balance at the end of the month (every account), like Reports.
    double sum = 0;
    for (final a in s.accounts) {
      sum += s.rawBal(a.id, '$ym-31');
    }
    final balanced = sum.abs() < .01;

    Widget side(String title, Color tint, List<(String, double, bool)> rows) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title.toUpperCase(),
              style: caps(11, color: tint, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final (name, amt, italic) in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: italic ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: body(
                          13,
                          style: italic ? FontStyle.italic : null,
                          color: italic ? C.n700 : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      f0(amt),
                      style: body(13, weight: FontWeight.w700, num: true),
                    ),
                  ],
                ),
              ),
          ],
        );
    final totalStyle = body(14, weight: FontWeight.w700, num: true);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
      children: [
        Row(
          children: [
            Expanded(child: Text(ymLong(ym), style: heading(22))),
            Tag(balanced ? l.balanced : l.outOfBalance, tone: TagTone.accent2),
          ],
        ),
        const SizedBox(height: 14),
        Center(child: Text(l.myMonth, style: heading(18))),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: C.text, width: 3)),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 260),
                    padding: const EdgeInsets.fromLTRB(0, 10, 12, 0),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: C.text, width: 3),
                      ),
                    ),
                    child: side(l.drMoneyIn, C.g700, left),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 0, 0),
                    child: side(l.crMoneyOut, C.a700, right),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Totals, ruled off with a double line as in a paper ledger.
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: C.text, width: 1.5)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Text(
                    f0(math.max(t.inc, t.exp)),
                    textAlign: TextAlign.right,
                    style: totalStyle,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    f0(math.max(t.inc, t.exp)),
                    textAlign: TextAlign.right,
                    style: totalStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(height: 1.5, color: C.text),
        const SizedBox(height: 2.5),
        Container(height: 1.5, color: C.text),
        const SizedBox(height: 18),
        Panel(
          color: net < 0 ? C.a200 : C.g200,
          radius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  net >= 0 ? l.carriedDown : l.spentMoreThanEarned,
                  style: body(13, color: net < 0 ? C.a900 : C.g900),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                f0(net.abs()),
                style: heading(20, color: net < 0 ? C.a900 : C.g900),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── 1d · Pebbles ─────────────────────────

/// Spending as soft round shapes (area ∝ amount) and the month's daily rhythm.
class PebblesHome extends StatelessWidget {
  const PebblesHome({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final l = S.current;
    final ym = s.month;
    final mE = s.entriesIn(ym);
    final t = s.totals(mE);
    final cats = s.spendingIn(ym).take(8).toList();
    final maxCat = cats.isEmpty ? 1.0 : cats.first.amt;

    final nd = daysIn(ym);
    final perDay = List<double>.filled(nd, 0);
    for (final e in mE) {
      final d = int.parse(e.date.substring(8)) - 1;
      for (final ln in e.lines) {
        if (s.typeOf(ln.a) == 'expense' && d >= 0 && d < nd) {
          perDay[d] += ln.dr - ln.cr;
        }
      }
    }
    final peak = perDay.fold(0.0, math.max);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ymLong(ym), style: body(12, color: C.n700)),
                  Text('${l.outLabel} ${f0(t.exp)}', style: heading(25)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(l.inLabel, style: body(12, color: C.n700)),
                Text(
                  f0(t.inc),
                  style: body(
                    15,
                    weight: FontWeight.w700,
                    color: C.g700,
                    num: true,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 300),
          child: Center(
            child: cats.isEmpty
                ? Text(l.noSpending, style: body(13, color: C.n700))
                : Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (i, c) in cats.indexed)
                        Builder(
                          builder: (_) {
                            final size = 56 + math.sqrt(c.amt / maxCat) * 86;
                            final color = C.pal[i % C.pal.length];
                            final ink = inkOn(color);
                            final fs = size > 100 ? 13.0 : 10.5;
                            return Container(
                              width: size,
                              height: size,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    c.name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: body(
                                      fs,
                                      weight: FontWeight.w600,
                                      color: ink,
                                      height: 1.1,
                                    ),
                                  ),
                                  Text(
                                    f0(c.amt),
                                    style: body(
                                      fs,
                                      weight: FontWeight.w700,
                                      color: ink,
                                      num: true,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Panel(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.dailySpending,
                      style: body(12, weight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    l.peak(f0(peak)),
                    style: body(12, color: C.n700, num: true),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 60,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final v in perDay)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1),
                          child: Container(
                            height: math.max(4, peak == 0 ? 4 : v / peak * 60),
                            decoration: BoxDecoration(
                              color: peak > 0 && v >= peak * .6
                                  ? C.a500
                                  : C.g400,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final d in ['1', '15', '$nd'])
                    Text(d, style: body(10.5, color: C.n700)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
