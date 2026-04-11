import 'package:flutter/material.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';

class ApiErrorBanner extends StatefulWidget {
  final Widget child;
  const ApiErrorBanner({super.key, required this.child});

  @override
  State<ApiErrorBanner> createState() => _ApiErrorBannerState();
}

class _ApiErrorBannerState extends State<ApiErrorBanner> {
  String? _message;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    ErrorInterceptor.onApiError = _onError;
  }

  void _onError(String message) {
    if (_showing) return;
    _message = message;
    _showing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSnackbar();
    });
  }

  void _showSnackbar() {
    if (!context.mounted) return;
    try {
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(_message ?? 'Erro', style: const TextStyle(fontSize: 14))),
            ],
          ),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ).closed.then((_) {
        _showing = false;
      });
    } catch (_) {
      _showing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
