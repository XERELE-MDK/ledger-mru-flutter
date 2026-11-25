// Settings: language, theme, home screen, bookkeeping mode, display, data & sync.
//
// Shown in place of the tabs (AppState.settingsOpen), not as a pushed route:
// changing the theme or the language rebuilds the whole MaterialApp, and a
// route would be lost — the user would land back on Home after every tap.

import 'package:flutter/material.dart';

import '../files.dart';
import '../format.dart';
import '../l10n.dart';
import '../model.dart';
import '../sheets.dart';
import '../sync.dart';
import '../theme.dart';
import '../widgets.dart';

void openSettings(BuildContext context) =>
    AppScope.read(context).setSettingsOpen(true);

/// Removes the demo entries after a confirmation. Offers Undo, except with sync
/// on: the other devices would remove them again.
Future<void> startEmpty(BuildContext context) async {
  final s = AppScope.read(context);
  final synced = SyncScope.read(context).on;
  final l = S.current;
  final demo = s.demoCount;
  final own = s.entries.length - demo;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(l.startEmpty(own == 0)),
      content: SingleChildScrollView(
        child: Text(
          [
            l.startEmptyText(demo, own),
            if (synced) l.startEmptySynced,
            if (own == 0) l.openingThen,
          ].join('\n\n'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: Text(l.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          child: Text(l.remove),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  final before = s.snapshot();
  s.removeDemo();
  toast(
    context,
    l.demoRemoved,
    action: synced
        ? null
        : SnackBarAction(label: l.undo, onPressed: () => s.importFile(before)),
  );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final l = S.current;
    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(6, 18, 6, 8),
      child: Text(
        title.toUpperCase(),
        style: caps(11, color: C.text, weight: FontWeight.w700),
      ),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
      children: [
        // ── language
        section(l.language),
        Panel(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              for (final code in languages)
                Expanded(
                  child: _Choice(
                    selected: l.lang == code,
                    onTap: () => s.setLang(code),
                    child: Text(
                      S.languageNames[code]!,
                      textAlign: TextAlign.center,
                      style: body(
                        14,
                        weight: FontWeight.w700,
                        color: l.lang == code ? C.bg : C.text,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // ── theme
        section(l.theme),
        Hint(l.themeHint),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, box) {
            final w = (box.maxWidth - 10) / 2;
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final t in [
                  s.theme == 'dark' ? organicDark : organicLight,
                  ...themes,
                ])
                  SizedBox(
                    width: w,
                    child: ThemeCard(
                      theme: t,
                      selected: s.palette == t.id,
                      onTap: () => s.setPalette(t.id),
                    ),
                  ),
              ],
            );
          },
        ),
        if (s.palette == 'organic') ...[
          const SizedBox(height: 12),
          FieldLabel(l.brightness),
          Segmented<String>(
            options: [
              ('system', l.system),
              ('light', l.light),
              ('dark', l.dark),
            ],
            value: s.theme,
            onChanged: s.setTheme,
          ),
        ],

        // ── home screen
        section(l.homeStyle),
        Panel(
          padding: const EdgeInsets.all(4),
          child: Column(
            children: [
              for (final (id, icon, name, sub) in [
                (
                  'overview',
                  Icons.dashboard_rounded,
                  l.styleOverview,
                  l.styleOverviewSub,
                ),
                (
                  'editorial',
                  Icons.notes_rounded,
                  l.styleEditorial,
                  l.styleEditorialSub,
                ),
                (
                  'taccount',
                  Icons.vertical_split_rounded,
                  l.styleTAccount,
                  l.styleTAccountSub,
                ),
                (
                  'pebbles',
                  Icons.bubble_chart_rounded,
                  l.stylePebbles,
                  l.stylePebblesSub,
                ),
              ])
                Tappable(
                  onTap: () => s.setHomeStyle(id),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: s.homeStyle == id ? C.accent : C.n200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          size: 20,
                          color: s.homeStyle == id ? C.bg : C.n700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: body(14, weight: FontWeight.w600),
                            ),
                            Text(sub, style: body(12, color: C.n700)),
                          ],
                        ),
                      ),
                      if (s.homeStyle == id)
                        Icon(
                          Icons.check_circle_rounded,
                          color: C.accent,
                          size: 22,
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        // ── bookkeeping mode
        section(l.bookkeepingMode),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Segmented<String>(
                options: [('simple', l.modeSimple), ('pro', l.modePro)],
                value: s.mode,
                onChanged: s.setMode,
                track: C.bg,
                selected: C.surface,
              ),
              const SizedBox(height: 10),
              Text(
                s.isPro ? l.modeProText : l.modeSimpleText,
                style: body(12.5, color: C.n700, height: 1.45),
              ),
            ],
          ),
        ),

        // ── display
        section(l.display),
        Panel(
          padding: const EdgeInsets.fromLTRB(18, 10, 10, 10),
          child: Column(
            children: [
              _Toggle(
                title: l.teachingHints,
                sub: l.teachingHintsSub,
                value: s.hints,
                onChanged: s.setHints,
              ),
              Divider(height: 1, color: C.divider),
              _Toggle(
                title: l.showKhoums,
                sub: l.showKhoumsSub,
                value: s.khoums,
                onChanged: s.setKhoums,
              ),
            ],
          ),
        ),

        // ── data & sync
        section(l.dataAndSync),
        const _DataPanel(),
        const SizedBox(height: 12),
        const _SyncPanel(),
        const SizedBox(height: 8),
        if (s.demoCount > 0)
          Center(
            child: TextButton(
              onPressed: () => startEmpty(context),
              child: Text(l.startEmpty(s.onlyDemo)),
            ),
          ),
        Center(
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: C.n700,
              textStyle: body(12),
            ),
            onPressed: () async {
              if (SyncScope.read(context).on) {
                return showDialog<void>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: Text(l.resetDemoQ),
                    content: Text(l.resetNeedsSyncOff),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: Text(l.gotIt),
                      ),
                    ],
                  ),
                );
              }
              final ok = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text(l.resetDemoQ),
                  content: Text(l.resetDemoText),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: Text(l.cancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(c, true),
                      child: Text(l.reset),
                    ),
                  ],
                ),
              );
              if (ok == true && context.mounted) {
                s.resetDemo();
                toast(context, l.demoRestored);
              }
            },
            child: Text(l.resetDemo),
          ),
        ),
      ],
    );
  }
}

