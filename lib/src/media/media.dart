/// Media — image/video picker, compression, cropping, and upload pipeline.
///
/// Import this barrel to access the full Media module:
/// ```dart
/// import 'package:primekit/src/media/media.dart';
/// ```
library primekit_media;

export 'avatar_uploader.dart' show AvatarUploader;
export 'image_compressor.dart' show ImageCompressor;
export 'image_cropper_service.dart' show ImageCropperService;
export 'media_file.dart' show MediaFile;
export 'media_picker.dart' show MediaPicker;
export 'media_uploader.dart' show MediaUploader;
export 'providers/firebase_storage_uploader.dart'
    show FirebaseStorageUploader;
export 'upload_task.dart'
    show
        UploadCancelledException,
        UploadFailedException,
        UploadStatus,
        UploadTask,
        UploadTaskController;
