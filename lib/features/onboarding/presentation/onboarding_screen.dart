import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/ads/app_open_ad_service.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/widgets/premium_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  var _page = 0;

  static const _pages = [
    _OnboardingData(
      title: 'Control your climate',
      description:
          'Control compatible air conditioners directly from your phone.',
      icon: Icons.thermostat_rounded,
    ),
    _OnboardingData(
      title: 'Connect in seconds',
      description:
          'Automatically discover compatible AC devices on your Wi-Fi network.',
      icon: Icons.radar_rounded,
    ),
    _OnboardingData(
      title: 'Comfort made simple',
      description:
          'Temperature, fan, mode, swing and timers — all from one elegant remote.',
      icon: Icons.auto_awesome_rounded,
    ),
    _OnboardingData(
      title: 'Help when you need it',
      description:
          'Run safe guided checks, look up error codes, and know when it is time to book a technician.',
      icon: Icons.health_and_safety_rounded,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(StorageKeys.onboardingComplete, true);
    AppOpenAdService.instance.enableForegroundAds();
    if (mounted) context.go('/home');
  }

  void _continue() {
    if (_page == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: AppDuration.slow,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppPage(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: _finish, child: const Text('Skip')),
          ),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              onPageChanged: (value) => setState(() => _page = value),
              itemBuilder: (context, index) =>
                  _OnboardingPage(data: _pages[index]),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var index = 0; index < _pages.length; index++)
                AnimatedContainer(
                  duration: AppDuration.normal,
                  width: index == _page ? 28 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: index == _page
                        ? AppColors.accentDeep
                        : Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: _page == _pages.length - 1 ? 'Get Started' : 'Continue',
            onPressed: _continue,
            icon: Icons.arrow_forward_rounded,
          ),
        ],
      ),
    ),
  );
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingData data;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: constraints.maxWidth.clamp(240, 380),
          height: constraints.maxHeight.clamp(260, 410) * .62,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: .23),
                      AppColors.accent.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              Transform.rotate(
                angle: -.12,
                child: GlassCard(
                  borderRadius: AppRadius.extraLarge,
                  padding: const EdgeInsets.all(35),
                  child: Icon(data.icon, size: 82, color: AppColors.accentDeep),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 26),
        Text(
          data.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Text(
            data.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    ),
  );
}

class _OnboardingData {
  const _OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
  });
  final String title;
  final String description;
  final IconData icon;
}
