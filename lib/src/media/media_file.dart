import 'package:flutter/foundation.dart';

/// An immutable value type representing a picked or compressed media file.
///
/// [MediaFile] is passed through the full pipeline — picker → compressor →
/// cropper → uploader — without mutation.
///
/// ```dart
/// final file = MediaFile(path: '/tmp/photo.jpg', mimeType: 'image/jpeg');
/// print(file.isImage);     // true
/// print(file.extension);   // 'jpg'
/// ```
@immutable
final class MediaFile {
  /// Creates a [MediaFile] with the given [path] and optional metadata.
  const MediaFile({
    required this.path,
    this.name,
    this.sizeBytes,
    this.mimeType,
    this.width,
    this.height,
    this.capturedAt,
  });

  /// Absolute file-system path to the media file.
  final String path;

  /// Optional filename (basename without directory).
  final String? name;

  /// File size in bytes, if known.
  final int? sizeBytes;

  /// MIME type string, e.g. `'image/jpeg'` or `'video/mp4'`.
  final String? mimeType;

  /// Pixel width, if known.
  final int? width;

  /// Pixel height, if known.
  final int? height;

  /// When the media was captured, if available.
  final DateTime? capturedAt;

  // ---------------------------------------------------------------------------
  // Derived
  // ---------------------------------------------------------------------------

  /// File size in megabytes, derived from [sizeBytes].
  ///
  /// Returns `null` when [sizeBytes] is unknown.
  double? get sizeMb =>
      sizeBytes == null ? null : sizeBytes! / (1024 * 1024);

  /// Whether this file is an image based on [mimeType] or [extension].
  bool get isImage {
    final ext = extension.toLowerCase();
    const imageExts = {
      'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic', 'heif',
    };
    if (imageExts.contains(ext)) return true;
    final mime = mimeType?.toLowerCase() ?? '';
    return mime.startsWith('image/');
  }

  /// Whether this file is a video based on [mimeType] or [extension].
  bool get isVideo {
    final ext = extension.toLowerCase();
    const videoExts = {'mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v', '3gp'};
    if (videoExts.contains(ext)) return true;
    final mime = mimeType?.toLowerCase() ?? '';
    return mime.startsWith('video/');
  }

  /// File extension (without leading dot) derived from [path].
  ///
  /// Returns an empty string if the path has no extension.
  String get extension {
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1 || lastDot == path.length - 1) return '';
    return path.substring(lastDot + 1);
  }

  // ---------------------------------------------------------------------------
  // copyWith
  // ---------------------------------------------------------------------------

  /// Returns a new [MediaFile] with the given fields replaced.
  ///
  /// Pass `null` explicitly to clear optional fields (uses a sentinel to
  /// distinguish "not provided" from `null`).
  MediaFile copyWith({
    String? path,
    Object? name = _sentinel,
    Object? sizeBytes = _sentinel,
    Object? mimeType = _sentinel,
    Object? width = _sentinel,
    Object? height = _sentinel,
    Object? capturedAt = _sentinel,
  }) =>
      MediaFile(
        path: path ?? this.path,
        name: name == _sentinel ? this.name : name as String?,
        sizeBytes: sizeBytes == _sentinel
            ? this.sizeBytes
            : sizeBytes as int?,
        mimeType: mimeType == _sentinel
            ? this.mimeType
            : mimeType as String?,
        width: width == _sentinel ? this.width : width as int?,
        height: height == _sentinel ? this.height : height as int?,
        capturedAt: capturedAt == _sentinel
            ? this.capturedAt
            : capturedAt as DateTime?,
      );

  // ---------------------------------------------------------------------------
  // Equality / hashCode
  // ---------------------------------------------------------------------------

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaFile &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          name == other.name &&
          sizeBytes == other.sizeBytes &&
          mimeType == other.mimeType &&
          width == other.width &&
          height == other.height &&
          capturedAt == other.capturedAt;

  @override
  int get hashCode => Object.hash(
        path,
        name,
        sizeBytes,
        mimeType,
        width,
        height,
        capturedAt,
      );

  @override
  String toString() =>
      'MediaFile(path: $path, mimeType: $mimeType, '
      'sizeBytes: $sizeBytes)';
}

/// Sentinel value used to distinguish `null` from "not provided" in
/// [MediaFile.copyWith].
const Object _sentinel = Object();