/// Pill choice (language).
class _Choice extends StatelessWidget {
  const _Choice({
    required this.selected,
    required this.onTap,
    required this.child,
  });
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? C.accent : Colors.transparent,
    shape: const StadiumBorder(),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: child,
      ),
    ),
  );
}

/// A theme drawn in its *own* colours and fonts, so you see it before choosing.
class ThemeCard extends StatelessWidget {
  const ThemeCard({
    super.key,
    required this.theme,
    required this.selected,
    required this.onTap,
  });
  final AppTheme theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final l = S.current;
    TextStyle head(double size) => TextStyle(
      fontFamily: t.headingFont,
      fontFamilyFallback: [t.bodyFont],
      fontWeight: t.headingWeight,
      fontSize: size,
      height: 1.1,
      color: t.text,
    );
    TextStyle bodyT(double size, {Color? color, FontWeight? weight}) =>
        TextStyle(
          fontFamily: t.bodyFont,
          fontSize: size,
          color: color ?? t.text,
          fontWeight: weight,
        );
    return Material(
      color: t.bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: selected ? C.accent : C.divider,
          width: selected ? 3 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l.themeName(t.id),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: head(18),
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_circle_rounded, size: 18, color: t.accent),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l.themeMood(t.id),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: bodyT(11, color: t.n[6]),
              ),
              const SizedBox(height: 10),
              // A tiny "You kept" card + income/spending tiles in the theme.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: t.hero[0],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        f0(8890),
                        style: head(16).copyWith(color: t.hero[2]),
                      ),
                    ),
                    Text(
                      'MRU',
                      style: bodyT(
                        9,
                        color: t.hero[3],
                        weight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  for (final c in [t.g[1], t.a[1], t.surface]) ...[
                    Expanded(
                      child: Container(
                        height: 16,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Container(
                    width: 26,
                    height: 16,
                    decoration: BoxDecoration(
                      color: t.accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.title,
    required this.sub,
    required this.value,
    required this.onChanged,
  });
  final String title, sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => onChanged(!value),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: body(14, weight: FontWeight.w600)),
                Text(sub, style: body(11.5, color: C.n700)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    ),
  );
}

/// Export / import of the whole book as JSON (same format as the desktop app).
class _DataPanel extends StatelessWidget {
  const _DataPanel();

  Future<void> _export(BuildContext context) async {
    final s = AppScope.read(context);
    try {
      final ok = await Files.save(
        'ledger-mru-${todayStr()}.json',
        s.exportJson(),
      );
      if (ok && context.mounted) {
        toast(context, S.current.exported(s.entries.length));
      }
    } catch (e) {
      if (context.mounted) toast(context, S.current.exportFailed(e));
    }
  }

  Future<void> _import(BuildContext context) async {
    final s = AppScope.read(context);
    final String? raw;
    try {
      raw = await Files.open();
    } catch (e) {
      if (context.mounted) toast(context, S.current.cannotReadFile(e));
      return;
    }
    if (raw == null || !context.mounted) return;
    final LedgerFile f;
    try {
      f = LedgerFile.parse(raw);
    } on FormatException catch (e) {
      toast(context, e.message);
      return;
    }
    final dates = f.entries.map((e) => e.date).toList()..sort();
    final span = dates.isEmpty
        ? ''
        : S.current.span(
            '${dayShort(dates.first)} ${dates.first.substring(0, 4)}',
            '${dayShort(dates.last)} ${dates.last.substring(0, 4)}',
          );
    final preview = s.previewMerge(f);
    // With sync on, the other devices would send the replaced entries back.
    final synced = SyncScope.read(context).on;
    final choice = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(S.current.importQ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.current.fileHas(f.accounts.length, f.entries.length, span),
              ),
              const SizedBox(height: 14),
              Text(
                S.current.mergeRecommended,
                style: body(14, weight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                preview.isNoop
                    ? S.current.upToDateNothingNew
                    : describeMerge(preview),
                style: body(13, color: C.n800, height: 1.4),
              ),
              const SizedBox(height: 12),
              Text(S.current.replace, style: body(14, weight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(
                synced
                    ? S.current.replaceNeedsSyncOff
                    : S.current.replaceText(
                        s.accounts.length,
                        s.entries.length,
                      ),
                style: body(13, color: C.n800, height: 1.4),
              ),
              const SizedBox(height: 12),
              Text(S.current.canUndo, style: body(12, color: C.n700)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(S.current.cancel),
          ),
          if (!synced)
            TextButton(
              onPressed: () => Navigator.pop(c, 'replace'),
              child: Text(S.current.replace),
            ),
          if (!preview.isNoop)
            FilledButton(
              onPressed: () => Navigator.pop(c, 'merge'),
              child: Text(S.current.merge),
            ),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    final before = s.snapshot();
    final String msg;
    if (choice == 'merge') {
      final r = s.mergeWith(f);
      msg = S.current.merged(describeMerge(r));
    } else {
      s.importFile(f);
      msg = S.current.replacedWith(f.entries.length);
    }
    toast(
      context,
      msg,
      action: SnackBarAction(
        label: S.current.undo,
        onPressed: () => s.importFile(before),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(S.current.data, style: heading(17)),
        const SizedBox(height: 6),
        Text(
          S.current.dataText,
          style: body(12.5, color: C.n700, height: 1.45),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _export(context),
                icon: const Icon(Icons.upload_rounded, size: 18),
                label: Text(S.current.export),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _import(context),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(S.current.import),
              ),
            ),
          ],
        ),
        if (AppScope.of(context).damagedCopies.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            S.current.damagedKept,
            style: body(12.5, color: C.a700, height: 1.45),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => saveDamagedCopy(context),
              child: Text(S.current.saveCopy),
            ),
          ),
        ],
      ],
    ),
  );
}

