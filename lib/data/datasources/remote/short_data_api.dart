import 'package:dio/dio.dart';
import 'package:short_url_mobile/core/errors/exceptions.dart';
import 'package:short_url_mobile/core/helpers/logger_helper.dart';
import 'package:short_url_mobile/core/services/dio_service.dart';
import 'package:short_url_mobile/data/models/url_list_response_model.dart';
import 'package:short_url_mobile/data/models/url_model.dart';
import 'package:short_url_mobile/data/wrapper/api_response.dart';

abstract class UrlDataApi {
  /// Get list of URLs with pagination
  ///
  /// Returns a [UrlListResponseModel] containing the list of URLs and pagination info
  Future<UrlListResponseModel> getUrlList({
    required int page,
    required int limit,
    String? keyword,
  });

  /// Create a new short URL
  ///
  /// Returns the created [UrlModel]
  Future<UrlModel> createUrl({
    required String title,
    required String destination,
    required String path,
  });

  /// Delete a URL by its ID
  ///
  /// Returns true if deletion was successful
  Future<bool> deleteUrl(String id);
}

class UrlDataApiImpl implements UrlDataApi {
  final DioService dioService;
  final LoggerUtil logger;

  UrlDataApiImpl({required this.dioService, required this.logger});

  @override
  Future<UrlListResponseModel> getUrlList({
    required int page,
    required int limit,
    String? keyword,
  }) async {
    try {
      logger.info(
        'API Request: Getting URL list (page: $page, limit: $limit${keyword != null ? ", keyword: $keyword" : ""})',
      );

      Map<String, dynamic> queryParams = {'page': page, 'limit': limit};

      // Add keyword to query parameters if provided
      if (keyword != null && keyword.isNotEmpty) {
        queryParams['keyword'] = keyword;
      }

      final response = await dioService.dio.get(
        '/short/',
        queryParameters: queryParams,
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

  @override
  Future<UrlModel> createUrl({
    required String title,
    required String destination,
    required String path,
  }) async {
    try {
      logger.info('API Request: Creating new URL (title: $title, path: $path)');

      final response = await dioService.dio.post(
        '/short/',
        data: {'title': title, 'destination': destination, 'path': path},
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        logger.error(
          'API Error: Failed to create URL with status ${response.statusCode}',
        );
        throw ServerException(
          message: 'Failed to create URL',
          statusCode: response.statusCode,
        );
      }

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => UrlModel.fromCreateResponse(
          data,
        ), // Menggunakan factory method baru
      );

      if (!apiResponse.isSuccess) {
        logger.error(
          'API Error: Failed to create URL with code ${apiResponse.code}',
        );
        throw ServerException(
          message: apiResponse.message ?? 'Failed to create URL',
        );
      }

      logger.info('API Success: URL created successfully');
      return apiResponse.data;
    } on DioException catch (e) {
      logger.error('API Error: DioException while creating URL', e);

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
        message: responseData?['message'] ?? 'Failed to create URL',
        statusCode: statusCode,
      );
    } catch (e) {
      logger.error('API Error: Unexpected error while creating URL', e);
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<bool> deleteUrl(String id) async {
    try {
      logger.info('API Request: Deleting URL with ID: $id');

      final response = await dioService.dio.delete('/short/$id');

      if (response.statusCode != 200) {
        logger.error(
          'API Error: Failed to delete URL with status ${response.statusCode}',
        );
        throw ServerException(
          message: 'Failed to delete URL',
          statusCode: response.statusCode,
        );
      }

      final apiResponse = ApiResponse.fromJson(
        response.data as Map<String, dynamic>,
        (data) => UrlModel.fromCreateResponse(data),
      );

      if (!apiResponse.isSuccess) {
        logger.error(
          'API Error: Failed to delete URL with code ${apiResponse.code}',
        );
        throw ServerException(
          message: apiResponse.message ?? 'Failed to delete URL',
        );
      }

      logger.info('API Success: URL deleted successfully');
      return true;
    } on DioException catch (e) {
      logger.error('API Error: DioException while deleting URL', e);

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
        message: responseData?['message'] ?? 'Failed to delete URL',
        statusCode: statusCode,
      );
    } catch (e) {
      logger.error('API Error: Unexpected error while deleting URL', e);
      throw ServerException(message: 'Unexpected error: ${e.toString()}');
    }
  }
}
