import 'package:dio/dio.dart';
import 'package:short_url_mobile/core/errors/exceptions.dart';
import 'package:short_url_mobile/core/network/http_client_service.dart';
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
  final HttpClientService dioService;
  final LoggerUtil logger;

  AuthDataApiImpl({required this.dioService, required this.logger});

  @override
  Future<LoginEntity> login({
    required String username,
    required String password,
  }) async {
    try {
      logger.info('API Request: Login attempt for user: $username');

      final response = await dioService.post(
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
      logger.info('API Request: Logout attempt');

      final response = await dioService.post('/auth/logout');

      if (response.statusCode != 200) {
        logger.error(
          'API Error: Logout failed with status ${response.statusCode}',
        );
        throw ServerException(
          message: 'Failed to logout',
          statusCode: response.statusCode,
        );
      }

      if (response.data == null) {
        logger.error('API Error: Logout response data is null');
        throw ServerException(message: 'Empty response from server');
      }

      // Validate response
      final responseData = response.data;
      if (responseData['status'] != 'OK' ||
          responseData['code'] != 'LOGOUT_SUCCESS') {
        logger.error('API Error: Unexpected logout response: $responseData');
        throw ServerException(
          message: responseData['message'] ?? 'Unexpected logout response',
        );
      }

      logger.info('API Success: Logged out successfully');
      return true;
    } on DioException catch (e) {
      logger.error('API Error: DioException during logout', e);

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(
          message: 'Connection timeout. Please check your internet connection.',
        );
      }

      final statusCode = e.response?.statusCode;
      final responseData = e.response?.data;

      throw ServerException(
        message: responseData?['message'] ?? 'Failed to logout',
        statusCode: statusCode,
      );
    } catch (e) {
      logger.error('API Error: Error during logout', e);
      throw ServerException(message: 'Failed to logout: ${e.toString()}');
    }
  }
}
