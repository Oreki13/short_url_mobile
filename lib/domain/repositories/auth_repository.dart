import 'package:dartz/dartz.dart';
import 'package:short_url_mobile/core/errors/exceptions.dart';
import 'package:short_url_mobile/core/errors/failures.dart';
import 'package:short_url_mobile/core/services/dio_service.dart';
import 'package:short_url_mobile/core/utility/logger_utility.dart';
import 'package:short_url_mobile/data/datasources/local/shared_preference_data_local.dart';
import 'package:short_url_mobile/data/datasources/remote/auth_data_api.dart';
import 'package:short_url_mobile/domain/entities/login_entity.dart';

abstract class AuthRepository {
  /// Login user with [username] and [password]
  ///
  /// Returns Either a Failure or true/false for success/failure
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
  final AuthLocalDataSource localDataSource;
  final DioService dioService;
  final LoggerUtil logger;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
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

      // Extract token and user ID

      // Set token for future API requests
      dioService.setAuthToken(authData.token);

      // Save to local storage if rememberMe is enabled
      // if (rememberMe) {
      await localDataSource.cacheAuthData(
        token: authData.token,
        userId: username,
      );
      // }

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
      final isLoggedIn = await localDataSource.isLoggedIn();

      // If logged in, ensure token is set in Dio
      if (isLoggedIn) {
        final token = await localDataSource.getAuthToken();
        if (token != null && token.isNotEmpty) {
          dioService.setAuthToken(token);
        }
      }

      return Right(isLoggedIn);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      logger.info('Repository: Attempting to logout user');

      // // Call API logout (if any)
      // await remoteDataSource.logout();

      // Clear auth token from headers
      dioService.clearAuthToken();

      // Clear local storage
      await localDataSource.clearAuthData();

      logger.info('Repository: User logged out successfully');
      return const Right(true);
    } on ServerException catch (e) {
      logger.error('Repository: Server exception during logout', e);
      return Left(ServerFailure(message: e.message));
    } on CacheException catch (e) {
      logger.error('Repository: Cache exception during logout', e);
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      logger.error('Repository: Unexpected error during logout', e);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
