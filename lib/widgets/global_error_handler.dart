import 'dart:async';

import 'package:flutter/material.dart';

import '../core/services/error_handling_service.dart';
import 'app_snackbar.dart';

/// 🚨 GLOBAL ERROR HANDLER - Material 3 Error UI
///
/// Wraps the app and listens to ErrorHandlingService.errorStream
/// to automatically show appropriate UI feedback for errors.
///
/// Usage:
/// ```dart
/// GlobalErrorHandler(
///   child: MaterialApp(...),
/// )
/// ```
class GlobalErrorHandler extends StatefulWidget {
  final Widget child;

  const GlobalErrorHandler({super.key, required this.child});

  @override
  State<GlobalErrorHandler> createState() => _GlobalErrorHandlerState();
}

class _GlobalErrorHandlerState extends State<GlobalErrorHandler> {
  StreamSubscription<AppException>? _errorSubscription;
  final _errorService = ErrorHandlingService();

  @override
  void initState() {
    super.initState();
    _subscribeToErrors();
  }

  void _subscribeToErrors() {
    _errorSubscription = _errorService.errorStream.listen(_handleError);
  }

  void _handleError(AppException error) {
    // Ensure we have a valid context
    if (!mounted) return;

    // Get user-friendly message
    final message = error.userMessage;

    // Show appropriate UI based on severity
    switch (error.severity) {
      case ErrorSeverity.info:
        AppSnackBar.info(context, message: message);
        break;

      case ErrorSeverity.warning:
        AppSnackBar.warning(context, message: message);
        break;

      case ErrorSeverity.error:
        // Check if it's a retryable error
        if (error.code == 'network' || error.code == 'timeout') {
          AppSnackBar.showRetry(
            context,
            message: message,
            onRetry: () {
              // Dismiss snackbar - user can retry their action
              AppSnackBar.hide(context);
            },
          );
        } else {
          AppSnackBar.error(context, message: message);
        }
        break;

      case ErrorSeverity.fatal:
        // For fatal errors, show a persistent error
        AppSnackBar.error(
          context,
          message: message,
          duration: const Duration(seconds: 10),
        );
        break;
    }
  }

  @override
  void dispose() {
    _errorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
