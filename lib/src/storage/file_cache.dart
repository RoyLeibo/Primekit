import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../core/exceptions.dart';
import '../core/logger.dart';

/// A local file cache for downloaded remote assets (images, PDFs, documents).
///
/// Files are stored in the application's temporary directory under a
/// `pk_file_cache/` subdirectory. Each entry is keyed by a stable string
/// (URL or explicit [cacheKey]), and an optional TTL controls eviction.
///
/// A lightweight LRU strategy is applied when [evictIfExceedsSize] is called:
/// the least-recently-accessed files are deleted until the total cache size
/// drops below [maxBytes].
///
/// ```dart
/// final cache = FileCache.instance;
///
/// final file = await cache.getOrFetch(
///   'https://example.com/report.pdf',
///   ttl: Duration(hours: 24),
/// );
/// ```
///
/// > Note: `path_provider` must be added to your `pubspec.yaml`:
/// > ```yaml
/// > dependencies:
/// >   path_provider: ^2.1.0
/// > ```
final class FileCache {
  FileCache._internal();

  static final FileCache _instance = FileCache._internal();

  /// The singleton instance.
  static FileCache get instance => _instance;

  static const String _cacheDirName = 'pk_file_cache';
  static const String _metaDirName = 'pk_file_cache_meta';

  // ---------------------------------------------------------------------------
  // Get or fetch
  // ---------------------------------------------------------------------------

  /// Returns a cached [File] for [url], downloading it on a cache miss.
  ///
  /// [ttl] specifies how long the cached file remains valid. When `null` the
  /// file is kept indefinitely. Expired files are re-fetched.
  ///
  /// [cacheKey] overrides the default key derived from [url]'s SHA-256 hash.
  ///
  /// Throws [StorageException] on fetch or I/O failure.
  Future<File> getOrFetch(String url, {Duration? ttl, String? cacheKey}) async {
    final key = cacheKey ?? _keyFromUrl(url);

    // Check whether a valid cached file exists.
    if (await _isValid(key, ttl)) {
      final cached = await _cacheFile(key);
      await _touchAccess(key);
      PrimekitLogger.verbose('File cache hit: "$key"', tag: 'FileCache');
      return cached;
    }

    // Miss or expired: download.
    PrimekitLogger.debug(
      'File cache miss: downloading "$url"',
      tag: 'FileCache',
    );
    return _download(url, key: key, ttl: ttl);
  }

  // ---------------------------------------------------------------------------
  // Existence check
  // ---------------------------------------------------------------------------

  /// Returns `true` if a valid (non-expired) cache entry exists for [cacheKey].
  Future<bool> has(String cacheKey) => _isValid(cacheKey, null);

  // ---------------------------------------------------------------------------
  // Eviction
  // ---------------------------------------------------------------------------

  /// Removes the cached file and its metadata for [cacheKey].
  ///
  /// No-op when the entry does not exist.
  Future<void> evict(String cacheKey) async {
    try {
      await Future.wait([
        _deleteSafely(await _cacheFile(cacheKey)),
        _deleteSafely(await _metaFile(cacheKey)),
      ]);
      PrimekitLogger.debug('Evicted "$cacheKey"', tag: 'FileCache');
    } on Exception catch (e, st) {
      PrimekitLogger.error(
        'Failed to evict "$cacheKey"',
        tag: 'FileCache',
        error: e,
        stackTrace: st,
      );
      throw StorageException(
        message: 'Failed to evict cache entry "$cacheKey"',
        code: 'FILE_CACHE_EVICT_FAILED',
        cause: e,
      );
    }
  }

