import 'package:flutter/material.dart';

import '../format.dart';
import '../l10n.dart';
import '../model.dart';
import '../sheets.dart';
import '../theme.dart';
import '../widgets.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final acc = s.sortedAccounts;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
      children: [
        for (final t in typeOrder)
          if (acc.any((a) => a.type == t)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      S.current.groupLabel(t).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: caps(11, color: C.text, weight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      S.current.typeHint(t),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: body(11, color: C.n700),
                    ),
                  ),
                ],
              ),
            ),
            Panel(
              radius: 24,
              padding: const EdgeInsets.all(4),
              child: Column(
                children: [
                  for (final a in acc.where((a) => a.type == t))
                    Tappable(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 11,
                      ),
                      onTap: () => showAccountSheet(context, a.id),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.name,
                                  style: body(14, weight: FontWeight.w600),
                                ),
                                Text(
                                  a.type == 'expense' && a.budget > 0
                                      ? S.current.budgetPerMonth(f0(a.budget))
                                      : (t == 'income' || t == 'expense'
                                            ? S.current.totalToDate
                                            : S.current.balanceToday),
                                  style: body(11.5, color: C.n700),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            s.fmt(s.normalBal(a, s.rawBal(a.id, '9999-12-31'))),
                            style: body(13, weight: FontWeight.w700, num: true),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        OutlinedButton(
          onPressed: () => showAccountSheet(context, null),
          child: Text(S.current.newAccountButton, style: heading(15)),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => showOpeningSheet(context),
          child: Text(S.current.openingBalances, style: heading(15)),
        ),
      ],
    );
  }
}
