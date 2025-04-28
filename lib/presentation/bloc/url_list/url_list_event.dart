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

class SearchUrls extends UrlListEvent {
  final String keyword;

  const SearchUrls(this.keyword);

  @override
  List<Object> get props => [keyword];
}

/// Create a new short URL
class CreateUrl extends UrlListEvent {
  final String title;
  final String destination;
  final String path;

  const CreateUrl({
    required this.title,
    required this.destination,
    required this.path,
  });

  @override
  List<Object> get props => [title, destination, path];
}

/// Delete a URL by its ID
class DeleteUrl extends UrlListEvent {
  final String id;
  final String title; // For displaying meaningful messages

  const DeleteUrl({required this.id, required this.title});

  @override
  List<Object> get props => [id, title];
}
