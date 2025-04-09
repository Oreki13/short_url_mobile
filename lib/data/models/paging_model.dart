import 'package:short_url_mobile/domain/entities/paging_entity.dart';

class PagingModel extends PagingEntity {
  const PagingModel({
    required super.currentPage,
    required super.totalPage,
    required super.size,
    required super.totalData,
  });

  factory PagingModel.fromJson(Map<String, dynamic> json) {
    return PagingModel(
      currentPage: json['current_page'] as int,
      totalPage: json['total_page'] as int,
      size: json['size'] as int,
      totalData: json['total_data'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'total_page': totalPage,
      'size': size,
      'total_data': totalData,
    };
  }
}
