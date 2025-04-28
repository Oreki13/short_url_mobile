import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:short_url_mobile/core/theme/app_dimension.dart';
import 'package:short_url_mobile/core/theme/app_text.dart';
import 'package:short_url_mobile/presentation/bloc/url_list/url_list_bloc.dart';
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
          appBar: AppBar(
            title: const Text('Short URL', style: AppText.h2),
            actions: [
              // Your existing ThemeCubit actions
              // ...
            ],
          ),
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
    String title,
  ) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete URL'),
          content: Text('Are you sure you want to delete "$title"?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
              onPressed: () {
                // Handle delete
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCreateUrlDialog(BuildContext context) async {
    final titleController = TextEditingController();
    final urlController = TextEditingController();
    final pathController = TextEditingController();

    // Get the current UrlListBloc instance from the parent context
    final urlListBloc = context.read<UrlListBloc>();

    // Simpan state awal untuk dibandingkan nanti
    final initialState = urlListBloc.state;
    bool isCreationRequested = false;

    return showDialog(
      context: context,
      builder:
          (dialogContext) => Dialog(
            // Make the dialog wider by using a specific width constraint
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.lg,
            ),
            child: Container(
              width:
                  double.infinity, // Make it take full width within constraints
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              padding: const EdgeInsets.all(AppDimensions.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create Short URL',
                    style: AppText.h3,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppDimensions.lg),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter a title for your URL',
                    ),
                  ),
                  const SizedBox(height: AppDimensions.md),
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      hintText: 'Enter the URL to shorten',
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: AppDimensions.md),
                  TextField(
                    controller: pathController,
                    decoration: const InputDecoration(
                      labelText: 'Endpoint',
                      hintText: 'Enter a custom path for your short URL',
                    ),
                  ),
                  const SizedBox(height: AppDimensions.sm),
                  const Text(
                    'Coming soon: Custom domain support',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.xl),
                  // Create button on top
                  StreamBuilder<UrlListState>(
                    stream: urlListBloc.stream,
                    initialData: urlListBloc.state,
                    builder: (context, snapshot) {
                      final state = snapshot.data!;

                      // Otomatis tutup dialog ketika berhasil membuat URL
                      if (isCreationRequested &&
                          !state.isCreating &&
                          state.errorMessage == null &&
                          state != initialState) {
                        // Delay tutup dialog sedikit untuk memberi waktu UI memperbarui
                        Future.microtask(() {
                          if (!dialogContext.mounted) return;
                          dialogContext.pop(true);
                          // Pop dengan nilai true menandakan sukses

                          // Tampilkan pesan sukses
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('URL created successfully'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        });
                      }
                      // Tampilkan pesan error tapi jangan tutup dialog
                      else if (isCreationRequested &&
                          !state.isCreating &&
                          state.errorMessage != null) {
                        // Reset flag karena pembuatan gagal
                        isCreationRequested = false;

                        // Tampilkan pesan error
                        Future.microtask(() {
                          if (!dialogContext.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.errorMessage!),
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        });
                      }

                      return ElevatedButton(
                        onPressed:
                            state.isCreating
                                ? null // Disable button while creating
                                : () {
                                  // Validate inputs
                                  if (titleController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please enter a title'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }

                                  if (urlController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Please enter a URL'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }

                                  if (pathController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enter an endpoint',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                    return;
                                  }

                                  // Set flag bahwa pembuatan URL diminta
                                  isCreationRequested = true;

                                  // Create URL
                                  urlListBloc.add(
                                    CreateUrl(
                                      title: titleController.text,
                                      destination: urlController.text,
                                      path: pathController.text,
                                    ),
                                  );
                                },
                        child:
                            !state.isCreating
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('Create'),
                      );
                    },
                  ),
                  const SizedBox(height: AppDimensions.md),
                  // Cancel button with outline style
                  OutlinedButton(
                    onPressed:
                        () => Navigator.of(
                          dialogContext,
                        ).pop(false), // Pop dengan nilai false untuk cancel
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
