import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:short_url_mobile/core/helpers/logger_helper.dart';

class LoggingInterceptor extends Interceptor {
  final LoggerUtil logger;

  LoggingInterceptor({required this.logger});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      logger.info('REQUEST[${options.method}] => PATH: ${options.path}');

      // Securely log headers (hiding sensitive data)
      final headers = Map<String, dynamic>.from(options.headers);
      if (headers.containsKey('Authorization')) {
        headers['Authorization'] = 'Bearer [REDACTED]';
      }
      logger.info('REQUEST HEADERS: $headers');

      // Securely log request body (hiding passwords)
      if (options.data is Map) {
        final logData = Map<String, dynamic>.from(options.data);
        if (logData.containsKey('password')) {
          logData['password'] = '***********';
        }
        if (logData.containsKey('refresh_token')) {
          logData['refresh_token'] = '[REDACTED]';
        }
        logger.info('REQUEST DATA: $logData');
      } else {
        logger.info('REQUEST DATA: ${options.data}');
      }
    }
    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      logger.info(
        'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
      );

      // Securely log response data (hiding sensitive information)
      var responseData = response.data;
      if (responseData is Map && responseData.containsKey('data')) {
        final dataCopy = Map<String, dynamic>.from(responseData);
        final data = dataCopy['data'];

        if (data is Map && data.containsKey('access_token')) {
          dataCopy['data'] = Map<String, dynamic>.from(data);
          dataCopy['data']['access_token'] = '[REDACTED]';

          if (dataCopy['data'].containsKey('refresh_token')) {
            dataCopy['data']['refresh_token'] = '[REDACTED]';
          }

          logger.info('RESPONSE DATA: $dataCopy');
        } else {
          logger.info('RESPONSE DATA: ${response.data}');
        }
      } else {
        logger.info('RESPONSE DATA: ${response.data}');
      }
    }
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      logger.error(
        'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}',
      );
      logger.error('ERROR MESSAGE: ${err.message}');

      if (err.response?.data != null) {
        logger.error('ERROR DATA: ${err.response?.data}');
      }
    }
    return super.onError(err, handler);
  }
}
