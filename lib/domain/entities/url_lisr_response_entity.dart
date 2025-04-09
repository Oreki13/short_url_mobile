import 'package:equatable/equatable.dart';
import 'package:short_url_mobile/domain/entities/paging_entity.dart';
import 'package:short_url_mobile/domain/entities/url_entity.dart';

class UrlListResponseEntity extends Equatable {
  final List<UrlEntity> data;
  final PagingEntity paging;

  const UrlListResponseEntity({required this.data, required this.paging});

  @override
  List<Object?> get props => [data, paging];
}
