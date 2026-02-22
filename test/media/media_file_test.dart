import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/media/media_file.dart';

void main() {
  group('MediaFile', () {
    // -------------------------------------------------------------------------
    // sizeMb
    // -------------------------------------------------------------------------

    group('sizeMb', () {
      test('returns null when sizeBytes is null', () {
        const file = MediaFile(path: '/tmp/photo.jpg');
        expect(file.sizeMb, isNull);
      });

      test('converts 1 048 576 bytes to 1.0 MB', () {
        const file = MediaFile(path: '/tmp/photo.jpg', sizeBytes: 1048576);
        expect(file.sizeMb, closeTo(1.0, 0.0001));
      });

      test('converts 512 KB to 0.5 MB', () {
        const file = MediaFile(path: '/tmp/photo.jpg', sizeBytes: 524288);
        expect(file.sizeMb, closeTo(0.5, 0.0001));
      });

      test('converts 200 KB to ~0.19 MB', () {
        const file = MediaFile(path: '/tmp/photo.jpg', sizeBytes: 204800);
        expect(file.sizeMb, closeTo(0.195, 0.001));
      });
    });

    // -------------------------------------------------------------------------
    // isImage
    // -------------------------------------------------------------------------

    group('isImage', () {
      test('returns true for .jpg extension', () {
        const file = MediaFile(path: '/tmp/photo.jpg');
        expect(file.isImage, isTrue);
      });

      test('returns true for .jpeg extension', () {
        const file = MediaFile(path: '/tmp/photo.jpeg');
        expect(file.isImage, isTrue);
      });

      test('returns true for .png extension', () {
        const file = MediaFile(path: '/tmp/photo.png');
        expect(file.isImage, isTrue);
      });

      test('returns true for .webp extension', () {
        const file = MediaFile(path: '/tmp/photo.webp');
        expect(file.isImage, isTrue);
      });

      test('returns true for .heic extension', () {
        const file = MediaFile(path: '/tmp/photo.heic');
        expect(file.isImage, isTrue);
      });

      test('returns true for image/jpeg MIME type', () {
        const file =
            MediaFile(path: '/tmp/photo.dat', mimeType: 'image/jpeg');
        expect(file.isImage, isTrue);
      });

      test('returns false for .mp4', () {
        const file = MediaFile(path: '/tmp/video.mp4');
        expect(file.isImage, isFalse);
      });

      test('returns false with video MIME type', () {
        const file =
            MediaFile(path: '/tmp/video.dat', mimeType: 'video/mp4');
        expect(file.isImage, isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // isVideo
    // -------------------------------------------------------------------------

    group('isVideo', () {
      test('returns true for .mp4 extension', () {
        const file = MediaFile(path: '/tmp/video.mp4');
        expect(file.isVideo, isTrue);
      });

      test('returns true for .mov extension', () {
        const file = MediaFile(path: '/tmp/video.mov');
        expect(file.isVideo, isTrue);
      });

      test('returns true for video/mp4 MIME type', () {
        const file =
            MediaFile(path: '/tmp/clip.dat', mimeType: 'video/mp4');
        expect(file.isVideo, isTrue);
      });

      test('returns false for .jpg', () {
        const file = MediaFile(path: '/tmp/photo.jpg');
        expect(file.isVideo, isFalse);
      });
    });

    // -------------------------------------------------------------------------
    // extension
    // -------------------------------------------------------------------------

    group('extension', () {
      test('returns jpg for /tmp/photo.jpg', () {
        const file = MediaFile(path: '/tmp/photo.jpg');
        expect(file.extension, 'jpg');
      });

      test('returns png for /tmp/image.PNG (case preserved)', () {
        const file = MediaFile(path: '/tmp/image.PNG');
        expect(file.extension, 'PNG');
      });

      test('returns empty string when no extension', () {
        const file = MediaFile(path: '/tmp/noextension');
        expect(file.extension, '');
      });

      test('returns empty string for trailing dot', () {
        const file = MediaFile(path: '/tmp/trailingdot.');
        expect(file.extension, '');
      });

      test('handles path with multiple dots', () {
        const file = MediaFile(path: '/tmp/my.image.file.jpeg');
        expect(file.extension, 'jpeg');
      });
    });

    // -------------------------------------------------------------------------
    // copyWith
    // -------------------------------------------------------------------------

    group('copyWith', () {
      const original = MediaFile(
        path: '/tmp/photo.jpg',
        name: 'photo.jpg',
        sizeBytes: 1024,
        mimeType: 'image/jpeg',
        width: 800,
        height: 600,
      );

      test('creates a new instance with updated path', () {
        final copy = original.copyWith(path: '/tmp/new.jpg');
        expect(copy.path, '/tmp/new.jpg');
        expect(copy.name, 'photo.jpg');
        expect(copy.sizeBytes, 1024);
      });

      test('allows clearing optional fields with null', () {
        final copy = original.copyWith(name: null);
        expect(copy.name, isNull);
      });

      test('does not mutate the original', () {
        original.copyWith(path: '/tmp/other.jpg');
        expect(original.path, '/tmp/photo.jpg');
      });
    });

    // -------------------------------------------------------------------------
    // equality
    // -------------------------------------------------------------------------

    group('equality', () {
      test('equal when all fields match', () {
        const a = MediaFile(path: '/tmp/photo.jpg', sizeBytes: 1024);
        const b = MediaFile(path: '/tmp/photo.jpg', sizeBytes: 1024);
        expect(a, b);
      });

      test('not equal when paths differ', () {
        const a = MediaFile(path: '/tmp/photo.jpg');
        const b = MediaFile(path: '/tmp/other.jpg');
        expect(a, isNot(b));
      });

      test('hashCode matches for equal objects', () {
        const a = MediaFile(path: '/tmp/photo.jpg', sizeBytes: 512);
        const b = MediaFile(path: '/tmp/photo.jpg', sizeBytes: 512);
        expect(a.hashCode, b.hashCode);
      });
    });
  });
}
