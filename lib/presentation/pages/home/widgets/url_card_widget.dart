import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:short_url_mobile/core/theme/app_color.dart';
import 'package:short_url_mobile/core/theme/app_dimension.dart';
import 'package:short_url_mobile/core/theme/app_text.dart';

class UrlCard extends StatelessWidget {
  final String title;
  final String originalUrl;
  final String shortUrl;
  final int openedCount;
  final DateTime createdAt;
  final VoidCallback? onTap;
  final VoidCallback? onCopy;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const UrlCard({
    super.key,
    required this.title,
    required this.originalUrl,
    required this.shortUrl,
    required this.openedCount,
    required this.createdAt,
    this.onTap,
    this.onCopy,
    this.onShare,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Format the date for display
    final formattedDate = DateFormat('dd MMMM yyyy', 'id_ID').format(createdAt);

    return Card(
      elevation: AppDimensions.elevationSm,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimensions.md,
        vertical: AppDimensions.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        side: BorderSide(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and metadata section
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.md,
              AppDimensions.md,
              AppDimensions.md,
              AppDimensions.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // URL Icon indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? AppColors.primaryDarkBlue.withAlpha(51)
                            : AppColors.primaryBlue.withAlpha(25),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: Icon(
                    Icons.link_rounded,
                    color:
                        isDark
                            ? AppColors.primaryDarkBlue
                            : AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppDimensions.sm),

                // Title and stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppText.bodyLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppDimensions.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.remove_red_eye_outlined,
                            size: AppDimensions.iconSm,
                            color: AppColors.grey,
                          ),
                          const SizedBox(width: AppDimensions.xs),
                          Text(
                            '$openedCount view${openedCount != 1 ? 's' : ''}',
                            style: AppText.caption.copyWith(
                              color: AppColors.grey,
                            ),
                          ),
                          const SizedBox(width: AppDimensions.md),
                          Icon(
                            Icons.calendar_today_outlined,
                            size: AppDimensions.iconSm,
                            color: AppColors.grey,
                          ),
                          const SizedBox(width: AppDimensions.xs),
                          Text(
                            formattedDate,
                            style: AppText.caption.copyWith(
                              color: AppColors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Original URL (truncated)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.xs,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.link_off,
                  size: AppDimensions.iconMd,
                  color: AppColors.grey,
                ),
                const SizedBox(width: AppDimensions.xs),
                Expanded(
                  child: Text(
                    originalUrl,
                    style: AppText.bodyMedium.copyWith(color: AppColors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Short URL (highlighted)
          Container(
            margin: const EdgeInsets.fromLTRB(
              AppDimensions.md,
              AppDimensions.xs,
              AppDimensions.md,
              AppDimensions.md,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.md,
              vertical: AppDimensions.xs,
            ),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? AppColors.primaryBlue.withAlpha(25)
                      : AppColors.lightGrey.withAlpha(76),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
              border: Border.all(
                color:
                    isDark
                        ? AppColors.primaryDarkBlue.withAlpha(76)
                        : AppColors.lightGrey,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.link,
                  size: AppDimensions.iconSm,
                  color:
                      isDark
                          ? AppColors.primaryDarkBlue
                          : AppColors.primaryBlue,
                ),
                const SizedBox(width: AppDimensions.sm),
                Expanded(
                  child: Text(
                    shortUrl,
                    style: AppText.bodyMedium.copyWith(
                      color:
                          isDark
                              ? AppColors.primaryDarkBlue
                              : AppColors.primaryBlue,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.copy_rounded,
                    size: AppDimensions.iconSm,
                    color:
                        isDark
                            ? AppColors.primaryDarkBlue
                            : AppColors.primaryBlue,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: shortUrl)).then((_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('URL copied to clipboard'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppColors.info,
                          duration: const Duration(seconds: 2),
                          width: 200,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                          ),
                        ),
                      );
                    });
                    if (onCopy != null) onCopy!();
                  },
                  tooltip: 'Copy short URL',
                ),
              ],
            ),
          ),

          // Action buttons
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppDimensions.radiusLg),
                bottomRight: Radius.circular(AppDimensions.radiusLg),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Open button
                TextButton.icon(
                  icon: const Icon(
                    Icons.open_in_new,
                    size: AppDimensions.iconSm,
                  ),
                  label: const Text('Open'),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        isDark
                            ? AppColors.primaryDarkBlue
                            : AppColors.primaryBlue,
                    textStyle: AppText.button,
                  ),
                  onPressed: onTap,
                ),
                // Share button
                IconButton(
                  icon: const Icon(
                    Icons.share_outlined,
                    size: AppDimensions.iconMd,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: onShare,
                  tooltip: 'Share URL',
                ),
                // Delete button
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    size: AppDimensions.iconMd,
                    color: AppColors.error,
                  ),
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  tooltip: 'Delete URL',
                ),
                const SizedBox(width: AppDimensions.xs),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
