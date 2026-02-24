import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/media/compress_format.dart';
import 'package:primekit/src/media/image_compressor_stub.dart';
import 'package:primekit/src/media/media_file.dart';

void main() {
  group('ImageCompressor stub', () {
    const source = MediaFile(
      path: '/tmp/test_image.jpg',
      name: 'test_image.jpg',
      sizeBytes: 102400,
      mimeType: 'image/jpeg',
    );

    test('compress() returns original file unchanged', () async {
      final result = await ImageCompressor.compress(source, quality: 80);
      expect(result, equals(source));
    });

    test('compress() with maxWidth/maxHeight returns original unchanged', () async {
      final result = await ImageCompressor.compress(
        source,
        quality: 60,
        maxWidth: 640,
        maxHeight: 480,
      );
      expect(result, equals(source));
    });

    test('compress() with different format returns original unchanged', () async {
      final result = await ImageCompressor.compress(
        source,
        format: CompressFormat.png,
      );
      expect(result, equals(source));
    });

    test('compressToSize() returns original file unchanged', () async {
      final result = await ImageCompressor.compressToSize(
        source,
        targetSizeKb: 50,
      );
      expect(result, equals(source));
    });

    test('getDimensions() returns 0x0', () async {
      final dims = await ImageCompressor.getDimensions('/tmp/any.jpg');
      expect(dims.width, equals(0));
      expect(dims.height, equals(0));
    });
  });
}
