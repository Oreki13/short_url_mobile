import 'package:dartz/dartz.dart';
import 'package:short_url_mobile/core/errors/failures.dart';
import 'package:short_url_mobile/core/helpers/logger_helper.dart';
import 'package:short_url_mobile/domain/entities/url_entity.dart';
import 'package:short_url_mobile/domain/repositories/url_repository.dart';

class UpdateUrlUseCase {
  final UrlRepository repository;
  final LoggerUtil logger;

  UpdateUrlUseCase({required this.repository, required this.logger});

  Future<Either<Failure, UrlEntity>> call({
    required String id,
    required String title,
    required String destination,
    required String path,
  }) async {
    logger.info('UseCase: Updating URL with ID: $id');
    return await repository.updateUrl(
      id: id,
      title: title,
      destination: destination,
      path: path,
    );
  }
}
