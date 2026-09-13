import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/constants/app_info.dart';
import '../../../core/constants/design_tokens.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  late final WebViewController _controller;
  var _isLoading = true;
  String? _error;
  String? _offlinePolicy;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _error = null;
              _offlinePolicy = null;
            });
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (!(error.isForMainFrame ?? true) || !mounted) return;
            setState(() {
              _isLoading = false;
              _error = error.description;
            });
            _loadOfflinePolicy();
          },
        ),
      )
      ..loadRequest(Uri.parse(AppInfo.privacyPolicyUrl));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Privacy Policy'),
      actions: [
        IconButton(
          tooltip: 'Reload policy',
          onPressed: _reload,
          icon: const Icon(Icons.refresh_rounded),
        ),
        const SizedBox(width: 4),
      ],
    ),
    body: Stack(
      children: [
        if (_error == null && _offlinePolicy == null)
          WebViewWidget(controller: _controller),
        if (_error != null && _offlinePolicy == null)
          _PolicyLoadError(message: _error!, onRetry: _reload),
        if (_offlinePolicy != null) _OfflinePolicy(text: _offlinePolicy!),
        if (_isLoading)
          const Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(
              minHeight: 3,
              color: AppColors.accentDeep,
            ),
          ),
      ],
    ),
  );

  void _reload() {
    setState(() {
      _isLoading = true;
      _error = null;
      _offlinePolicy = null;
    });
    _controller.loadRequest(Uri.parse(AppInfo.privacyPolicyUrl));
  }

  Future<void> _loadOfflinePolicy() async {
    try {
      final policy = await rootBundle.loadString(
        'assets/legal/privacy_policy.txt',
      );
      if (mounted) setState(() => _offlinePolicy = policy);
    } catch (_) {
      // The error state already provides retry and copy-link actions.
    }
  }
}

class _OfflinePolicy extends StatelessWidget {
  const _OfflinePolicy({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(99),
        ),
        child: const Text(
          'OFFLINE COPY',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.accentDeep,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
      const SizedBox(height: 18),
      SelectableText(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.55),
      ),
    ],
  );
}

class _PolicyLoadError extends StatelessWidget {
  const _PolicyLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 48,
            color: AppColors.accentDeep,
          ),
          const SizedBox(height: 16),
          Text(
            'Could not load the policy',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 22),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                const ClipboardData(text: AppInfo.privacyPolicyUrl),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Policy link copied')),
                );
              }
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy policy link'),
          ),
        ],
      ),
    ),
  );
}
