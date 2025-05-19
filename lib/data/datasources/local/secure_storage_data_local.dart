import 'package:short_url_mobile/core/errors/exceptions.dart';
import 'package:short_url_mobile/core/helpers/logger_helper.dart';
import 'package:short_url_mobile/core/helpers/secure_storage_helper.dart';

abstract class SecureStorageDataLocal {
  /// Gets the cached auth token.
  ///
  /// Throws [CacheException] if no cached data is present.
  Future<String?> getAuthToken();

  /// Cache the auth [token].
  ///
  /// Returns true if successful.
  Future<bool> cacheAuthToken(String token);

  /// Clear the cached auth token.
  ///
  /// Returns true if successful.
  Future<bool> clearAuthToken();

  /// Check if auth token exists
  ///
  /// Returns true if logged in
  Future<bool> hasAuthToken();

  /// Get refresh token from secure storage
  Future<String?> getRefreshToken();

  /// Cache refresh token to secure storage
  Future<void> cacheRefreshToken(String token);

  /// Clear refresh token from secure storage
  Future<void> clearRefreshToken();

  /// Check if refresh token exists in secure storage
  Future<bool> hasRefreshToken();
}

/// Implementation of SecureStorageDataLocal using Flutter Secure Storage
class SecureStorageDataLocalImpl implements SecureStorageDataLocal {
  final SecureStorageHelper secureStorage;
  final LoggerUtil logger;

  // Storage keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';

  SecureStorageDataLocalImpl({
    required this.secureStorage,
    required this.logger,
  });

  @override
  Future<String?> getAuthToken() async {
    try {
      logger.info('SecureStorage: Retrieving auth token');
      final token = await secureStorage.read(key: authTokenKey);
      return token;
    } catch (e) {
      logger.error('SecureStorage Error: Failed to get auth token', e);
      throw CacheException(message: 'Failed to get auth token');
    }
  }

  @override
  Future<bool> cacheAuthToken(String token) async {
    try {
      logger.info('SecureStorage: Storing auth token');
      await secureStorage.write(key: authTokenKey, value: token);
      return true;
    } catch (e) {
      logger.error('SecureStorage Error: Failed to cache auth token', e);
      throw CacheException(message: 'Failed to cache auth token');
    }
  }

  @override
  Future<bool> clearAuthToken() async {
    try {
      logger.info('SecureStorage: Clearing auth token');
      await secureStorage.delete(key: authTokenKey);

      // Also clear refresh token if exists
      if (await secureStorage.containsKey(key: refreshTokenKey)) {
        await secureStorage.delete(key: refreshTokenKey);
      }

      return true;
    } catch (e) {
      logger.error('SecureStorage Error: Failed to clear auth token', e);
      throw CacheException(message: 'Failed to clear auth token');
    }
  }

  @override
  Future<bool> hasAuthToken() async {
    try {
      logger.info('SecureStorage: Checking if auth token exists');
      final token = await secureStorage.read(key: authTokenKey);
      return token != null && token.isNotEmpty;
    } catch (e) {
      logger.error('SecureStorage Error: Failed to check auth token', e);
      throw CacheException(message: 'Failed to check auth token');
    }
  }

  // Additional methods for other secure data
  @override
  Future<bool> cacheRefreshToken(String refreshToken) async {
    try {
      logger.info('SecureStorage: Storing refresh token');
      await secureStorage.write(key: refreshTokenKey, value: refreshToken);
      return true;
    } catch (e) {
      logger.error('SecureStorage Error: Failed to cache refresh token', e);
      throw CacheException(message: 'Failed to cache refresh token');
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    try {
      logger.info('SecureStorage: Retrieving refresh token');
      return await secureStorage.read(key: refreshTokenKey);
    } catch (e) {
      logger.error('SecureStorage Error: Failed to get refresh token', e);
      throw CacheException(message: 'Failed to get refresh token');
    }
  }

  @override
  Future<void> clearRefreshToken() async {
    try {
      logger.info('SecureStorage: Clearing refresh token');
      await secureStorage.delete(key: refreshTokenKey);
    } catch (e) {
      logger.error('SecureStorage Error: Failed to clear refresh token', e);
      throw CacheException(message: 'Failed to clear refresh token');
    }
  }

  @override
  Future<bool> hasRefreshToken() async {
    try {
      logger.info('SecureStorage: Checking if refresh token exists');
      final token = await secureStorage.read(key: refreshTokenKey);
      return token != null && token.isNotEmpty;
    } catch (e) {
      logger.error('SecureStorage Error: Failed to check refresh token', e);
      throw CacheException(message: 'Failed to check refresh token');
    }
  }
}
