// Conditional export router for [ImageCropperService].
//
// - On Web (`dart.library.html`): loads the image via [NetworkImage] (blob URL)
//   and returns a new blob URL for the cropped result.
// - On platforms with `dart:io` (Android, iOS, macOS, Windows, Linux):
//   loads via [FileImage] and writes the cropped result to a temp file.
// - Stub: returns null for all crop requests (unreachable in practice).
//
// All variants use the pure-Flutter [croppy] package, which has no platform
// channel dependencies and therefore supports all six Flutter platforms.
export 'image_cropper_service_stub.dart'
    if (dart.library.html) 'image_cropper_service_web.dart'
    if (dart.library.io) 'image_cropper_service_io.dart';
