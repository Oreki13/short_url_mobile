import 'package:shared_preferences/shared_preferences.dart';
import 'package:short_url_mobile/core/errors/exceptions.dart';
import 'package:short_url_mobile/core/utility/logger_utility.dart';

abstract class AuthLocalDataSource {
  /// Gets the cached auth token.
  ///
  /// Throws [CacheException] if no cached data is present.
  Future<String?> getAuthToken();

  /// Gets the cached user ID.
  ///
  /// Throws [CacheException] if no cached data is present.
  Future<String?> getUserId();

  /// Cache the auth [token] and [userId].
  ///
  /// Returns true if successful.
  Future<bool> cacheAuthData({required String token, required String userId});

  /// Clear the cached auth data.
  ///
  /// Returns true if successful.
  Future<bool> clearAuthData();

  /// Check if user is logged in based on stored token
  ///
  /// Returns true if logged in
  Future<bool> isLoggedIn();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SharedPreferences sharedPreferences;
  final LoggerUtil logger;

  static const String AUTH_TOKEN_KEY = 'auth_token';
  static const String USER_ID_KEY = 'user_id';

  AuthLocalDataSourceImpl({
    required this.sharedPreferences,
    required this.logger,
  });

  @override
  Future<String?> getAuthToken() async {
    try {
      final token = sharedPreferences.getString(AUTH_TOKEN_KEY);
      return token;
    } catch (e) {
      logger.error('Cache Error: Failed to get auth token', e);
      throw CacheException(message: 'Failed to get auth token');
    }
  }

  @override
  Future<String?> getUserId() async {
    try {
      final userId = sharedPreferences.getString(USER_ID_KEY);
      return userId;
    } catch (e) {
      logger.error('Cache Error: Failed to get user ID', e);
      throw CacheException(message: 'Failed to get user ID');
    }
  }

  @override
  Future<bool> cacheAuthData({
    required String token,
    required String userId,
  }) async {
    try {
      logger.info('Cache: Storing auth data');

      final tokenResult = await sharedPreferences.setString(
        AUTH_TOKEN_KEY,
        token,
      );
      final userIdResult = await sharedPreferences.setString(
        USER_ID_KEY,
        userId,
      );

      return tokenResult && userIdResult;
    } catch (e) {
      logger.error('Cache Error: Failed to cache auth data', e);
      throw CacheException(message: 'Failed to cache auth data');
    }
  }

  @override
  Future<bool> clearAuthData() async {
    try {
      logger.info('Cache: Clearing auth data');

      final tokenResult = await sharedPreferences.remove(AUTH_TOKEN_KEY);
      final userIdResult = await sharedPreferences.remove(USER_ID_KEY);

      return tokenResult && userIdResult;
    } catch (e) {
      logger.error('Cache Error: Failed to clear auth data', e);
      throw CacheException(message: 'Failed to clear auth data');
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    try {
      final token = sharedPreferences.getString(AUTH_TOKEN_KEY);
      return token != null && token.isNotEmpty;
    } catch (e) {
      logger.error('Cache Error: Failed to check login status', e);
      throw CacheException(message: 'Failed to check login status');
    }
  }
}
