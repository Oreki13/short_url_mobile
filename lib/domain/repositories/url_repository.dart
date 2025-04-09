import 'package:dartz/dartz.dart';
import 'package:short_url_mobile/core/errors/exceptions.dart';
import 'package:short_url_mobile/core/errors/failures.dart';
import 'package:short_url_mobile/core/helpers/logger_helper.dart';
import 'package:short_url_mobile/data/datasources/remote/short_data_api.dart';
import 'package:short_url_mobile/domain/entities/url_lisr_response_entity.dart';

abstract class UrlRepository {
  /// Get list of URLs with pagination
  ///
  /// Returns Either a Failure or [UrlListResponseEntity]
  Future<Either<Failure, UrlListResponseEntity>> getUrlList({
    required int page,
    required int limit,
  });
}

class UrlRepositoryImpl implements UrlRepository {
  final UrlDataApi remoteDataSource;
  final LoggerUtil logger;

  UrlRepositoryImpl({required this.remoteDataSource, required this.logger});

  @override
  Future<Either<Failure, UrlListResponseEntity>> getUrlList({
    required int page,
    required int limit,
  }) async {
    try {
      logger.info('Repository: Getting URL list (page: $page, limit: $limit)');

      final result = await remoteDataSource.getUrlList(
        page: page,
        limit: limit,
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
}
