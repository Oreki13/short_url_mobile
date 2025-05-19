import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:short_url_mobile/presentation/bloc/url_list/url_list_bloc.dart';
import 'dart:async';

class DeleteConfirmationDialog extends StatelessWidget {
  final String id;
  final String title;
  final UrlListBloc urlListBloc;

  const DeleteConfirmationDialog({
    super.key,
    required this.id,
    required this.title,
    required this.urlListBloc,
  });

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<bool> isDeletionRequestedNotifier = ValueNotifier(
      false,
    );

    // We'll use a StreamSubscription to listen to bloc state changes
    StreamSubscription<UrlListState>? subscription;

    // Setup the subscription when the widget is inserted into the tree
    WidgetsBinding.instance.addPostFrameCallback((_) {
      subscription = urlListBloc.stream.listen((state) {
        // Only process if deletion was requested
        if (!isDeletionRequestedNotifier.value) return;

        // Check if deletion completed (was deleting, and now it's not)
        if (state.isDeleting == false && isDeletionRequestedNotifier.value) {
          if (state.errorMessage == null) {
            // Close dialog and show success message
            if (!context.mounted) return;
            context.pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('URL "$title" deleted successfully'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            // Show error message but keep dialog open
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to delete: ${state.errorMessage}'),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      });
    });

    return PopScope(
      // Cancel subscription when the dialog is dismissed
      onPopInvokedWithResult: (didPop, _) {
        subscription?.cancel();
      },
      child: BlocProvider.value(
        value: urlListBloc,
        child: BlocBuilder<UrlListBloc, UrlListState>(
          builder: (context, state) {
            return AlertDialog(
              title: const Text('Delete URL'),
              content: Text('Are you sure you want to delete "$title"?'),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    subscription?.cancel();
                    context.pop();
                  },
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed:
                      state.isDeleting
                          ? null
                          : () {
                            isDeletionRequestedNotifier.value = true;
                            // Dispatch the delete event to the BLoC
                            urlListBloc.add(DeleteUrl(id: id, title: title));
                          },
                  child:
                      state.isDeleting
                          ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Delete'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Static method to show dialog for convenience
  static Future<void> show(
    BuildContext context, {
    required String id,
    required String title,
  }) {
    // Get the bloc from the parent context before creating dialog
    final urlListBloc = context.read<UrlListBloc>();

    return showDialog<void>(
      context: context,
      builder:
          (BuildContext dialogContext) => DeleteConfirmationDialog(
            id: id,
            title: title,
            urlListBloc: urlListBloc,
          ),
    );
  }
}
