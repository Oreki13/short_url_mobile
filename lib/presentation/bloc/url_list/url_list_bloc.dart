import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:short_url_mobile/domain/entities/url_entity.dart';
import 'package:short_url_mobile/domain/usecase/get_url_list_usecase.dart';

part 'url_list_event.dart';
part 'url_list_state.dart';

class UrlListBloc extends Bloc<UrlListEvent, UrlListState> {
  final GetUrlList getUrlList;

  UrlListBloc({required this.getUrlList}) : super(UrlListState()) {
    on<FetchUrlList>(_onFetchUrlList);
    on<LoadMoreUrls>(_onLoadMoreUrls);
    on<RefreshUrlList>(_onRefreshUrlList);
  }

  Future<void> _onFetchUrlList(
    FetchUrlList event,
    Emitter<UrlListState> emit,
  ) async {
    emit(state.copyWith(status: UrlListStatus.loading, errorMessage: null));

    final result = await getUrlList(Params(page: 1, limit: state.pageSize));

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: UrlListStatus.failure,
          errorMessage: failure.message ?? 'Failed to fetch URLs',
        ),
      ),
      (urlListResponse) => emit(
        state.copyWith(
          status: UrlListStatus.success,
          urls: urlListResponse.data,
          currentPage: urlListResponse.paging.currentPage,
          totalPages: urlListResponse.paging.totalPage,
          hasReachedMax:
              urlListResponse.paging.currentPage >=
              urlListResponse.paging.totalPage,
        ),
      ),
    );
  }

  Future<void> _onLoadMoreUrls(
    LoadMoreUrls event,
    Emitter<UrlListState> emit,
  ) async {
    // If already at max or currently loading more, do nothing
    if (state.hasReachedMax ||
        state.status == UrlListStatus.loadingMore ||
        state.status == UrlListStatus.loading) {
      return;
    }

    emit(state.copyWith(status: UrlListStatus.loadingMore, errorMessage: null));

    final nextPage = state.currentPage + 1;
    final result = await getUrlList(
      Params(page: nextPage, limit: state.pageSize),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: UrlListStatus.failure,
          errorMessage: failure.message ?? 'Failed to load more URLs',
        ),
      ),
      (urlListResponse) {
        final allUrls = List<UrlEntity>.from(state.urls)
          ..addAll(urlListResponse.data);

        emit(
          state.copyWith(
            status: UrlListStatus.success,
            urls: allUrls,
            currentPage: urlListResponse.paging.currentPage,
            hasReachedMax:
                urlListResponse.paging.currentPage >=
                urlListResponse.paging.totalPage,
          ),
        );
      },
    );
  }

  Future<void> _onRefreshUrlList(
    RefreshUrlList event,
    Emitter<UrlListState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, errorMessage: null));

    final result = await getUrlList(Params(page: 1, limit: state.pageSize));

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: UrlListStatus.failure,
          isRefreshing: false,
          errorMessage: failure.message ?? 'Failed to refresh URLs',
        ),
      ),
      (urlListResponse) => emit(
        state.copyWith(
          status: UrlListStatus.success,
          isRefreshing: false,
          urls: urlListResponse.data,
          currentPage: urlListResponse.paging.currentPage,
          totalPages: urlListResponse.paging.totalPage,
          hasReachedMax:
              urlListResponse.paging.currentPage >=
              urlListResponse.paging.totalPage,
        ),
      ),
    );
  }
}
