import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:primekit/src/media/media_file.dart';
import 'package:primekit/src/media/media_uploader.dart';
import 'package:primekit/src/media/upload_task.dart';
import 'package:primekit/src/media/avatar_uploader.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockMediaUploader extends Mock implements MediaUploader {}

class FakeUploadTask extends Fake implements UploadTask {
  FakeUploadTask(this._url);

  final String _url;

  @override
  Future<String> get downloadUrl => Future.value(_url);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late MockMediaUploader mockUploader;
  late AvatarUploader avatarUploader;

  setUpAll(() {
    registerFallbackValue(const MediaFile(path: '/tmp/fallback.jpg'));
  });

  setUp(() {
    mockUploader = MockMediaUploader();
    avatarUploader = AvatarUploader(
      uploader: mockUploader,
      pathPrefix: 'avatars',
    );
  });

  group('AvatarUploader', () {
    // -------------------------------------------------------------------------
    // uploadFile — remotePath format
    // -------------------------------------------------------------------------

    group('uploadFile', () {
      test('builds remotePath as pathPrefix/userId.jpg', () {
        const userId = 'user_abc';
        const file = MediaFile(path: '/tmp/photo.jpg', mimeType: 'image/jpeg');
        const expectedUrl = 'https://cdn.example.com/avatars/user_abc.jpg';

        when(
          () => mockUploader.upload(
            file: any(named: 'file'),
            remotePath: any(named: 'remotePath'),
            metadata: any(named: 'metadata'),
          ),
        ).thenReturn(FakeUploadTask(expectedUrl));

        final task = avatarUploader.uploadFile(file, userId: userId);

        // Verify the correct remote path was used.
        verify(
          () => mockUploader.upload(
            file: any(named: 'file'),
            remotePath: 'avatars/$userId.jpg',
            metadata: any(named: 'metadata'),
          ),
        ).called(1);

        expect(task, isNotNull);
      });

      test('uses custom pathPrefix', () {
        final customUploader = AvatarUploader(
          uploader: mockUploader,
          pathPrefix: 'profile_pics',
        );

        when(
          () => mockUploader.upload(
            file: any(named: 'file'),
            remotePath: any(named: 'remotePath'),
            metadata: any(named: 'metadata'),
          ),
        ).thenReturn(FakeUploadTask('https://example.com/p.jpg'));

        customUploader.uploadFile(
          const MediaFile(path: '/tmp/img.jpg'),
          userId: 'u1',
        );

        verify(
          () => mockUploader.upload(
            file: any(named: 'file'),
            remotePath: 'profile_pics/u1.jpg',
            metadata: any(named: 'metadata'),
          ),
        ).called(1);
      });

      test('remote path includes userId', () {
        const userId = 'user_xyz_123';

        when(
          () => mockUploader.upload(
            file: any(named: 'file'),
            remotePath: any(named: 'remotePath'),
            metadata: any(named: 'metadata'),
          ),
        ).thenReturn(
          FakeUploadTask('https://cdn.example.com/avatars/$userId.jpg'),
        );

        avatarUploader.uploadFile(
          const MediaFile(path: '/tmp/img.png'),
          userId: userId,
        );

        final capturedPath =
            verify(
                  () => mockUploader.upload(
                    file: any(named: 'file'),
                    remotePath: captureAny(named: 'remotePath'),
                    metadata: any(named: 'metadata'),
                  ),
                ).captured.first
                as String;

        expect(capturedPath, contains(userId));
      });
    });
  });
}
