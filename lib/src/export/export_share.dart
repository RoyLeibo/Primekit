import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Platform-agnostic file sharing / download helper.
///
/// On mobile and desktop this writes to a temporary file and opens the
/// system share sheet. The web implementation (selected via conditional
/// export) triggers a browser blob download instead.
class PkExportShare {
  PkExportShare._();

  /// Shares or downloads a file from raw bytes.
  ///
  /// [filename] is used as the suggested save name. [mimeType] helps the
  /// system choose the appropriate handler (e.g. `application/pdf`).
  static Future<void> shareFile({
    required Uint8List bytes,
    required String filename,
    String? mimeType,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: filename,
    );
  }

  /// Shares or downloads a text file (e.g. CSV).
  static Future<void> shareText({
    required String content,
    required String filename,
    String mimeType = 'text/csv',
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content, flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: mimeType)],
      subject: filename,
    );
  }

  /// Convenience: shares PDF bytes with the correct MIME type.
  static Future<void> sharePdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    return shareFile(
      bytes: bytes,
      filename: filename,
      mimeType: 'application/pdf',
    );
  }

  /// Convenience: shares CSV text with the correct MIME type.
  static Future<void> shareCsv({
    required String content,
    required String filename,
  }) async {
    return shareText(
      content: content,
      filename: filename,
      mimeType: 'text/csv',
    );
  }
}
