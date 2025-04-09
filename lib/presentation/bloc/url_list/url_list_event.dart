part of 'url_list_bloc.dart';

sealed class UrlListEvent extends Equatable {
  const UrlListEvent();

  @override
  List<Object> get props => [];
}

/// Fetch the initial page of URLs
class FetchUrlList extends UrlListEvent {
  const FetchUrlList();
}

/// Load the next page when user reaches the end of the list
class LoadMoreUrls extends UrlListEvent {
  const LoadMoreUrls();
}

/// Refresh the URL list (for pull-to-refresh)
class RefreshUrlList extends UrlListEvent {
  const RefreshUrlList();
}
