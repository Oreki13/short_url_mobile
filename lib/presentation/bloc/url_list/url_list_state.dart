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
  final bool isCreating;
  final bool isDeleting;
  final String? searchKeyword;

  const UrlListState({
    this.status = UrlListStatus.initial,
    this.urls = const [],
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.totalPages = 1,
    this.pageSize = 5,
    this.errorMessage,
    this.isRefreshing = false,
    this.isCreating = false,
    this.isDeleting = false,
    this.searchKeyword = "",
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
    bool? isCreating,
    bool? isDeleting,
    String? searchKeyword,
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
      isCreating: isCreating ?? this.isCreating,
      isDeleting: isDeleting ?? this.isDeleting,
      searchKeyword: searchKeyword ?? this.searchKeyword,
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
    isCreating,
    isDeleting,
    searchKeyword,
  ];
}

final class UrlListInitial extends UrlListState {}
