import 'l10n.dart';

// Dates are stored as "YYYY-MM-DD" strings; everything shown to the user goes
// through the current language (S.current): month and day names, number
// grouping ("1,250" / "1 250"), decimal mark ("1,250.5" / "1 250,5").

String pad2(int n) => n.toString().padLeft(2, '0');

String dateStr(DateTime d) => '${d.year}-${pad2(d.month)}-${pad2(d.day)}';
String todayStr() => dateStr(DateTime.now());

DateTime parseDate(String ds) {
  final p = ds.split('-').map(int.parse).toList();
  return DateTime(p[0], p[1], p.length > 2 ? p[2] : 1);
}

String ymShift(String ym, int off) {
  final d = parseDate(ym);
  final s = DateTime(d.year, d.month + off, 1);
  return '${s.year}-${pad2(s.month)}';
}

String get _lang => S.current.lang;

/// "November 2026" · "novembre 2026" · "2026年11月"
String ymLong(String ym) {
  final d = parseDate(ym);
  final m = S.current.months[d.month - 1];
  return _lang == 'ja' ? '${d.year}年$m' : '$m ${d.year}';
}

/// "Nov 2026" · "nov. 2026" · "2026年11月"
String ymShort(String ym) {
  final d = parseDate(ym);
  final m = S.current.monthsShort[d.month - 1];
  return _lang == 'ja' ? '${d.year}年$m' : '$m ${d.year}';
}

/// "Nov" · "nov." · "11月"
String monthAbbr(String ym) => S.current.monthsShort[parseDate(ym).month - 1];

/// "November" · "novembre" · "11月"
String monthName(String ym) => S.current.months[parseDate(ym).month - 1];

int daysIn(String ym) {
  final d = parseDate(ym);
  return DateTime(d.year, d.month + 1, 0).day;
}

/// "Fri 20 Nov" · "ven. 20 nov." · "11月20日(金)"
String dayLong(String ds) {
  final d = parseDate(ds);
  final wd = S.current.weekdays[d.weekday - 1];
  return switch (_lang) {
    'ja' => '${d.month}月${d.day}日($wd)',
    _ => '$wd ${d.day} ${S.current.monthsShort[d.month - 1]}',
  };
}

/// "20 Nov" · "20 nov." · "11月20日"
String dayShort(String ds) {
  final d = parseDate(ds);
  return _lang == 'ja'
      ? '${d.month}月${d.day}日'
      : '${d.day} ${S.current.monthsShort[d.month - 1]}';
}

/// Thousands separator: narrow no-break space in French, comma otherwise.
String get _groupSep => _lang == 'fr' ? ' ' : ',';
String get _decimalSep => _lang == 'fr' ? ',' : '.';

String _group(int v) {
  final s = v.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(_groupSep);
    b.write(s[i]);
  }
  return b.toString();
}

/// Whole MRU, grouped, with a true minus sign.
String f0(num n) {
  final v = n.round();
  return '${v < 0 ? '−' : ''}${_group(v.abs())}';
}

/// MRU with khoums: always 2 decimals when [dec], otherwise up to 2 only when needed.
String f2(num n, bool dec) {
  final cents = (n * 100).round();
  final neg = cents < 0;
  final a = cents.abs();
  final whole = a ~/ 100, frac = a % 100;
  var s = _group(whole);
  if (dec) {
    s += '$_decimalSep${pad2(frac)}';
  } else if (frac != 0) {
    s += frac % 10 == 0
        ? '$_decimalSep${frac ~/ 10}'
        : '$_decimalSep${pad2(frac)}';
  }
  return '${neg ? '−' : ''}$s';
}

/// Largest amount accepted in one entry (guards against "1e400" → Infinity).
const maxAmount = 1e12;

/// Reads what people type, whatever the separators:
/// "1 250,50" · "1,250.50" · "1.250,50" · "1250.5" · "1,250" (= 1250) · "12,5" (= 12.5).
/// Returns 0 when the text is not a finite amount between 0 and [maxAmount].
double parseAmount(String input) {
  var t = input.replaceAll(RegExp(r'[\s   ]'), '');
  if (t.isEmpty || !RegExp(r'^[0-9.,]+$').hasMatch(t)) return 0;
  final lastComma = t.lastIndexOf(','), lastDot = t.lastIndexOf('.');
  if (lastComma >= 0 && lastDot >= 0) {
    // Both used: the last one is the decimal mark, the other groups thousands.
    final dec = lastComma > lastDot ? ',' : '.';
    final grp = dec == ',' ? '.' : ',';
    t = t.replaceAll(grp, '').replaceAll(dec, '.');
  } else if (lastComma >= 0) {
    // "1,250" / "12,345,678": thousands. "12,5" / "0,75": decimals.
    t = RegExp(r'^\d{1,3}(,\d{3})+$').hasMatch(t)
        ? t.replaceAll(',', '')
        : t.replaceAll(',', '.');
  } else if (lastDot >= 0) {
    // "1.250.000" (several groups): thousands. "1250.5" / "1.250": decimals.
    if (RegExp(r'^\d{1,3}(\.\d{3}){2,}$').hasMatch(t)) {
      t = t.replaceAll('.', '');
    }
  }
  final v = double.tryParse(t);
  if (v == null || !v.isFinite || v < 0 || v > maxAmount) return 0;
  return v;
}
