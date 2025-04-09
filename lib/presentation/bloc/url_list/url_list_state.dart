part of 'url_list_bloc.dart';

enum UrlListStatus { initial, loading, success, failure, loadingMore }

class UrlListState extends Equatable {
  final UrlListStatus status;
  final List<UrlEntity> urls;
  final bool hasReachedMax;
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final String? errorMessage;
  final bool isRefreshing;

  const UrlListState({
    this.status = UrlListStatus.initial,
    this.urls = const [],
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.totalPages = 1,
    this.pageSize = 5,
    this.errorMessage,
    this.isRefreshing = false,
  });

  UrlListState copyWith({
    UrlListStatus? status,
    List<UrlEntity>? urls,
    bool? hasReachedMax,
    int? currentPage,
    int? totalPages,
    int? pageSize,
    String? errorMessage,
    bool? isRefreshing,
  }) {
    return UrlListState(
      status: status ?? this.status,
      urls: urls ?? this.urls,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      pageSize: pageSize ?? this.pageSize,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
    status,
    urls,
    hasReachedMax,
    currentPage,
    totalPages,
    pageSize,
    errorMessage,
    isRefreshing,
  ];
}

final class UrlListInitial extends UrlListState {}
