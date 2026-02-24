/// Platform-agnostic image compression format identifiers.
///
/// This mirrors `flutter_image_compress`'s `CompressFormat` so that the
/// stub and web implementations can share the same method signatures.
enum CompressFormat {
  /// JPEG compression (lossy, smallest file size for photos).
  jpeg,

  /// PNG compression (lossless, best for transparency).
  png,

  /// WebP compression (both lossy and lossless modes).
  webp,

  /// HEIC/HEIF (Apple high-efficiency, iOS 11+).
  heic,
}
