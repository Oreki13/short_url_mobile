import 'package:dartz/dartz.dart';
import 'package:short_url_mobile/core/errors/failures.dart';
import 'package:short_url_mobile/domain/entities/url_entity.dart';
import 'package:short_url_mobile/domain/repositories/url_repository.dart';

class CreateUrlUseCase {
  final UrlRepository repository;

  CreateUrlUseCase(this.repository);

  Future<Either<Failure, UrlEntity>> call({
    required String title,
    required String destination,
    required String path,
  }) {
    return repository.createUrl(
      title: title,
      destination: destination,
      path: path,
    );
  }
}
