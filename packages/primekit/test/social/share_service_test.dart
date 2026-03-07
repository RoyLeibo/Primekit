import 'package:flutter_test/flutter_test.dart';
import 'package:primekit/src/social/share_service.dart';

void main() {
  group('ShareService.buildShareLink', () {
    // -------------------------------------------------------------------------
    // URI construction
    // -------------------------------------------------------------------------

    test('builds basic URI without query parameters', () {
      final uri = ShareService.buildShareLink(
        scheme: 'https',
        host: 'app.example.com',
        path: '/posts/42',
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'app.example.com');
      expect(uri.path, '/posts/42');
      expect(uri.queryParameters, isEmpty);
    });

    test('includes query parameters when provided', () {
      final uri = ShareService.buildShareLink(
        scheme: 'https',
        host: 'app.example.com',
        path: '/posts/42',
        queryParameters: {'ref': 'share', 'source': 'mobile'},
      );

      expect(uri.queryParameters['ref'], 'share');
      expect(uri.queryParameters['source'], 'mobile');
    });

    test('toString returns correctly formatted URL', () {
      final uri = ShareService.buildShareLink(
        scheme: 'https',
        host: 'app.example.com',
        path: '/posts/42',
      );

      expect(uri.toString(), 'https://app.example.com/posts/42');
    });

    test('toString includes query string', () {
      final uri = ShareService.buildShareLink(
        scheme: 'https',
        host: 'app.example.com',
        path: '/items/7',
        queryParameters: {'id': '7'},
      );

      expect(uri.toString(), contains('id=7'));
    });

    test('supports custom scheme (deep link)', () {
      final uri = ShareService.buildShareLink(
        scheme: 'myapp',
        host: 'content',
        path: '/profile/user_1',
      );

      expect(uri.scheme, 'myapp');
      expect(uri.host, 'content');
    });

    test('empty queryParameters map is treated same as null', () {
      final withEmpty = ShareService.buildShareLink(
        scheme: 'https',
        host: 'example.com',
        path: '/a',
        queryParameters: {},
      );
      final withNull = ShareService.buildShareLink(
        scheme: 'https',
        host: 'example.com',
        path: '/a',
      );

      expect(withEmpty.queryParameters, withNull.queryParameters);
    });

    test('path with nested segments', () {
      final uri = ShareService.buildShareLink(
        scheme: 'https',
        host: 'app.example.com',
        path: '/users/42/posts/7',
      );
      expect(uri.pathSegments, ['users', '42', 'posts', '7']);
    });
  });
}