  /// Removes all cached files and metadata.
  Future<void> evictAll() async {
    try {
      final cacheDir = await _getCacheDir();
      final metaDir = await _getMetaDir();

      await Future.wait([
        if (await cacheDir.exists()) cacheDir.delete(recursive: true),
        if (await metaDir.exists()) metaDir.delete(recursive: true),
      ]);
      PrimekitLogger.debug('Evicted all file cache entries', tag: 'FileCache');
    } on Exception catch (e, st) {
      PrimekitLogger.error(
        'Failed to evict all',
        tag: 'FileCache',
        error: e,
        stackTrace: st,
      );
      throw StorageException(
        message: 'Failed to evict all cached files',
        code: 'FILE_CACHE_EVICT_ALL_FAILED',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Size
  // ---------------------------------------------------------------------------

  /// Returns the total size in bytes of all cached files.
  Future<int> get sizeInBytes async {
    try {
      final cacheDir = await _getCacheDir();
      if (!await cacheDir.exists()) return 0;
      var total = 0;
      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          total += await entity.length();
        }
      }
      return total;
    } on Exception catch (e, st) {
      PrimekitLogger.error(
        'Failed to compute cache size',
        tag: 'FileCache',
        error: e,
        stackTrace: st,
      );
      throw StorageException(
        message: 'Failed to compute file cache size',
        code: 'FILE_CACHE_SIZE_FAILED',
        cause: e,
      );
    }
  }

  /// Evicts the least-recently-accessed files until the total cache size is
  /// below [maxBytes].
  ///
  /// Uses access time recorded in each entry's metadata file for LRU ordering.
  Future<void> evictIfExceedsSize(int maxBytes) async {
    assert(maxBytes > 0, 'maxBytes must be positive');
    try {
      var currentSize = await sizeInBytes;
      if (currentSize <= maxBytes) return;

      final cacheDir = await _getCacheDir();
      if (!await cacheDir.exists()) return;

      // Build list of (key, accessedAt, fileSize) sorted by oldest access.
      final entries = <_CacheEntryStat>[];
      await for (final entity in cacheDir.list()) {
        if (entity is! File) continue;
        final key = entity.uri.pathSegments.last;
        final meta = await _loadMeta(key);
        final accessedAt = meta?['accessedAt'] != null
            ? DateTime.tryParse(meta!['accessedAt'] as String)
            : null;
        final size = await entity.length();
        entries.add(
          _CacheEntryStat(
            key: key,
            accessedAt: accessedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
            size: size,
          ),
        );
      }

      entries.sort((a, b) => a.accessedAt.compareTo(b.accessedAt));

      for (final entry in entries) {
        if (currentSize <= maxBytes) break;
        await evict(entry.key);
        currentSize -= entry.size;
        PrimekitLogger.debug(
          'LRU evicted "${entry.key}" (freed ${entry.size} bytes)',
          tag: 'FileCache',
        );
      }
    } on Exception catch (e, st) {
      PrimekitLogger.error(
        'evictIfExceedsSize failed',
        tag: 'FileCache',
        error: e,
        stackTrace: st,
      );
      throw StorageException(
        message: 'Failed to evict cache entries by size limit',
        code: 'FILE_CACHE_SIZE_EVICT_FAILED',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Internal: download
  // ---------------------------------------------------------------------------

  Future<File> _download(
    String url, {
    required String key,
    Duration? ttl,
  }) async {
    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode < 200 || response.statusCode >= 300) {
        httpClient.close();
        throw StorageException(
          message: 'HTTP ${response.statusCode} while fetching $url',
          code: 'FILE_CACHE_FETCH_HTTP_ERROR',
        );
      }

      final file = await _cacheFile(key);
      await file.parent.create(recursive: true);
      final sink = file.openWrite();
      try {
        await response.pipe(sink);
      } finally {
        await sink.flush();
        await sink.close();
        httpClient.close();
      }

      await _saveMeta(key, ttl: ttl);
      PrimekitLogger.debug(
        'Downloaded and cached "$url" as "$key"',
        tag: 'FileCache',
      );
      return file;
    } on StorageException {
      rethrow;
    } on Exception catch (e, st) {
      PrimekitLogger.error(
        'Download failed for "$url"',
        tag: 'FileCache',
        error: e,
        stackTrace: st,
      );
      throw StorageException(
        message: 'Failed to fetch and cache "$url"',
        code: 'FILE_CACHE_FETCH_FAILED',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Internal: validity
  // ---------------------------------------------------------------------------

  Future<bool> _isValid(String key, Duration? ttl) async {
    final file = await _cacheFile(key);
    if (!await file.exists()) return false;

    final meta = await _loadMeta(key);
    if (meta == null) return false;

    final expiresAtRaw = meta['expiresAt'] as String?;
    if (expiresAtRaw == null) return true; // No TTL — never expires.

    final expiresAt = DateTime.tryParse(expiresAtRaw);
    if (expiresAt == null) return false;

    return DateTime.now().toUtc().isBefore(expiresAt);
  }

  // ---------------------------------------------------------------------------
  // Internal: metadata
  // ---------------------------------------------------------------------------

  Future<void> _saveMeta(String key, {Duration? ttl}) async {
    final meta = <String, dynamic>{
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'accessedAt': DateTime.now().toUtc().toIso8601String(),
      if (ttl != null)
        'expiresAt': DateTime.now().toUtc().add(ttl).toIso8601String(),
    };
    final file = await _metaFile(key);
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(meta));
  }

  Future<void> _touchAccess(String key) async {
    try {
      final meta = await _loadMeta(key) ?? {};
      final updated = {
        ...meta,
        'accessedAt': DateTime.now().toUtc().toIso8601String(),
      };
      final file = await _metaFile(key);
      await file.writeAsString(jsonEncode(updated));
    } on Exception {
      // Non-critical; ignore errors in access-time tracking.
    }
  }

  Future<Map<String, dynamic>?> _loadMeta(String key) async {
    try {
      final file = await _metaFile(key);
      if (!await file.exists()) return null;
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on Exception {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Internal: file paths
  // ---------------------------------------------------------------------------

  Future<File> _cacheFile(String key) async {
    final dir = await _getCacheDir();
    return File('${dir.path}/$key');
  }

  Future<File> _metaFile(String key) async {
    final dir = await _getMetaDir();
    return File('${dir.path}/$key.meta');
  }

  Future<Directory> _getCacheDir() async {
    final base = await getTemporaryDirectory();
    return Directory('${base.path}/$_cacheDirName');
  }

  Future<Directory> _getMetaDir() async {
    final base = await getTemporaryDirectory();
    return Directory('${base.path}/$_metaDirName');
  }

  // ---------------------------------------------------------------------------
  // Internal: utilities
  // ---------------------------------------------------------------------------

  /// Derives a stable, filesystem-safe cache key from [url] using its
  /// SHA-256 hash.
  String _keyFromUrl(String url) {
    final bytes = utf8.encode(url);
    return sha256.convert(bytes).toString();
  }

  Future<void> _deleteSafely(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on Exception {
      // Best-effort deletion; ignore errors.
    }
  }
}

// ---------------------------------------------------------------------------
// Internal helper struct
// ---------------------------------------------------------------------------

final class _CacheEntryStat {
  const _CacheEntryStat({
    required this.key,
    required this.accessedAt,
    required this.size,
  });

  final String key;
  final DateTime accessedAt;
  final int size;
}
