import 'package:dio/dio.dart';
import 'package:short_url_mobile/core/errors/exceptions.dart';
import 'package:short_url_mobile/core/helpers/logger_helper.dart';
import 'package:short_url_mobile/core/services/dio_service.dart';
import 'package:short_url_mobile/data/models/url_list_response_model.dart';
import 'package:short_url_mobile/data/wrapper/api_response.dart';

abstract class UrlDataApi {
  /// Get list of URLs with pagination
  ///
  /// Returns a [UrlListResponseModel] containing the list of URLs and pagination info
  Future<UrlListResponseModel> getUrlList({
    required int page,
    required int limit,
  });
}

class UrlDataApiImpl implements UrlDataApi {
  final DioService dioService;
  final LoggerUtil logger;

  UrlDataApiImpl({required this.dioService, required this.logger});

  @override
  Future<UrlListResponseModel> getUrlList({
    required int page,
    required int limit,
  }) async {
    try {
      logger.info('API Request: Getting URL list (page: $page, limit: $limit)');

      final response = await dioService.dio.get(
        '/short/',
        queryParameters: {'page': page, 'limit': limit},
      );

      if (response.statusCode != 200) {
        logger.error(
          'API Error: Failed to get URL list with status ${response.statusCode}',
        );
        throw ServerException(
          message: 'Failed to get URL list',
          statusCode: response.statusCode,
        );
      }

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => UrlListResponseModel.fromJson(data),
      );

      if (!apiResponse.isSuccess) {
        logger.error(
          'API Error: Failed to get URL list with code ${apiResponse.code}',
        );
        throw ServerException(
          message: apiResponse.message ?? 'Failed to get URL list',
        );
      }

      logger.info('API Success: URL list fetched successfully');
      return apiResponse.data;
    } on DioException catch (e) {
      logger.error('API Error: DioException while getting URL list', e);

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
        throw AuthException(message: 'Unauthorized. Please login again.');
      } else if (statusCode != null && statusCode >= 500) {
        throw ServerException(
          message: 'Server error. Please try again later.',
          statusCode: statusCode,
        );
      }

      throw ServerException(
        message: responseData?['message'] ?? 'Failed to get URL list',
        statusCode: statusCode,
      );
    } catch (e) {
      logger.error('API Error: Unexpected error while getting URL list', e);
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }
}
