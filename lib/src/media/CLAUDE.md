# media — Image & File Handling

**Purpose:** Image picking, compression, cropping, and upload management with progress tracking.

**Key exports:**
- `MediaPicker` — wraps `image_picker`; pick from camera or gallery
- `ImageCompressor` — compress with quality/format control
- `ImageCropperService` — crop UI (uses `croppy`)
- `MediaUploader` — abstract upload interface
- `AvatarUploader` — specialized uploader for profile images
- `UploadTask` — resumable upload with progress/cancellation
- `MediaFile`, `CompressFormat`, `UploadStatus` — value types
- `FirebaseStorageUploader` — Firebase Storage impl (import via `firebase.dart`, not exported here)

**Dependencies:** image_picker 1.1.2, image 4.0.0, croppy 1.4.1, firebase_storage (conditional)

**Pattern:** Task-based uploads; observe `UploadTask.progress` stream for UI.

**Maintenance:** Update when new upload backend added or pick/compress API changes.
