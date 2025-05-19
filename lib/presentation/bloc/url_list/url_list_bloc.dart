import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:short_url_mobile/domain/entities/url_entity.dart';
import 'package:short_url_mobile/domain/usecase/create_url_usecase.dart';
import 'package:short_url_mobile/domain/usecase/delete_url_usecase.dart';
import 'package:short_url_mobile/domain/usecase/get_url_list_usecase.dart';
import 'package:short_url_mobile/domain/usecase/update_url_usecase.dart';

part 'url_list_event.dart';
part 'url_list_state.dart';

class UrlListBloc extends Bloc<UrlListEvent, UrlListState> {
  final GetUrlListUseCase getUrlList;
  final CreateUrlUseCase createUrl;
  final DeleteUrlUseCase deleteUrl;
  final UpdateUrlUseCase updateUrl;

  UrlListBloc({
    required this.getUrlList,
    required this.createUrl,
    required this.deleteUrl,
    required this.updateUrl,
  }) : super(const UrlListState()) {
    on<FetchUrlList>(_onFetchUrlList);
    on<LoadMoreUrls>(_onLoadMoreUrls);
    on<RefreshUrlList>(_onRefreshUrlList);
    on<SearchUrls>(_onSearchUrls);
    on<CreateUrl>(_onCreateUrl);
    on<DeleteUrl>(_onDeleteUrl);
    on<UpdateUrl>(_onUpdateUrl);
  }

  Future<void> _onFetchUrlList(
    FetchUrlList event,
    Emitter<UrlListState> emit,
  ) async {
    emit(state.copyWith(status: UrlListStatus.loading, errorMessage: null));

    final result = await getUrlList(
      page: 1,
      limit: 10,
      keyword: state.searchKeyword,
    );

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
      page: nextPage,
      limit: 10,
      keyword: state.searchKeyword,
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

    final result = await getUrlList(
      page: 1,
      limit: 10,
      keyword: state.searchKeyword,
    );

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

  Future<void> _onSearchUrls(
    SearchUrls event,
    Emitter<UrlListState> emit,
  ) async {
    // Update the search keyword in the state
    emit(
      state.copyWith(
        searchKeyword: event.keyword,
        status: UrlListStatus.loading,
        errorMessage: null,
      ),
    );

    // Fetch the first page of results with the search keyword
    final result = await getUrlList(page: 1, limit: 10, keyword: event.keyword);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: UrlListStatus.failure,
          errorMessage: failure.message ?? 'Failed to search URLs',
        ),
      ),
      (urlListResponse) => emit(
        state.copyWith(
          status: UrlListStatus.success,
          urls: urlListResponse.data,
          currentPage: 1,
          hasReachedMax:
              urlListResponse.paging.currentPage >=
              urlListResponse.paging.totalPage,
        ),
      ),
    );
  }

  Future<void> _onCreateUrl(CreateUrl event, Emitter<UrlListState> emit) async {
    emit(state.copyWith(isCreating: true, errorMessage: null));

    final result = await createUrl(
      title: event.title,
      destination: event.destination,
      path: event.path,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isCreating: false,
          errorMessage: failure.message ?? 'Failed to create URL',
        ),
      ),
      (url) {
        // Add new URL to the beginning of the list
        final updatedUrls = [url, ...state.urls];

        emit(
          state.copyWith(
            isCreating: false,
            urls: updatedUrls,
            errorMessage: null,
          ),
        );
      },
    );
  }

  Future<void> _onDeleteUrl(DeleteUrl event, Emitter<UrlListState> emit) async {
    emit(state.copyWith(isDeleting: true, errorMessage: null));

    final result = await deleteUrl(event.id);

    result.fold(
      (failure) => emit(
        state.copyWith(
          isDeleting: false,
          errorMessage: failure.message ?? 'Failed to delete URL',
        ),
      ),
      (success) {
        // If successful, remove the URL from the list
        final updatedUrls = List<UrlEntity>.from(state.urls)
          ..removeWhere((url) => url.id == event.id);

        emit(
          state.copyWith(
            isDeleting: false,
            urls: updatedUrls,
            errorMessage: null,
          ),
        );
      },
    );
  }

  Future<void> _onUpdateUrl(UpdateUrl event, Emitter<UrlListState> emit) async {
    emit(state.copyWith(isUpdating: true, errorMessage: null));

    final result = await updateUrl(
      id: event.id,
      title: event.title,
      destination: event.destination,
      path: event.path,
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isUpdating: false,
          errorMessage: failure.message ?? 'Failed to update URL',
        ),
      ),
      (updatedUrl) {
        // If successful, update the URL in the list
        final updatedUrls = List<UrlEntity>.from(state.urls);
        final index = updatedUrls.indexWhere((url) => url.id == event.id);

        if (index != -1) {
          updatedUrls[index] = updatedUrl;
        }

        emit(
          state.copyWith(
            isUpdating: false,
            urls: updatedUrls,
            errorMessage: null,
          ),
        );
      },
    );
  }
}
