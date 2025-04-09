import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:short_url_mobile/core/errors/failures.dart';
import 'package:short_url_mobile/domain/entities/url_lisr_response_entity.dart';
import 'package:short_url_mobile/domain/repositories/url_repository.dart';

class GetUrlList {
  final UrlRepository repository;

  GetUrlList(this.repository);

  Future<Either<Failure, UrlListResponseEntity>> call(Params params) async {
    return await repository.getUrlList(page: params.page, limit: params.limit);
  }
}

class Params extends Equatable {
  final int page;
  final int limit;

  const Params({required this.page, required this.limit});

  @override
  List<Object?> get props => [page, limit];
}
