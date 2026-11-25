import 'package:flutter/material.dart';

import '../format.dart';
import '../l10n.dart';
import '../model.dart';
import '../theme.dart';
import '../widgets.dart';

class LedgerScreen extends StatelessWidget {
  const LedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final acc = s.sortedAccounts;
    if (acc.isEmpty) {
      return Center(
        child: Text(S.current.noAccounts, style: body(14, color: C.n700)),
      );
    }
    final la = s.byId[s.ledgerAcc] ?? acc.first;
    final ym = s.month;
    var run = s.rawBal(la.id, '$ym-00');
    final openBal = run;
    double lDr = 0, lCr = 0;
    final rows = <(Entry, Line, double)>[];
    for (final e in s.entriesIn(ym)) {
      for (final l in e.lines) {
        if (l.a != la.id) continue;
        run += l.dr - l.cr;
        lDr += l.dr;
        lCr += l.cr;
        rows.add((e, l, run));
      }
    }
    const w = [62.0, 62.0, 72.0];

    return ListView(
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: acc.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (_, i) => Chip2(
              label: acc[i].name,
              selected: acc[i].id == la.id,
              onTap: () => s.setLedgerAcc(acc[i].id),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Panel(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(la.name, style: heading(20))),
                    Tag(S.current.typeLabel(la.type), tone: TagTone.accent),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  S.current.normalSide(
                    S.current.typeHint(la.type),
                    normalSide[la.type] == 'dr',
                  ),
                  style: body(12, color: C.n700),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.current.opening,
                            style: body(11, color: C.n700),
                          ),
                          Text(
                            s.fmt(s.normalBal(la, openBal)),
                            style: body(15, weight: FontWeight.w700, num: true),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.current.closing,
                            style: body(11, color: C.n700),
                          ),
                          Text(s.fmt(s.normalBal(la, run)), style: heading(20)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              THead([
                S.current.colEntry,
                S.current.colDebit,
                S.current.colCredit,
                S.current.colBalance,
              ], widths: w),
              for (final (e, l, bal) in rows)
                TRow(
                  widths: w,
                  style: body(12, num: true),
                  first: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.memo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: body(12, weight: FontWeight.w600),
                      ),
                      Text(dayShort(e.date), style: body(11, color: C.n700)),
                    ],
                  ),
                  cells: [
                    Text(l.dr != 0 ? s.fmt(l.dr) : ''),
                    Text(l.cr != 0 ? s.fmt(l.cr) : ''),
                    Text(
                      s.fmt(s.normalBal(la, bal)),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              TRow(
                widths: w,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 6,
                ),
                border: BorderSide(color: C.text, width: 2),
                style: body(12, weight: FontWeight.w700, num: true),
                first: Text(S.current.monthTotal),
                cells: [Text(s.fmt(lDr)), Text(s.fmt(lCr)), const SizedBox()],
              ),
              if (rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 6,
                  ),
                  child: Text(
                    S.current.noMovement(ymLong(ym)),
                    style: body(13, color: C.n700),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
