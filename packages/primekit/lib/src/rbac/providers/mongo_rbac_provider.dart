import 'package:dio/dio.dart';

import '../rbac_context.dart';
import '../rbac_policy.dart';
import '../rbac_provider.dart';

/// [RbacProvider] backed by the MongoDB Atlas Data API.
///
/// Role assignments are stored in a `usersCollection` document as an array
/// field named `roles`.
///
/// ```dart
/// final provider = MongoRbacProvider(
///   policy: myPolicy,
///   baseUrl: 'https://data.mongodb-api.com/app/myapp/endpoint/data/v1',
///   apiKey:  'my-api-key',
///   dataSource: 'Cluster0',
///   database: 'mydb',
/// );
/// ```
final class MongoRbacProvider implements RbacProvider {
  /// Creates a [MongoRbacProvider].
  ///
  /// [policy] — the RBAC policy used when constructing [RbacContext].
  /// [baseUrl] — base URL of the Atlas Data API endpoint.
  /// [apiKey] — Atlas API key.
  /// [dataSource] — name of the Atlas cluster / data source.
  /// [database] — name of the MongoDB database.
  /// [usersCollection] — collection that holds user documents.
  /// [dio] — optional [Dio] instance for testing/overriding.
  MongoRbacProvider({
    required RbacPolicy policy,
    required String baseUrl,
    required String apiKey,
    required String dataSource,
    required String database,
    String usersCollection = 'users',
    Dio? dio,
  }) : _policy = policy,
       _baseUrl = baseUrl,
       _dataSource = dataSource,
       _database = database,
       _usersCollection = usersCollection,
       _dio = dio ?? Dio()
         ..options.headers['api-key'] = apiKey
         ..options.headers['Content-Type'] = 'application/json';

  final RbacPolicy _policy;
  final String _baseUrl;
  final String _dataSource;
  final String _database;
  final String _usersCollection;
  final Dio _dio;

  // ---------------------------------------------------------------------------
  // loadContext
  // ---------------------------------------------------------------------------

  @override
  Future<RbacContext> loadContext({required String userId}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_baseUrl/action/findOne',
        data: {
          'dataSource': _dataSource,
          'database': _database,
          'collection': _usersCollection,
          'filter': {'_id': userId},
          'projection': {'roles': 1},
        },
      );

      final doc = response.data?['document'] as Map<String, dynamic>?;
      final raw = doc?['roles'];
      final roleIds = raw is List
          ? raw.whereType<String>().toList()
          : <String>[];

      return RbacContext(userId: userId, roleIds: roleIds, policy: _policy);
    } catch (error) {
      throw Exception(
        'MongoRbacProvider.loadContext failed for user "$userId": $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // assignRole
  // ---------------------------------------------------------------------------

  @override
  Future<void> assignRole({
    required String userId,
    required String roleId,
  }) async {
    try {
      await _dio.post<void>(
        '$_baseUrl/action/updateOne',
        data: {
          'dataSource': _dataSource,
          'database': _database,
          'collection': _usersCollection,
          'filter': {'_id': userId},
          'update': {
            r'$addToSet': {'roles': roleId},
          },
          'upsert': true,
        },
      );
    } catch (error) {
      throw Exception(
        'MongoRbacProvider.assignRole failed '
        '(user: $userId, role: $roleId): $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // removeRole
  // ---------------------------------------------------------------------------

  @override
  Future<void> removeRole({
    required String userId,
    required String roleId,
  }) async {
    try {
      await _dio.post<void>(
        '$_baseUrl/action/updateOne',
        data: {
          'dataSource': _dataSource,
          'database': _database,
          'collection': _usersCollection,
          'filter': {'_id': userId},
          'update': {
            r'$pull': {'roles': roleId},
          },
        },
      );
    } catch (error) {
      throw Exception(
        'MongoRbacProvider.removeRole failed '
        '(user: $userId, role: $roleId): $error',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // usersWithRole
  // ---------------------------------------------------------------------------

  @override
  Future<List<String>> usersWithRole(String roleId) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$_baseUrl/action/find',
        data: {
          'dataSource': _dataSource,
          'database': _database,
          'collection': _usersCollection,
          'filter': {'roles': roleId},
          'projection': {'_id': 1},
        },
      );

      final docs = response.data?['documents'] as List<dynamic>? ?? [];
      return docs
          .whereType<Map<String, dynamic>>()
          .map((d) => d['_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList(growable: false);
    } catch (error) {
      throw Exception(
        'MongoRbacProvider.usersWithRole failed for role "$roleId": $error',
      );
    }
  }
}
