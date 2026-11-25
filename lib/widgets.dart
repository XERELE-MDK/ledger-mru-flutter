import 'package:flutter/material.dart';

import 'theme.dart';

/// Rounded surface panel.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.color,
    this.radius = 28,
    this.padding = const EdgeInsets.fromLTRB(18, 16, 18, 16),
  });
  final Widget child;
  final Color? color;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color ?? C.surface,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: child,
  );
}

enum TagTone { accent, accent2, neutral }

class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.tone = TagTone.neutral});
  final String label;
  final TagTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      TagTone.accent => (C.a100, C.a800),
      TagTone.accent2 => (C.g100, C.g800),
      TagTone.neutral => (C.n100, C.n800),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: body(11, color: fg, spacing: .2)),
    );
  }
}

/// Pill segmented control: inactive options are transparent on [track].
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.track,
    this.selected,
  });
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final Color? track;
  final Color? selected;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: track ?? C.surface,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      children: [
        for (final (v, label) in options)
          Expanded(
            child: Material(
              color: v == value ? (selected ?? C.bg) : Colors.transparent,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onChanged(v),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: body(
                      13,
                      weight: FontWeight.w600,
                      color: v == value ? C.text : C.n700,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Pill chip (accent when selected, surface otherwise).
class Chip2 extends StatelessWidget {
  const Chip2({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? C.accent : C.surface,
    shape: const StadiumBorder(),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          label,
          style: body(
            13,
            weight: FontWeight.w600,
            color: selected ? C.bg : C.text,
          ),
        ),
      ),
    ),
  );
}

/// Rounded progress / share bar.
class Bar extends StatelessWidget {
  const Bar({
    super.key,
    required this.fraction,
    required this.color,
    this.height = 8,
    this.track,
  });
  final double fraction;
  final Color color;
  final double height;
  final Color? track;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: track ?? C.n200,
      borderRadius: BorderRadius.circular(999),
    ),
    alignment: Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: fraction.clamp(0.0, 1.0),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    ),
  );
}

/// Section title in the display face with an optional trailing action.
class SectionHead extends StatelessWidget {
  const SectionHead(
    this.title, {
    super.key,
    this.action,
    this.onAction,
    this.trailing,
  });
  final String title;
  final String? action;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(child: Text(title, style: heading(17))),
      ?trailing,
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}

/// Simple table row with a flexible first column and fixed numeric columns.
class TRow extends StatelessWidget {
  const TRow({
    super.key,
    required this.first,
    required this.cells,
    required this.widths,
    this.style,
    this.padding = const EdgeInsets.symmetric(vertical: 9, horizontal: 6),
    this.border,
  });
  final Widget first;
  final List<Widget> cells;
  final List<double> widths;
  final TextStyle? style;
  final EdgeInsetsGeometry padding;
  final BorderSide? border;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      border: Border(top: border ?? BorderSide(color: C.divider)),
    ),
    child: DefaultTextStyle.merge(
      style: style,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: first),
          for (final (i, c) in cells.indexed)
            SizedBox(
              width: widths[i],
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Align(alignment: Alignment.centerRight, child: c),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Uppercase table header row.
class THead extends StatelessWidget {
  const THead(
    this.labels, {
    super.key,
    required this.widths,
    this.padding = const EdgeInsets.fromLTRB(6, 0, 6, 6),
  });
  final List<String> labels;
  final List<double> widths;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final st = caps(10.5);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(child: Text(labels.first.toUpperCase(), style: st)),
          for (final (i, l) in labels.skip(1).indexed)
            SizedBox(
              width: widths[i],
              child: Text(
                l.toUpperCase(),
                textAlign: TextAlign.right,
                style: st,
              ),
            ),
        ],
      ),
    );
  }
}

/// A pressable row with rounded hover/press feedback.
class Tappable extends StatelessWidget {
  const Tappable({
    super.key,
    required this.child,
    required this.onTap,
    this.radius = 20,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
  });
  final Widget child;
  final VoidCallback onTap;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(radius),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class Hint extends StatelessWidget {
  const Hint(
    this.text, {
    super.key,
    this.padding = const EdgeInsets.symmetric(horizontal: 4),
  });
  final String text;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Text(text, style: body(12, color: C.n700, height: 1.45)),
  );
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 5, left: 2),
    child: Text(text, style: body(12, color: C.text.withValues(alpha: .7))),
  );
}

/// Grab handle shown at the top of bottom sheets.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: C.n400,
        borderRadius: BorderRadius.circular(999),
      ),
    ),
  );
}

/// Pill dropdown matching the text inputs.
class PillSelect<T> extends StatelessWidget {
  const PillSelect({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final T? value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final has = items.any((i) => i.$1 == value);
    return DropdownButtonFormField<T>(
      initialValue: has ? value : null,
      key: ValueKey(value),
      isExpanded: true,
      borderRadius: BorderRadius.circular(20),
      dropdownColor: C.bg,
      icon: Icon(Icons.expand_more_rounded, color: C.n700),
      style: body(14),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: [
        for (final (v, label) in items)
          DropdownMenuItem(
            value: v,
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
