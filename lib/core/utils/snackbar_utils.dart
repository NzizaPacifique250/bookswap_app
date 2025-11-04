import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Snackbar utility functions for consistent messaging throughout the app
class SnackbarUtils {
  SnackbarUtils._(); // Private constructor to prevent instantiation

  /// Duration for auto-dismissing snackbars (3 seconds)
  static const Duration _defaultDuration = Duration(seconds: 3);

  /// Shows a success snackbar with green background and check icon
  static void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _SnackbarContent(
          message: message,
          icon: Icons.check_circle,
          iconColor: AppColors.success,
        ),
        backgroundColor: AppColors.cardBackground,
        behavior: SnackBarBehavior.floating,
        duration: _defaultDuration,
        margin: const EdgeInsets.only(
          bottom: 80,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
    );
  }

  /// Shows an error snackbar with red background and error icon
  static void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _SnackbarContent(
          message: message,
          icon: Icons.error,
          iconColor: AppColors.error,
        ),
        backgroundColor: AppColors.cardBackground,
        behavior: SnackBarBehavior.floating,
        duration: _defaultDuration,
        margin: const EdgeInsets.only(
          bottom: 80,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
    );
  }

  /// Shows an info snackbar with blue background and info icon
  static void showInfoSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _SnackbarContent(
          message: message,
          icon: Icons.info,
          iconColor: AppColors.info,
        ),
        backgroundColor: AppColors.cardBackground,
        behavior: SnackBarBehavior.floating,
        duration: _defaultDuration,
        margin: const EdgeInsets.only(
          bottom: 80,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
    );
  }

  /// Shows a loading snackbar with spinner (does not auto-dismiss)
  /// Returns the ScaffoldFeatureController to allow manual dismissal
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>
      showLoadingSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    return ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: _LoadingSnackbarContent(message: message),
        backgroundColor: AppColors.cardBackground,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(days: 1), // Don't auto-dismiss
        margin: const EdgeInsets.only(
          bottom: 80,
          left: 16,
          right: 16,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
    );
  }

  /// Hides the current snackbar
  static void hideSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}

/// Custom snackbar content widget with icon and message
class _SnackbarContent extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color iconColor;

  const _SnackbarContent({
    required this.message,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom loading snackbar content widget with spinner
class _LoadingSnackbarContent extends StatelessWidget {
  final String message;

  const _LoadingSnackbarContent({required this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

