import 'package:short_url_mobile/data/models/paging_model.dart';
import 'package:short_url_mobile/data/models/url_model.dart';
import 'package:short_url_mobile/domain/entities/url_lisr_response_entity.dart';

class UrlListResponseModel extends UrlListResponseEntity {
  const UrlListResponseModel({
    required List<UrlModel> data,
    required PagingModel paging,
  }) : super(data: data, paging: paging);

  factory UrlListResponseModel.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataList = json['data'] as List<dynamic>;
    final List<UrlModel> urls =
        dataList
            .map((item) => UrlModel.fromJson(item as Map<String, dynamic>))
            .toList();

    return UrlListResponseModel(
      data: urls,
      paging: PagingModel.fromJson(json['paging'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': (data as List<UrlModel>).map((e) => e.toJson()).toList(),
      'paging': (paging as PagingModel).toJson(),
    };
  }
}
