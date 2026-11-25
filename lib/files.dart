import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'l10n.dart';

/// "Save as" / "Open" dialogs.
/// Android: the system file picker (see MainActivity.kt).
/// Linux (desktop build, for testing): zenity dialogs + dart:io.
class Files {
  static const _ch = MethodChannel('ledger/files');

  /// Returns true when written, false when the user cancelled.
  static Future<bool> save(String name, String content) async {
    if (_linuxDesktop) {
      final path = await zenity([
        '--file-selection',
        '--save',
        '--confirm-overwrite',
        '--title=${S.current.exportTitle}',
        '--filename=${await downloadsDir()}/$name',
      ]);
      if (path == null) return false;
      await File(path).writeAsString(content);
      return true;
    }
    return await _ch.invokeMethod<bool>('save', {
          'name': name,
          'content': content,
        }) ??
        false;
  }

  /// Returns the file's text, or null when the user cancelled.
  static Future<String?> open() async {
    if (_linuxDesktop) {
      final path = await zenity([
        '--file-selection',
        '--title=${S.current.importTitle}',
        '--file-filter=Ledger JSON | *.json',
        '--file-filter=All files | *',
      ]);
      return path == null ? null : File(path).readAsString();
    }
    return _ch.invokeMethod<String>('open');
  }
}

/// Runs a zenity dialog; returns the chosen path, or null when cancelled.
Future<String?> zenity(List<String> args) async {
  final r = await Process.run('zenity', args);
  final out = (r.stdout as String).trim();
  return r.exitCode == 0 && out.isNotEmpty ? out : null;
}

/// ~/Downloads (localised, e.g. ~/Téléchargements), or ~ as a fallback.
Future<String> downloadsDir() async {
  try {
    final r = await Process.run('xdg-user-dir', ['DOWNLOAD']);
    final d = (r.stdout as String).trim();
    if (r.exitCode == 0 && d.isNotEmpty) return d;
  } catch (_) {}
  return Platform.environment['HOME'] ?? '.';
}

/// Linux desktop build (zenity dialogs, plain folders). Uses the *target*
/// platform, not the host OS: widget tests run on Linux but target Android.
bool get _linuxDesktop => defaultTargetPlatform == TargetPlatform.linux;
