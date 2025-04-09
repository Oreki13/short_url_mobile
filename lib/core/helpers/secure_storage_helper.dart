import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Helper class to provide a singleton instance of FlutterSecureStorage with proper configuration
class SecureStorageHelper {
  static SecureStorageHelper? _instance;
  late final FlutterSecureStorage _storage;

  // Configuration Options
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
    // Set additional iOS-specific options as needed
    accountName: 'short_url_app',
  );

  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    resetOnError: true,
    keyCipherAlgorithm:
        KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    sharedPreferencesName: 'short_url_secure_prefs',
  );

  // Private constructor
  SecureStorageHelper._() {
    _storage = const FlutterSecureStorage(
      iOptions: _iosOptions,
      aOptions: _androidOptions,
    );
  }

  // Factory constructor for singleton pattern
  factory SecureStorageHelper() {
    _instance ??= SecureStorageHelper._();
    return _instance!;
  }

  // Access to storage instance
  FlutterSecureStorage get storage => _storage;

  // Helper methods for easy access

  /// Write a value to secure storage
  Future<void> write({required String key, required String value}) async {
    return await _storage.write(key: key, value: value);
  }

  /// Read a value from secure storage
  Future<String?> read({required String key}) async {
    return await _storage.read(key: key);
  }

  /// Delete a value from secure storage
  Future<void> delete({required String key}) async {
    return await _storage.delete(key: key);
  }

  /// Delete all values from secure storage
  Future<void> deleteAll() async {
    return await _storage.deleteAll();
  }

  /// Check if a key exists in secure storage
  Future<bool> containsKey({required String key}) async {
    return await _storage.containsKey(key: key);
  }
}
