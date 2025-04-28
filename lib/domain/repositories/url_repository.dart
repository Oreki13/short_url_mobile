import 'package:dartz/dartz.dart';
import 'package:short_url_mobile/core/errors/exceptions.dart';
import 'package:short_url_mobile/core/errors/failures.dart';
import 'package:short_url_mobile/core/helpers/logger_helper.dart';
import 'package:short_url_mobile/data/datasources/remote/short_data_api.dart';
import 'package:short_url_mobile/domain/entities/url_entity.dart';
import 'package:short_url_mobile/domain/entities/url_lisr_response_entity.dart';

abstract class UrlRepository {
  /// Get list of URLs with pagination
  ///
  /// Returns a [UrlListData] containing the list of URLs and pagination info
  Future<Either<Failure, UrlListResponseEntity>> getUrlList({
    required int page,
    required int limit,
    String? keyword,
  });

  /// Create a new short URL
  ///
  /// Returns the created [UrlEntity] if successful
  Future<Either<Failure, UrlEntity>> createUrl({
    required String title,
    required String destination,
    required String path,
  });

  /// Delete a URL by its ID
  ///
  /// Returns true if deletion was successful, false otherwise
  Future<Either<Failure, bool>> deleteUrl(String id);
}

class UrlRepositoryImpl implements UrlRepository {
  final UrlDataApi remoteDataSource;
  final LoggerUtil logger;

  UrlRepositoryImpl({required this.remoteDataSource, required this.logger});

  @override
  Future<Either<Failure, UrlListResponseEntity>> getUrlList({
    required int page,
    required int limit,
    String? keyword,
  }) async {
    try {
      logger.info(
        'Repository: Getting URL list (page: $page, limit: $limit${keyword != null ? ", keyword: $keyword" : ""})',
      );

      final result = await remoteDataSource.getUrlList(
        page: page,
        limit: limit,
        keyword: keyword,
      );

      logger.info('Repository: URL list fetched successfully');
      return Right(result);
    } on AuthException catch (e) {
      logger.warning('Repository: Auth exception while getting URL list', e);
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      logger.error('Repository: Server exception while getting URL list', e);
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      logger.error('Repository: Network exception while getting URL list', e);
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      logger.error('Repository: Unexpected error while getting URL list', e);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, UrlEntity>> createUrl({
    required String title,
    required String destination,
    required String path,
  }) async {
    try {
      logger.info('Repository: Creating new URL (title: $title, path: $path)');

      final result = await remoteDataSource.createUrl(
        title: title,
        destination: destination,
        path: path,
      );

      logger.info('Repository: URL created successfully');
      return Right(result);
    } on AuthException catch (e) {
      logger.warning('Repository: Auth exception while creating URL', e);
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      logger.error('Repository: Server exception while creating URL', e);
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      logger.error('Repository: Network exception while creating URL', e);
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      logger.error('Repository: Unexpected error while creating URL', e);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteUrl(String id) async {
    try {
      logger.info('Repository: Deleting URL with ID: $id');

      final result = await remoteDataSource.deleteUrl(id);

      logger.info('Repository: URL deleted successfully');
      return Right(result);
    } on AuthException catch (e) {
      logger.warning('Repository: Auth exception while deleting URL', e);
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      logger.error('Repository: Server exception while deleting URL', e);
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      logger.error('Repository: Network exception while deleting URL', e);
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      logger.error('Repository: Unexpected error while deleting URL', e);
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
