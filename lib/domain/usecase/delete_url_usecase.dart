import 'package:dartz/dartz.dart';
import 'package:short_url_mobile/core/errors/failures.dart';
import 'package:short_url_mobile/domain/repositories/url_repository.dart';

class DeleteUrlUseCase {
  final UrlRepository repository;

  DeleteUrlUseCase(this.repository);

  /// Execute delete URL operation with given ID
  ///
  /// Returns Either a Failure or bool for success
  Future<Either<Failure, bool>> call(String id) async {
    return await repository.deleteUrl(id);
  }
}
