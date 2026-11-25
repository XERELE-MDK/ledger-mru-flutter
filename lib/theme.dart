import 'package:flutter/material.dart';

/// A complete visual theme: colours *and* fonts. [C] exposes the current one
/// to every widget; [LedgerApp] sets it and rebuilds the tree on change.
class AppTheme {
  const AppTheme({
    required this.id,
    required this.dark,
    required this.headingFont,
    required this.bodyFont,
    this.headingWeight = FontWeight.w400,
    this.headingSpacing = -0.015,
    required this.bg,
    required this.surface,
    required this.text,
    required this.accent,
    required this.accent2,
    required this.divider,
    required this.n,
    required this.a,
    required this.g,
    required this.hero,
    required this.pal,
  });

  final String id;
  final bool dark;
  final String headingFont, bodyFont;
  final FontWeight headingWeight;

  /// Letter-spacing of headings, as a fraction of the font size.
  final double headingSpacing;
  final Color bg, surface, text, accent, accent2, divider;

  /// Tonal ramps, steps 100…900: neutral, accent (spending), accent 2 (income).
  final List<Color> n, a, g;

  /// "You kept" card: background, circle, big text, caps, subline.
  final List<Color> hero;

  /// Category colours (bars, pebbles).
  final List<Color> pal;

  /// Builds a theme from a handful of base colours: ramps are mixed towards
  /// white/black (light themes) or the ground/text (dark themes), so steps
  /// 100–300 stay "tinted fills" and 700–900 "text on fills" in every theme.
  factory AppTheme.generate({
    required String id,
    required bool dark,
    required String headingFont,
    required String bodyFont,
    FontWeight headingWeight = FontWeight.w700,
    double headingSpacing = 0,
    required Color bg,
    required Color surface,
    required Color text,
    required Color accent,
    required Color accent2,
  }) {
    Color mix(Color x, Color y, double t) => Color.lerp(x, y, t)!;
    const white = Color(0xFFFFFFFF), black = Color(0xFF000000);
    List<Color> ramp(Color c) => dark
        ? [
            mix(bg, c, .14),
            mix(bg, c, .24),
            mix(bg, c, .40),
            mix(bg, c, .78),
            c,
            mix(c, white, .15),
            mix(c, white, .35),
            mix(c, white, .58),
            mix(c, white, .78),
          ]
        : [
            mix(white, c, .10),
            mix(white, c, .22),
            mix(white, c, .42),
            mix(white, c, .70),
            c,
            mix(c, black, .18),
            mix(c, black, .36),
            mix(c, black, .54),
            mix(c, black, .70),
          ];
    final n = [
      dark ? mix(bg, text, .09) : mix(bg, white, .55),
      for (final t in [.10, .18, .28, .44, .57, .68, .82, .94])
        mix(bg, text, t),
    ];
    final a = ramp(accent), g = ramp(accent2);
    final heroBg = dark ? mix(bg, accent2, .26) : g[7];
    return AppTheme(
      id: id,
      dark: dark,
      headingFont: headingFont,
      bodyFont: bodyFont,
      headingWeight: headingWeight,
      headingSpacing: headingSpacing,
      bg: bg,
      surface: surface,
      text: text,
      accent: accent,
      accent2: accent2,
      divider: text.withValues(alpha: .16),
      n: n,
      a: a,
      g: g,
      hero: [
        heroBg,
        mix(heroBg, accent2, dark ? .22 : .30),
        dark ? text : bg,
        dark ? g[6] : g[1],
        dark ? g[7] : g[0],
      ],
      pal: dark
          ? [a[4], g[4], a[6], g[6], a[3], g[3], n[4], n[5]]
          : [a[4], g[4], a[2], g[2], a[6], g[6], n[3], n[5]],
    );
  }
}

List<Color> _hex(List<int> v) => [for (final x in v) Color(x)];

/// Organic — the original design system (light), hand-tuned values.
final organicLight = AppTheme(
  id: 'organic',
  dark: false,
  headingFont: 'Caprasimo',
  bodyFont: 'Figtree',
  bg: const Color(0xFFF5EAD8),
  surface: const Color(0xFFEBDDC5),
  text: const Color(0xFF201E1D),
  accent: const Color(0xFFC67139),
  accent2: const Color(0xFF7A8A5E),
  divider: const Color(0x29201E1D),
  n: _hex([
    0xFFF9F4ED,
    0xFFEEE7DB,
    0xFFDCD3C4,
    0xFFC0B6A5,
    0xFFA19786,
    0xFF82796A,
    0xFF645C50,
    0xFF474238,
    0xFF2E2B25,
  ]),
  a: _hex([
    0xFFFFF2EB,
    0xFFFFE1D0,
    0xFFFFC6A5,
    0xFFF6A06B,
    0xFFD67F48,
    0xFFB2622D,
    0xFF8C491A,
    0xFF643312,
    0xFF402310,
  ]),
  g: _hex([
    0xFFF0FAE1,
    0xFFE1EECC,
    0xFFCCDBB2,
    0xFFAEBF92,
    0xFF8FA073,
    0xFF728157,
    0xFF56633F,
    0xFF3D472B,
    0xFF272E1B,
  ]),
  hero: _hex([0xFF3D472B, 0xFF56633F, 0xFFF5EAD8, 0xFFE1EECC, 0xFFF0FAE1]),
  pal: _hex([
    0xFFD67F48,
    0xFF8FA073,
    0xFFFFC6A5,
    0xFFCCDBB2,
    0xFF8C491A,
    0xFF56633F,
    0xFFC0B6A5,
    0xFF82796A,
  ]),
);

