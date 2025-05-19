import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:short_url_mobile/core/theme/app_dimension.dart';
import 'package:short_url_mobile/core/theme/app_text.dart';
import 'package:short_url_mobile/presentation/bloc/url_list/url_list_bloc.dart';

class EditUrlDialog extends StatelessWidget {
  final UrlListBloc urlListBloc;
  final String id;
  final String title;
  final String originalUrl;
  final String path;

  const EditUrlDialog({
    super.key,
    required this.urlListBloc,
    required this.id,
    required this.title,
    required this.originalUrl,
    required this.path,
  });

  @override
  Widget build(BuildContext context) {
    final titleController = TextEditingController(text: title);
    final urlController = TextEditingController(text: originalUrl);
    final pathController = TextEditingController(text: path);

    // Save initial state for comparison later
    final initialState = urlListBloc.state;
    final ValueNotifier<bool> isUpdateRequestedNotifier = ValueNotifier(false);

    return BlocProvider.value(
      value: urlListBloc,
      child: Dialog(
        // Make the dialog wider by using a specific width constraint
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.md,
          vertical: AppDimensions.lg,
        ),
        child: Container(
          width: double.infinity, // Make it take full width within constraints
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          padding: const EdgeInsets.all(AppDimensions.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Edit Short URL',
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
              // Update button on top
              BlocConsumer<UrlListBloc, UrlListState>(
                listener: (context, state) {
                  // Automatically close dialog when URL update is successful
                  if (isUpdateRequestedNotifier.value &&
                      !state.isUpdating &&
                      state.errorMessage == null &&
                      state != initialState) {
                    // Delay closing the dialog to give UI time to update
                    Future.microtask(() {
                      if (!context.mounted) return;
                      context.pop(true); // Pop with true indicating success

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('URL updated successfully'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    });
                  }
                  // Show error message but keep dialog open
                  else if (isUpdateRequestedNotifier.value &&
                      !state.isUpdating &&
                      state.errorMessage != null) {
                    // Reset flag because update failed
                    isUpdateRequestedNotifier.value = false;

                    // Show error message
                    Future.microtask(() {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.errorMessage!),
                          backgroundColor: Theme.of(context).colorScheme.error,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    });
                  }
                },
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed:
                            state.isUpdating
                                ? null // Disable button while updating
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

                                  // Set flag that URL update was requested
                                  isUpdateRequestedNotifier.value =
                                      true; // Set flag that URL update was requested
                                  isUpdateRequestedNotifier.value = true;

                                  // Update URL
                                  urlListBloc.add(
                                    UpdateUrl(
                                      id: id,
                                      title: titleController.text,
                                      destination: urlController.text,
                                      path: pathController.text,
                                    ),
                                  );
                                },
                        child:
                            state.isUpdating
                                ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color:
                                        Theme.of(context).colorScheme.onPrimary,
                                  ),
                                )
                                : const Text('Update'),
                      ),
                      const SizedBox(height: AppDimensions.md),
                      // Cancel button with outline style
                      OutlinedButton(
                        onPressed:
                            () =>
                                context.pop(false), // Pop with false for cancel
                        child: const Text('Cancel'),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Static method to show dialog for convenience
  static Future<bool?> show(
    BuildContext context, {
    required String id,
    required String title,
    required String originalUrl,
    required String path,
  }) {
    // Get the bloc from the parent context before creating dialog
    final urlListBloc = context.read<UrlListBloc>();

    return showDialog<bool>(
      context: context,
      builder:
          (BuildContext dialogContext) => EditUrlDialog(
            urlListBloc: urlListBloc,
            id: id,
            title: title,
            originalUrl: originalUrl,
            path: path,
          ),
    );
  }
}
