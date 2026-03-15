import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

/// Service for capturing widgets as images and sharing them.
///
/// Provides platform-aware file handling (web vs mobile) and native share
/// sheet integration via `share_plus`.
///
/// Usage with a [GlobalKey]:
/// ```dart
/// final key = GlobalKey();
///
/// // Wrap your widget
/// RepaintBoundary(key: key, child: MyCard());
///
/// // Capture and share
/// final service = PkScreenshotShareService();
/// await service.captureAndShare(
///   key: key,
///   fileName: 'my-card.png',
///   shareText: 'Check this out!',
/// );
/// ```
class PkScreenshotShareService {
  /// Pixel ratio for the capture. Higher = better quality but larger file.
  final double pixelRatio;

  const PkScreenshotShareService({this.pixelRatio = 2.0});

  /// Capture the widget identified by [key] as PNG bytes.
  ///
  /// Returns null if the capture fails (e.g. widget not yet laid out).
  Future<Uint8List?> capture({required GlobalKey key}) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  /// Capture and share the widget via the native share sheet.
  ///
  /// Falls back to sharing [shareText] only if image capture fails.
  Future<void> captureAndShare({
    required GlobalKey key,
    String fileName = 'screenshot.png',
    String? shareText,
    String? shareSubject,
  }) async {
    final bytes = await capture(key: key);

    if (bytes != null) {
      await _shareImage(
        bytes: bytes,
        fileName: fileName,
        text: shareText,
        subject: shareSubject,
      );
    } else if (shareText != null) {
      await Share.share(shareText, subject: shareSubject);
    }
  }

  /// Capture and save the widget as an image file.
  ///
  /// On web, triggers a download via share_plus.
  /// On mobile, writes to the temp directory and returns the file path.
  Future<String?> captureAndSave({
    required GlobalKey key,
    String fileName = 'screenshot.png',
  }) async {
    final bytes = await capture(key: key);
    if (bytes == null) return null;

    if (kIsWeb) {
      await Share.shareXFiles([
        XFile.fromData(bytes, mimeType: 'image/png', name: fileName),
      ]);
      return null;
    }

    final dir = await _getTempDirectory();
    if (dir == null) return null;

    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Share raw image bytes via the native share sheet.
  Future<void> shareBytes({
    required Uint8List bytes,
    String fileName = 'screenshot.png',
    String? text,
  }) async {
    await _shareImage(bytes: bytes, fileName: fileName, text: text);
  }

  Future<void> _shareImage({
    required Uint8List bytes,
    required String fileName,
    String? text,
    String? subject,
  }) async {
    if (kIsWeb) {
      await Share.shareXFiles(
        [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
        text: text,
        subject: subject,
      );
    } else {
      final dir = await _getTempDirectory();
      if (dir == null) {
        // Fallback to in-memory sharing
        await Share.shareXFiles(
          [XFile.fromData(bytes, mimeType: 'image/png', name: fileName)],
          text: text,
          subject: subject,
        );
        return;
      }

      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
        subject: subject,
      );
    }
  }

  Future<Directory?> _getTempDirectory() async {
    try {
      // Dynamic import to avoid web compilation errors
      return Directory.systemTemp.createTempSync('pk_screenshot_');
    } catch (_) {
      return null;
    }
  }
}
