import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../format.dart';
import '../l10n.dart';
import '../model.dart';
import '../sheets.dart';
import '../theme.dart';
import '../widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final ym = s.month;
    final end = '$ym-31';
    final mE = s.entriesIn(ym);
    final t = s.totals(mE);
    final net = t.inc - t.exp;
    final cats = s.spendingIn(ym);
    final maxCat = cats.isEmpty ? 1.0 : cats.first.amt;
    final assets = s.sortedAccounts.where((a) => a.type == 'asset').toList();
    final assetTotal = assets.fold(0.0, (v, a) => v + s.rawBal(a.id, end));
    final recent = mE.reversed.take(4).map((e) => describe(s, e)).toList();

    final l = S.current;
    final rateText = t.inc > 0
        ? (net >= 0
              ? l.rateKept((net / t.inc * 100).round())
              : l.rateSpent((t.exp / t.inc * 100).round()))
        : l.noIncomeYet;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      children: [
        // Hero
        ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Container(
            color: C.heroBg,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -62,
                  top: -62,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: C.heroCircle,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${net >= 0 ? l.youKept : l.youOverspent} · ${ymLong(ym)}'
                          .toUpperCase(),
                      style: caps(12, color: C.heroCaps),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              f0(net.abs()),
                              style: heading(46, color: C.heroText, height: 1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'MRU',
                          style: body(
                            15,
                            weight: FontWeight.w600,
                            color: C.heroCaps,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(rateText, style: body(13, color: C.heroSub)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _Tile(
                label: l.income,
                icon: Icons.south_west_rounded,
                value: f0(t.inc),
                bg: C.g200,
                fg: C.g800,
                strong: C.g900,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Tile(
                label: l.outcome,
                icon: Icons.north_east_rounded,
                value: f0(t.exp),
                bg: C.a200,
                fg: C.a800,
                strong: C.a900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Where it went
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHead(
                l.whereItWent,
                action: l.budgets,
                onAction: () {
                  s.report = 'bud';
                  s.setTab(AppTab.reports);
                },
              ),
              const SizedBox(height: 6),
              for (final (i, c) in cats.take(5).indexed) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.name,
                        style: body(13, weight: FontWeight.w600),
                      ),
                    ),
                    Text(f0(c.amt), style: body(13, color: C.n700, num: true)),
                  ],
                ),
                const SizedBox(height: 5),
                Bar(
                  fraction: math.max(.04, c.amt / maxCat),
                  color: C.pal[i % C.pal.length],
                ),
                const SizedBox(height: 12),
              ],
              if (cats.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(l.noSpending, style: body(13, color: C.n700)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Money I have
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHead(
                l.moneyIHave,
                trailing: Text(
                  '${f0(assetTotal)} MRU',
                  style: body(15, weight: FontWeight.w700, num: true),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final a in assets)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: C.n100,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${a.name}  '),
                            TextSpan(
                              text: f0(s.rawBal(a.id, end)),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        style: body(12, color: C.n800, num: true),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SectionHead(
            l.latest,
            action: l.tabJournal,
            onAction: () => s.setTab(AppTab.journal),
          ),
        ),
        for (final v in recent) EntryRow(view: v),
        if (recent.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l.nothingIn(ymLong(ym)),
              style: body(13, color: C.n700),
            ),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.icon,
    required this.value,
    required this.bg,
    required this.fg,
    required this.strong,
  });
  final String label;
  final IconData icon;
  final String value;
  final Color bg, fg, strong;

  @override
  Widget build(BuildContext context) => Panel(
    color: bg,
    radius: 24,
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(
              label,
              style: body(12, weight: FontWeight.w600, color: fg),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: heading(22, color: strong)),
        ),
      ],
    ),
  );
}

/// Colors per entry kind: (sign, amount color, avatar bg, dot).
(String, Color, Color, Color) kindStyle(Kind k) => switch (k) {
  Kind.expense => ('−', C.a700, C.a200, C.a500),
  Kind.income => ('+', C.g700, C.g200, C.g600),
  Kind.transfer => ('', C.n700, C.n200, C.n500),
};

/// Entry row with an initial avatar (Home → Latest).
class EntryRow extends StatelessWidget {
  const EntryRow({super.key, required this.view});
  final EntryView view;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final (sign, fg, bg, _) = kindStyle(view.kind);
    return Tappable(
      onTap: () => showEntrySheet(context, view.entry.id),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Text(
              view.title.isEmpty
                  ? '?'
                  : view.title.characters.first.toUpperCase(),
              style: body(14, weight: FontWeight.w700, color: fg),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  view.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: body(14, weight: FontWeight.w600),
                ),
                Text(
                  '${dayShort(view.entry.date)} · ${view.sub}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: body(12, color: C.n700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$sign${s.fmt(view.entry.amount)}',
            style: body(14, weight: FontWeight.w700, color: fg, num: true),
          ),
        ],
      ),
    );
  }
}
