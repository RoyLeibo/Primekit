import 'dart:convert';
import 'dart:typed_data';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web implementation of [PkExportShare].
///
/// Triggers a browser blob download via an invisible anchor element.
class PkExportShare {
  PkExportShare._();

  /// Downloads a file from raw bytes in the browser.
  static Future<void> shareFile({
    required Uint8List bytes,
    required String filename,
    String? mimeType,
  }) async {
    final blob = html.Blob([bytes], mimeType ?? 'application/octet-stream');
    _triggerDownload(blob, filename);
  }

  /// Downloads a text file (e.g. CSV) in the browser.
  static Future<void> shareText({
    required String content,
    required String filename,
    String mimeType = 'text/csv',
  }) async {
    final bytes = utf8.encode(content);
    final blob = html.Blob(
      [Uint8List.fromList(bytes)],
      '$mimeType;charset=utf-8',
    );
    _triggerDownload(blob, filename);
  }

  /// Convenience: downloads PDF bytes in the browser.
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

  /// Convenience: downloads CSV text in the browser.
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

  static void _triggerDownload(html.Blob blob, String filename) {
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