/// Organic — dark variant made for this app (ramps mirrored by role).
final organicDark = AppTheme(
  id: 'organic',
  dark: true,
  headingFont: 'Caprasimo',
  bodyFont: 'Figtree',
  bg: const Color(0xFF1C1A17),
  surface: const Color(0xFF2A2621),
  text: const Color(0xFFF3E9D8),
  accent: const Color(0xFFD67F48),
  accent2: const Color(0xFF8FA073),
  divider: const Color(0x29F3E9D8),
  n: _hex([
    0xFF35312B,
    0xFF3A352E,
    0xFF4A443B,
    0xFF5E574C,
    0xFF82796A,
    0xFFA19786,
    0xFFB3A996,
    0xFFD2C8B6,
    0xFFF0E6D4,
  ]),
  a: _hex([
    0xFF3A2618,
    0xFF4A2C18,
    0xFF6B3A1C,
    0xFFC06A33,
    0xFFD67F48,
    0xFFE08E57,
    0xFFF0A370,
    0xFFFFC6A5,
    0xFFFFE1D0,
  ]),
  g: _hex([
    0xFF26301C,
    0xFF2F3A22,
    0xFF3F4C2E,
    0xFF6E7F55,
    0xFF8FA073,
    0xFFA3B487,
    0xFFB8C89C,
    0xFFD3E0BD,
    0xFFE7F2D6,
  ]),
  hero: _hex([0xFF2C3620, 0xFF36422A, 0xFFF3E9D8, 0xFFB8C89C, 0xFFD3E0BD]),
  pal: _hex([
    0xFFD67F48,
    0xFF8FA073,
    0xFFF6A06B,
    0xFFAEBF92,
    0xFFB2622D,
    0xFF728157,
    0xFFA19786,
    0xFF82796A,
  ]),
);

/// The other complete themes: each changes colours *and* fonts.
final themes = <AppTheme>[
  // Espresso, milk foam and caramel; a coffee-menu serif.
  AppTheme.generate(
    id: 'cappuccino',
    dark: true,
    headingFont: 'DMSerifDisplay',
    bodyFont: 'Nunito',
    headingWeight: FontWeight.w400,
    bg: const Color(0xFF1E1813),
    surface: const Color(0xFF2C231C),
    text: const Color(0xFFF3E7D9),
    accent: const Color(0xFFD29B6C),
    accent2: const Color(0xFFA9B77E),
  ),
  // True black for OLED screens, sharp grotesk, neon accents.
  AppTheme.generate(
    id: 'amoled',
    dark: true,
    headingFont: 'SpaceGrotesk',
    bodyFont: 'Inter',
    headingSpacing: -0.02,
    bg: const Color(0xFF000000),
    surface: const Color(0xFF111111),
    text: const Color(0xFFF2F2F2),
    accent: const Color(0xFFFF6A3D),
    accent2: const Color(0xFF3DDC97),
  ),
  // Ice, glacier blue and aurora teal; rounded geometric type.
  AppTheme.generate(
    id: 'arctic',
    dark: false,
    headingFont: 'Comfortaa',
    bodyFont: 'Lexend',
    bg: const Color(0xFFEEF4F8),
    surface: const Color(0xFFDDE8F0),
    text: const Color(0xFF0F2230),
    accent: const Color(0xFF2E77B0),
    accent2: const Color(0xFF2F8F82),
  ),
  // Dunes, henna and indigo cloth — a nod to Mauritania; editorial serif.
  AppTheme.generate(
    id: 'sahara',
    dark: false,
    headingFont: 'PlayfairDisplay',
    bodyFont: 'Karla',
    bg: const Color(0xFFF4E4C8),
    surface: const Color(0xFFE9D3AD),
    text: const Color(0xFF2A1C10),
    accent: const Color(0xFFB4502A),
    accent2: const Color(0xFF2E6670),
  ),
  // Cherry blossom and young leaves; soft rounded type.
  AppTheme.generate(
    id: 'sakura',
    dark: false,
    headingFont: 'Quicksand',
    bodyFont: 'Mulish',
    bg: const Color(0xFFFBF1F3),
    surface: const Color(0xFFF3DEE4),
    text: const Color(0xFF2E1A22),
    accent: const Color(0xFFCF4F74),
    accent2: const Color(0xFF5E8F5A),
  ),
];

/// Theme for a palette id + the Organic light/dark choice.
AppTheme themeFor(String palette, {required bool organicDark}) {
  if (palette == 'organic') {
    return organicDark ? organicDarkTheme : organicLight;
  }
  return themes.firstWhere((t) => t.id == palette, orElse: () => organicLight);
}