/// Sync through a folder shared by Syncthing (one file per device).
class _SyncPanel extends StatelessWidget {
  const _SyncPanel();

  Future<void> _connect(BuildContext context) async {
    final sync = SyncScope.read(context);
    final picked = await pickSyncFolder();
    if (picked == null || !context.mounted) return;
    final (uri, name) = picked;
    final folder = folderFor(uri);
    final FolderMerge preview;
    try {
      preview = await sync.preview(folder);
    } catch (e) {
      if (context.mounted) toast(context, S.current.cannotReadFolder(e));
      return;
    }
    if (!context.mounted) return;
    var useFolder = false;
    final demo = demoOnlyHere(
      AppScope.read(context).entries,
      preview.files,
    ).length;
    if (preview.peers.isNotEmpty && (!preview.report.isNoop || demo > 0)) {
      final choice = await showDialog<String>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(S.current.folderHasData(name)),
          content: SingleChildScrollView(
            child: Text(
              [
                S.current.folderChoice(
                  preview.peers.length,
                  describeMerge(preview.report),
                ),
                if (demo > 0) S.current.demoLeftOut(demo),
              ].join('\n\n'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: Text(S.current.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(c, 'folder'),
              child: Text(S.current.useFolderData),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, 'merge'),
              child: Text(S.current.merge),
            ),
          ],
        ),
      );
      if (choice == null || !context.mounted) return;
      useFolder = choice == 'folder';
    }
    final s = AppScope.read(context);
    final before = s.snapshot();
    await sync.connect(uri, name, folder: folder, useFolderData: useFolder);
    if (!context.mounted) return;
    toast(
      context,
      sync.error ?? S.current.syncOn(name),
      action: SnackBarAction(
        label: S.current.undo,
        // Leaves the folder too, or the next pass would merge it all again.
        onPressed: () async {
          await sync.disconnect();
          s.importFile(before);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sync = SyncScope.of(context);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(S.current.sync, style: heading(17))),
              Tag(
                sync.on ? S.current.on : S.current.off,
                tone: sync.on ? TagTone.accent2 : TagTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            S.current.syncText,
            style: body(12.5, color: C.n700, height: 1.45),
          ),
          const SizedBox(height: 12),
          if (!sync.on)
            FilledButton.icon(
              onPressed: () => _connect(context),
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              label: Text(S.current.chooseSyncFolder),
            )
          else ...[
            Text(sync.status, style: body(14, weight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              S.current.thisDevice(sync.folderName ?? 'folder', sync.ownName),
              style: body(12, color: C.n700),
            ),
            if (sync.error != null) ...[
              const SizedBox(height: 6),
              Text(
                sync.error!,
                style: body(12.5, weight: FontWeight.w600, color: C.a700),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: sync.busy
                        ? null
                        : () async {
                            final r = await sync.syncNow();
                            if (context.mounted) {
                              toast(
                                context,
                                sync.error ??
                                    (r == null || r.isNoop
                                        ? S.current.upToDate
                                        : S.current.synced(describeMerge(r))),
                              );
                            }
                          },
                    icon: const Icon(Icons.sync_rounded, size: 18),
                    label: Text(S.current.syncNow),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      await sync.disconnect();
                      if (context.mounted) {
                        toast(context, S.current.syncStopped);
                      }
                    },
                    child: Text(S.current.disconnect),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
