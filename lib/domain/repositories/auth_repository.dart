import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dartz/dartz.dart';
import 'package:short_url_mobile/core/errors/exceptions.dart';
import 'package:short_url_mobile/core/errors/failures.dart';
import 'package:short_url_mobile/core/helpers/logger_helper.dart';
import 'package:short_url_mobile/core/services/dio_service.dart';
import 'package:short_url_mobile/data/datasources/local/secure_storage_data_local.dart';
import 'package:short_url_mobile/data/datasources/local/shared_preference_data_local.dart';
import 'package:short_url_mobile/data/datasources/remote/auth_data_api.dart';
import 'package:short_url_mobile/domain/entities/login_entity.dart';

abstract class AuthRepository {
  /// Login user with [username] and [password]
  ///
  /// Returns Either a Failure or LoginEntity
  Future<Either<Failure, LoginEntity>> login({
    required String username,
    required String password,
    bool rememberMe = false,
  });

  /// Check if user is logged in
  ///
  /// Returns Either a Failure or true/false for logged in status
  Future<Either<Failure, bool>> isLoggedIn();

  /// Logout user and clear cache
  ///
  /// Returns Either a Failure or true for success
  Future<Either<Failure, bool>> logout();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataApi remoteDataSource;
  final SecureStorageDataLocal secureStorage;
  final SharedPreferenceDataLocal sharedPreferences;
  final DioService dioService;
  final LoggerUtil logger;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.secureStorage,
    required this.sharedPreferences,
    required this.dioService,
    required this.logger,
  });

  @override
  Future<Either<Failure, LoginEntity>> login({
    required String username,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      logger.info('Repository: Attempting login for user: $username');

      // Call remote data source to authenticate
      final authData = await remoteDataSource.login(
        username: username,
        password: password,
      );

      final decodeJwt = JWT.decode(authData.accessToken);
      final userId = decodeJwt.payload['id'];

      // Set token for future API requests and store in cookies
      dioService.setAuthToken(authData.accessToken, userId);

      // Always store auth token securely
      await secureStorage.cacheAuthToken(authData.accessToken);
      await sharedPreferences.cacheUserId(userId);

      // Save user ID to SharedPreferences and refresh token if rememberMe is enabled
      if (rememberMe) {
        logger.info('Repository: Saving user ID with rememberMe: $rememberMe');
        await sharedPreferences.setRememberMe(true);
        // Store refresh token for later use when rememberMe is enabled
        await secureStorage.cacheRefreshToken(authData.refreshToken);
        // Store refresh token in cookies
        dioService.setRefreshTokenCookie(authData.refreshToken);
        logger.info(
          'Repository: Refresh token saved for future use in secure storage and cookies',
        );
      } else {
        // Clear any existing refresh token if remember me is disabled
        await secureStorage.clearRefreshToken();
      }

      logger.info('Repository: Login successful for user: $username');
      return Right(authData);
    } on AuthException catch (e) {
      logger.warning('Repository: Auth exception during login', e);
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      logger.error('Repository: Server exception during login', e);
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      logger.error('Repository: Network exception during login', e);
      return Left(NetworkFailure(message: e.message));
    } on CacheException catch (e) {
      logger.error('Repository: Cache exception during login', e);
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      logger.error('Repository: Unexpected error during login', e);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isLoggedIn() async {
    try {
      logger.info('Repository: Checking if user is logged in');

      // Check for token in SecureStorage
      final hasToken = await secureStorage.hasAuthToken();
      final hasUserId = await sharedPreferences.hasUserData();

      // If token exists, check if it's valid
      if (hasToken && hasUserId) {
        // Get token for Dio headers
        final token = await secureStorage.getAuthToken();
        final userId = await sharedPreferences.getUserId();
        if ((token != null && token.isNotEmpty) &&
            (userId != null && userId.isNotEmpty)) {
          // Set token for future API requests
          dioService.setAuthToken(token, userId);
        }
      }

      return Right(hasToken);
    } on CacheException catch (e) {
      logger.error('Repository: Cache exception during isLoggedIn check', e);
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      logger.error('Repository: Unexpected error during isLoggedIn check', e);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      logger.info('Repository: Attempting to logout user');

      // Call API logout endpoint
      final logoutSuccessful = await remoteDataSource.logout();
      if (!logoutSuccessful) {
        logger.warning('Repository: API logout returned false');
        // Continue with local logout even if server logout fails
      } else {
        logger.info('Repository: API logout successful');
      }

      // Clear Dio auth headers
      dioService.clearAuthToken();

      // Clear secure storage (token)
      await secureStorage.clearAuthToken();
      // Clear refresh token regardless of remember me state
      await secureStorage.clearRefreshToken();

      // Clear shared preferences (user data) only if rememberMe is false
      final rememberMe = await sharedPreferences.getRememberMe();
      if (!rememberMe) {
        await sharedPreferences.clearUserData();
        await sharedPreferences.setRememberMe(false);
      }

      logger.info('Repository: User logged out successfully');
      return const Right(true);
    } on ServerException catch (e) {
      logger.error('Repository: Server exception during logout', e);

      // Even if server logout fails, proceed with local logout
      try {
        // Clear Dio auth headers and local storage
        dioService.clearAuthToken();
        await secureStorage.clearAuthToken();
        await secureStorage.clearRefreshToken();

        final rememberMe = await sharedPreferences.getRememberMe();
        if (!rememberMe) {
          await sharedPreferences.clearUserData();
          await sharedPreferences.setRememberMe(false);
        }

        logger.info('Repository: Local logout completed after server error');
        return const Right(true);
      } catch (localError) {
        logger.error(
          'Repository: Local logout failed after server error',
          localError,
        );
        return Left(
          ServerFailure(message: e.message, statusCode: e.statusCode),
        );
      }
    } on NetworkException catch (e) {
      logger.error('Repository: Network exception during logout', e);

      // Proceed with local logout even on network errors
      try {
        dioService.clearAuthToken();
        await secureStorage.clearAuthToken();
        await secureStorage.clearRefreshToken();

        final rememberMe = await sharedPreferences.getRememberMe();
        if (!rememberMe) {
          await sharedPreferences.clearUserData();
          await sharedPreferences.setRememberMe(false);
        }

        logger.info('Repository: Local logout completed after network error');
        return const Right(true);
      } catch (localError) {
        logger.error(
          'Repository: Local logout failed after network error',
          localError,
        );
        return Left(NetworkFailure(message: e.message));
      }
    } on CacheException catch (e) {
      logger.error('Repository: Cache exception during logout', e);
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      logger.error('Repository: Unexpected error during logout', e);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