AppTheme get organicDarkTheme => organicDark;

/// Current theme tokens, read by every widget.
class C {
  /// Set by [LedgerApp] before building; the whole tree is rebuilt on change.
  static AppTheme t = organicLight;
  static bool get dark => t.dark;

  static Color get bg => t.bg;
  static Color get surface => t.surface;
  static Color get text => t.text;
  static Color get accent => t.accent;
  static Color get accent2 => t.accent2;
  static Color get divider => t.divider;
  static Color get n100 => t.n[0];
  static Color get n200 => t.n[1];
  static Color get n300 => t.n[2];
  static Color get n400 => t.n[3];
  static Color get n500 => t.n[4];
  static Color get n600 => t.n[5];
  static Color get n700 => t.n[6];
  static Color get n800 => t.n[7];
  static Color get n900 => t.n[8];
  static Color get a100 => t.a[0];
  static Color get a200 => t.a[1];
  static Color get a300 => t.a[2];
  static Color get a400 => t.a[3];
  static Color get a500 => t.a[4];
  static Color get a600 => t.a[5];
  static Color get a700 => t.a[6];
  static Color get a800 => t.a[7];
  static Color get a900 => t.a[8];
  static Color get g100 => t.g[0];
  static Color get g200 => t.g[1];
  static Color get g300 => t.g[2];
  static Color get g400 => t.g[3];
  static Color get g500 => t.g[4];
  static Color get g600 => t.g[5];
  static Color get g700 => t.g[6];
  static Color get g800 => t.g[7];
  static Color get g900 => t.g[8];

  static Color get heroBg => t.hero[0];
  static Color get heroCircle => t.hero[1];
  static Color get heroText => t.hero[2];
  static Color get heroCaps => t.hero[3];
  static Color get heroSub => t.hero[4];

  static List<Color> get pal => t.pal;
}

const _tab = [FontFeature.tabularFigures()];

TextStyle heading(double size, {Color? color, double height = 1.12}) =>
    TextStyle(
      fontFamily: C.t.headingFont,
      // Display faces often lack "−" (U+2212) or Japanese: the body font,
      // then the system fonts (Noto CJK…), fill the gaps.
      fontFamilyFallback: [C.t.bodyFont],
      fontWeight: C.t.headingWeight,
      fontSize: size,
      height: height,
      letterSpacing: C.t.headingSpacing * size,
      color: color ?? C.text,
      fontFeatures: _tab,
    );

TextStyle body(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color? color,
  bool num = false,
  double? height,
  double? spacing,
  FontStyle? style,
}) => TextStyle(
  fontFamily: C.t.bodyFont,
  fontSize: size,
  fontWeight: weight,
  color: color ?? C.text,
  height: height,
  letterSpacing: spacing,
  fontStyle: style,
  fontFeatures: num ? _tab : null,
);

/// Small uppercase label (e.g. table headers, group titles).
TextStyle caps(
  double size, {
  Color? color,
  FontWeight weight = FontWeight.w400,
}) => body(size, color: color ?? C.n700, weight: weight, spacing: size * 0.08);

ThemeData buildTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: C.accent,
        brightness: C.dark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: C.accent,
        onPrimary: C.bg,
        secondary: C.accent2,
        surface: C.bg,
        onSurface: C.text,
        surfaceContainerHighest: C.surface,
        outline: C.divider,
      );
  final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(999));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: C.bg,
    fontFamily: C.t.bodyFont,
    splashFactory: InkRipple.splashFactory,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: C.accent,
      selectionColor: C.accent.withValues(alpha: .3),
      selectionHandleColor: C.accent,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: C.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: body(14, color: C.n500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: C.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: C.divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(999),
        borderSide: BorderSide(color: C.accent, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
            backgroundColor: C.accent,
            foregroundColor: C.bg,
            shape: pill,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            textStyle: heading(15),
          ).copyWith(
            overlayColor: WidgetStateProperty.all(
              C.a700.withValues(alpha: .25),
            ),
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: C.text,
        side: BorderSide(color: C.divider),
        shape: pill,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        textStyle: heading(14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: C.a700,
        shape: pill,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        minimumSize: const Size(0, 32),
        textStyle: heading(13),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: C.surface,
      indicatorColor: C.a300,
      surfaceTintColor: Colors.transparent,
      height: 70,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => body(
          11,
          weight: FontWeight.w600,
          color: s.contains(WidgetState.selected) ? C.a900 : C.n700,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          size: 21,
          color: s.contains(WidgetState.selected) ? C.a900 : C.n700,
        ),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: C.bg,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: Colors.black.withValues(alpha: C.dark ? .6 : .45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: C.n900,
      contentTextStyle: body(13, color: C.bg),
      actionTextColor: C.a300,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: C.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      titleTextStyle: heading(20),
      contentTextStyle: body(14, color: C.n800),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: C.bg,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: C.heroBg,
      headerForegroundColor: C.heroText,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? C.bg : C.n600,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? C.accent : C.n300,
      ),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );
}
