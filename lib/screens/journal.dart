import 'package:flutter/material.dart';

import '../format.dart';
import '../l10n.dart';
import '../model.dart';
import '../sheets.dart';
import '../theme.dart';
import '../widgets.dart';
import 'home.dart' show kindStyle;

class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final mE = s.entriesIn(s.month);
    double jDr = 0, jCr = 0;
    for (final e in mE) {
      for (final l in e.lines) {
        jDr += l.dr;
        jCr += l.cr;
      }
    }
    // Newest first, grouped by day.
    final groups = <(String, List<EntryView>)>[];
    for (final e in mE.reversed) {
      if (groups.isEmpty || groups.last.$1 != e.date) groups.add((e.date, []));
      groups.last.$2.add(describe(s, e));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      children: [
        if (s.isPro) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: C.surface,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: '${S.current.debits} '),
                        TextSpan(
                          text: s.fmt(jDr),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: ' · ${S.current.credits} '),
                        TextSpan(
                          text: s.fmt(jCr),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    style: body(12, num: true),
                  ),
                ),
                Tag(
                  (jDr - jCr).abs() < 0.01
                      ? S.current.balanced
                      : S.current.checkEntries,
                  tone: TagTone.accent2,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        for (final (date, items) in groups) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            child: Text(dayLong(date).toUpperCase(), style: caps(11)),
          ),
          Panel(
            radius: 24,
            padding: const EdgeInsets.all(4),
            child: Column(
              children: [
                for (final v in items) _JournalItem(view: v, pro: s.isPro),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (groups.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            child: Text(
              S.current.nothingRecorded(ymLong(s.month)),
              textAlign: TextAlign.center,
              style: body(14, color: C.n700, height: 1.5),
            ),
          ),
      ],
    );
  }
}

class _JournalItem extends StatelessWidget {
  const _JournalItem({required this.view, required this.pro});
  final EntryView view;
  final bool pro;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final (sign, fg, _, dot) = kindStyle(view.kind);
    return Tappable(
      onTap: () => showEntrySheet(context, view.entry.id),
      child: pro
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(view.entry.memo, style: body(13, weight: FontWeight.w700)),
                const SizedBox(height: 6),
                ...entryLines(s, view.entry, size: 12, numWidth: 74),
              ],
            )
          : Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        view.title,
                        style: body(14, weight: FontWeight.w600),
                      ),
                      Text(
                        '${view.entry.memo} · ${view.sub}',
                        style: body(12, color: C.n700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$sign${s.fmt(view.entry.amount)}',
                  style: body(
                    14,
                    weight: FontWeight.w700,
                    color: fg,
                    num: true,
                  ),
                ),
              ],
            ),
    );
  }
}

/// Dr lines first, Cr lines indented with "to …" — classic journal layout.
List<Widget> entryLines(
  AppState s,
  Entry e, {
  double size = 12,
  double numWidth = 74,
  bool divided = false,
  bool boldName = false,
}) {
  final lines = [...e.lines]..sort((a, b) => b.dr.compareTo(a.dr));
  return [
    for (final l in lines)
      Container(
        padding: EdgeInsets.symmetric(vertical: divided ? 7 : 1),
        decoration: divided
            ? BoxDecoration(
                border: Border(top: BorderSide(color: C.divider)),
              )
            : null,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: l.dr > 0 ? 0 : 18),
                child: Text(
                  l.dr > 0 ? s.nameOf(l.a) : S.current.to(s.nameOf(l.a)),
                  style: body(
                    size,
                    color: boldName ? C.text : C.n800,
                    weight: boldName ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: numWidth,
              child: Text(
                l.dr != 0 ? s.fmt(l.dr) : '',
                textAlign: TextAlign.right,
                style: body(size, num: true),
              ),
            ),
            SizedBox(
              width: numWidth,
              child: Text(
                l.cr != 0 ? s.fmt(l.cr) : '',
                textAlign: TextAlign.right,
                style: body(size, num: true, color: C.n700),
              ),
            ),
          ],
        ),
      ),
  ];
}
