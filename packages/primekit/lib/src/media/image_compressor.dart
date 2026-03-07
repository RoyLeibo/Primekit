// Conditional export router for [ImageCompressor].
//
// - On Web (`dart.library.html`): uses the HTML Canvas API for in-browser
//   compression via `package:web`.
// - On platforms with `dart:io` (Android, iOS, macOS, Windows, Linux):
//   uses the pure-Dart `image` package for decoding, resizing, and encoding
//   — full six-platform support with no native channel dependencies.
// - Stub: unreachable in practice; returns the original [MediaFile] unchanged.
//
// The platform-agnostic [CompressFormat] enum is re-exported by every branch.
export 'image_compressor_stub.dart'
    if (dart.library.html) 'image_compressor_web.dart'
    if (dart.library.io) 'image_compressor_io.dart';
