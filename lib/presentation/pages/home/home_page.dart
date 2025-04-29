import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:short_url_mobile/core/theme/app_dimension.dart';
import 'package:short_url_mobile/core/theme/app_text.dart';
import 'package:short_url_mobile/presentation/bloc/url_list/url_list_bloc.dart';
import 'package:short_url_mobile/presentation/pages/home/widgets/create_url_dialog.dart';
import 'package:short_url_mobile/presentation/pages/home/widgets/delete_confirmation_dialog.dart';
import 'package:short_url_mobile/presentation/pages/home/widgets/search_bar_widget.dart';
import 'package:short_url_mobile/presentation/pages/home/widgets/url_card_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:short_url_mobile/dependency.dart' as di;
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;

  // Debounce duration
  final Duration _debounceDuration = const Duration(milliseconds: 500);

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Debounce function
  void _onSearchChanged(BuildContext context, String value) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      // This code runs after the debounce delay
      context.read<UrlListBloc>().add(SearchUrls(value));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (_) => di.sl<UrlListBloc>()..add(const FetchUrlList()),
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Short URL', style: AppText.h2)),
          body: Column(
            children: [
              // Add search bar below AppBar
              BlocBuilder<UrlListBloc, UrlListState>(
                buildWhen:
                    (previous, current) =>
                        previous.searchKeyword != current.searchKeyword,
                builder: (context, state) {
                  // Update searchController text if state keyword changes from elsewhere
                  if (state.searchKeyword != null &&
                      state.searchKeyword != searchController.text) {
                    searchController.text = state.searchKeyword!;
                  }

                  return SearchBarWidget(
                    controller: searchController,
                    onChanged: (val) {
                      _onSearchChanged(context, val);
                    },
                    onClear: () {
                      context.read<UrlListBloc>().add(const SearchUrls(''));
                    },
                    hintText: 'Search URLs...',
                  );
                },
              ),
              // Main content (URL list)
              Expanded(
                child: BlocConsumer<UrlListBloc, UrlListState>(
                  listenWhen:
                      (previous, current) =>
                          previous.isRefreshing && !current.isRefreshing,
                  listener: (context, state) {
                    // When refresh completes, show feedback
                    if (state.status == UrlListStatus.success &&
                        !state.isRefreshing) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Refresh complete'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else if (state.status == UrlListStatus.failure &&
                        !state.isRefreshing) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to refresh: ${state.errorMessage}',
                          ),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          duration: const Duration(seconds: 3),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    {
                      switch (state.status) {
                        case UrlListStatus.initial:
                        case UrlListStatus.loading:
                          return const Center(
                            child: CircularProgressIndicator(),
                          );

                        case UrlListStatus.failure:
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Failed to load URLs', style: AppText.h3),
                                const SizedBox(height: AppDimensions.sm),
                                Text(
                                  state.errorMessage ?? 'Unknown error',
                                  style: AppText.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppDimensions.md),
                                ElevatedButton(
                                  onPressed:
                                      () =>
                                          context.read<UrlListBloc>()
                                            ..add(const FetchUrlList()),
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          );

                        case UrlListStatus.success:
                        case UrlListStatus.loadingMore:
                          if (state.urls.isEmpty) {
                            return RefreshIndicator(
                              onRefresh: () async {
                                context.read<UrlListBloc>().add(
                                  const RefreshUrlList(),
                                );
                              },
                              child: ListView(
                                // Make ListView fill the screen so pulling works even when empty
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.height *
                                        0.7,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'No URLs found',
                                            style: AppText.h3,
                                          ),
                                          const SizedBox(
                                            height: AppDimensions.md,
                                          ),
                                          Text(
                                            'Create your first short URL',
                                            style: AppText.bodyMedium,
                                          ),
                                          const SizedBox(
                                            height: AppDimensions.lg,
                                          ),
                                          Icon(
                                            Icons.link_off,
                                            size: 64,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondary
                                                .withAlpha(100),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: () async {
                              context.read<UrlListBloc>().add(
                                const RefreshUrlList(),
                              );
                              // Return a completed future so RefreshIndicator knows to stop
                              return Future<void>.value();
                            },
                            child: Stack(
                              children: [
                                ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: AppDimensions.md,
                                  ),
                                  itemCount:
                                      state.hasReachedMax
                                          ? state.urls.length
                                          : state.urls.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index >= state.urls.length) {
                                      // Show loading indicator at the bottom
                                      if (!state.hasReachedMax) {
                                        // Trigger loading more when reaching the end
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              context.read<UrlListBloc>().add(
                                                const LoadMoreUrls(),
                                              );
                                            });

                                        return const Padding(
                                          padding: EdgeInsets.all(
                                            AppDimensions.md,
                                          ),
                                          child: Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      return const SizedBox();
                                    }

                                    final url = state.urls[index];
                                    final shortUrlString =
                                        'https://s-url.com/${url.path}';

                                    return UrlCard(
                                      title: url.title,
                                      originalUrl: url.destination,
                                      shortUrl: shortUrlString,
                                      openedCount: url.countClicks,
                                      createdAt: url.createdAt,
                                      onTap: () => _launchUrl(url.destination),
                                      onCopy: () {
                                        // Analytics or other callback when URL is copied
                                      },
                                      onShare:
                                          () => _shareUrl(
                                            shortUrlString,
                                            url.title,
                                          ),
                                      onDelete:
                                          () => _showDeleteConfirmation(
                                            context,
                                            url.id,
                                            url.title,
                                          ),
                                    );
                                  },
                                ),

                                // Show overlay refreshing indicator when isRefreshing is true
                                if (state.isRefreshing)
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withAlpha(30),
                                      child: const Center(
                                        child: SizedBox(
                                          height: 2,
                                          child: LinearProgressIndicator(),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // Show dialog to create new short URL
              _showCreateUrlDialog(context);
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> _shareUrl(String url, String title) async {
    await Share.share('Check out this link: $url', subject: title);
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    String id,
    String title,
  ) async {
    await DeleteConfirmationDialog.show(context, id: id, title: title);
  }

  Future<void> _showCreateUrlDialog(BuildContext context) async {
    await CreateUrlDialog.show(context);
  }
}
