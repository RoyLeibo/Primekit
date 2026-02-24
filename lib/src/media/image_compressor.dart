// Conditional export router for [ImageCompressor].
//
// - On Web (`dart.library.html`): uses the HTML Canvas API for in-browser
//   compression via `package:web`.
// - On platforms with `dart:io` (Android, iOS, macOS): uses
//   `flutter_image_compress` with full native compression support.
// - On all other platforms (Windows, Linux): a no-op stub returns the
//   original [MediaFile] unchanged.
//
// The platform-agnostic [CompressFormat] enum is re-exported by every branch.
export 'image_compressor_stub.dart'
    if (dart.library.html) 'image_compressor_web.dart'
    if (dart.library.io) 'image_compressor_io.dart';
