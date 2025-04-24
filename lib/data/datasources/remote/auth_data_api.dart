import 'package:dio/dio.dart';
import 'package:short_url_mobile/core/errors/exceptions.dart';
import 'package:short_url_mobile/core/services/dio_service.dart';
import 'package:short_url_mobile/core/helpers/logger_helper.dart';
import 'package:short_url_mobile/data/models/login_model.dart';
import 'package:short_url_mobile/domain/entities/login_entity.dart';

abstract class AuthDataApi {
  /// Login user with [username] and [password]
  ///
  /// Returns LoginEntity if successful
  Future<LoginEntity> login({
    required String username,
    required String password,
  });

  /// Logout user
  ///
  /// Returns true if successful
  Future<bool> logout();
}

class AuthDataApiImpl implements AuthDataApi {
  final DioService dioService;
  final LoggerUtil logger;

  AuthDataApiImpl({required this.dioService, required this.logger});

  @override
  Future<LoginEntity> login({
    required String username,
    required String password,
  }) async {
    try {
      logger.info('API Request: Login attempt for user: $username');

      final response = await dioService.dio.post(
        '/auth/login',
        data: {'email': username, 'password': password},
      );

      if (response.statusCode != 200) {
        logger.error(
          'API Error: Login failed with status ${response.statusCode}',
        );
        throw ServerException(
          message: 'Failed to login',
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        logger.error('API Error: Login response data is null');
        throw ServerException(message: 'Empty response from server');
      }

      // Parse response data to LoginModel
      final loginModel = LoginModel.fromJson(response.data);

      // Validate login success
      if (!loginModel.isSuccess) {
        logger.error(
          'API Error: Login unsuccessful with code ${loginModel.code}',
        );
        throw AuthException(
          message:
              loginModel.message ??
              'Login failed with code: ${loginModel.code}',
        );
      }

      // Validate access token
      if (loginModel.accessToken.isEmpty) {
        logger.error('API Error: Empty access token received');
        throw ServerException(
          message: 'Invalid access token received from server',
        );
      }

      // Validate refresh token
      if (loginModel.refreshToken.isEmpty) {
        logger.error('API Error: Empty refresh token received');
        throw ServerException(
          message: 'Invalid refresh token received from server',
        );
      }

      logger.info('API Success: Login successful for user: $username');

      // Return the login entity
      return loginModel;
    } on DioException catch (e) {
      logger.error('API Error: DioException during login', e);

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(
          message: 'Connection timeout. Please check your internet connection.',
        );
      }

      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;

      if (statusCode == 401) {
        throw AuthException(message: 'Invalid username or password');
      } else if (statusCode == 403) {
        throw AuthException(message: 'Account is locked or inactive');
      } else if (statusCode != null && statusCode >= 500) {
        throw ServerException(
          message: 'Server error. Please try again later.',
          statusCode: statusCode,
        );
      }

      throw ServerException(
        message: responseData?['message'] ?? 'Failed to login',
        statusCode: statusCode,
      );
    } catch (e) {
      logger.error('API Error: Unexpected error during login', e);
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<bool> logout() async {
    try {
      // Optional: Call logout API endpoint if you have one
      // await dioService.dio.post('/auth/logout');

      // Since most mobile apps don't need to call an API for logout,
      // we'll just return true here
      return true;
    } catch (e) {
      logger.error('API Error: Error during logout', e);
      throw ServerException(message: 'Failed to logout: ${e.toString()}');
    }
  }
}
