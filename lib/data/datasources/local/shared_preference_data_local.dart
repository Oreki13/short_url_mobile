import 'package:shared_preferences/shared_preferences.dart';
import 'package:short_url_mobile/core/errors/exceptions.dart';
import 'package:short_url_mobile/core/helpers/logger_helper.dart';

abstract class SharedPreferenceDataLocal {
  /// Gets the cached user ID.
  ///
  /// Throws [CacheException] if no cached data is present.
  Future<String?> getUserId();

  /// Cache the user ID.
  ///
  /// Returns true if successful.
  Future<bool> cacheUserId(String userId);

  /// Clear the cached user data.
  ///
  /// Returns true if successful.
  Future<bool> clearUserData();

  /// Check if user data exists
  ///
  /// Returns true if exists
  Future<bool> hasUserData();

  /// Set remember me value
  ///
  /// Returns true if successful
  Future<bool> setRememberMe(bool value);

  /// Get remember me value
  ///
  /// Returns true if successful
  Future<bool> getRememberMe();
}

class SharedPreferenceDataLocalImpl implements SharedPreferenceDataLocal {
  final SharedPreferences sharedPreferences;
  final LoggerUtil logger;

  static const String userIdKey = 'user_id';
  static const String rememberMeKey = 'remember_me';
  static const String userSettingsKeyPrefix = 'user_setting_';

  SharedPreferenceDataLocalImpl({
    required this.sharedPreferences,
    required this.logger,
  });

  @override
  Future<String?> getUserId() async {
    try {
      logger.info('SharedPreferences: Retrieving user ID');
      final userId = sharedPreferences.getString(userIdKey);
      return userId;
    } catch (e) {
      logger.error('Cache Error: Failed to get user ID', e);
      throw CacheException(message: 'Failed to get user ID');
    }
  }

  @override
  Future<bool> cacheUserId(String userId) async {
    try {
      logger.info('SharedPreferences: Storing user ID');
      final result = await sharedPreferences.setString(userIdKey, userId);
      return result;
    } catch (e) {
      logger.error('Cache Error: Failed to cache user ID', e);
      throw CacheException(message: 'Failed to cache user ID');
    }
  }

  @override
  Future<bool> clearUserData() async {
    try {
      logger.info('SharedPreferences: Clearing user data');

      // Get all keys to remove user-related settings
      final allKeys = sharedPreferences.getKeys();
      final userRelatedKeys =
          allKeys
              .where(
                (key) =>
                    key == userIdKey ||
                    key == rememberMeKey ||
                    key.startsWith(userSettingsKeyPrefix),
              )
              .toList();

      // Remove each key
      for (final key in userRelatedKeys) {
        await sharedPreferences.remove(key);
      }

      return true;
    } catch (e) {
      logger.error('Cache Error: Failed to clear user data', e);
      throw CacheException(message: 'Failed to clear user data');
    }
  }

  @override
  Future<bool> hasUserData() async {
    try {
      final userId = sharedPreferences.getString(userIdKey);
      return userId != null && userId.isNotEmpty;
    } catch (e) {
      logger.error('Cache Error: Failed to check user data', e);
      throw CacheException(message: 'Failed to check user data');
    }
  }

  @override
  // Additional methods for user preferences
  Future<bool> setRememberMe(bool value) async {
    try {
      logger.info('SharedPreferences: Setting remember me to $value');
      return await sharedPreferences.setBool(rememberMeKey, value);
    } catch (e) {
      logger.error('Cache Error: Failed to set remember me', e);
      throw CacheException(message: 'Failed to set remember me');
    }
  }

  @override
  Future<bool> getRememberMe() async {
    try {
      return sharedPreferences.getBool(rememberMeKey) ?? false;
    } catch (e) {
      logger.error('Cache Error: Failed to get remember me', e);
      throw CacheException(message: 'Failed to get remember me');
    }
  }

  // Generic method for user settings
  Future<bool> setUserSetting(String key, dynamic value) async {
    try {
      final prefKey = '$userSettingsKeyPrefix$key';
      if (value is String) {
        return await sharedPreferences.setString(prefKey, value);
      } else if (value is int) {
        return await sharedPreferences.setInt(prefKey, value);
      } else if (value is bool) {
        return await sharedPreferences.setBool(prefKey, value);
      } else if (value is double) {
        return await sharedPreferences.setDouble(prefKey, value);
      } else {
        throw CacheException(message: 'Unsupported setting type');
      }
    } catch (e) {
      logger.error('Cache Error: Failed to set user setting', e);
      throw CacheException(message: 'Failed to set user setting');
    }
  }
}
