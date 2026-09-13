import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/ads/app_open_ad_service.dart';
import '../../../core/constants/app_info.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/constants/storage_keys.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  var _visible = false;
  late final AnimationController _loadingController;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
    unawaited(_finishLaunch());
  }

  Future<void> _finishLaunch() async {
    final preferences = await SharedPreferences.getInstance();
    final onboardingComplete =
        preferences.getBool(StorageKeys.onboardingComplete) ?? false;
    await Future<void>.delayed(const Duration(seconds: 4));
    await AppOpenAdService.instance.showAfterSplash();
    if (onboardingComplete) {
      AppOpenAdService.instance.enableForegroundAds();
    }
    if (mounted) context.go(onboardingComplete ? '/home' : '/onboarding');
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              AppColors.accent.withValues(alpha: dark ? .12 : .09),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedOpacity(
              opacity: _visible ? 1 : 0,
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOut,
              child: AnimatedScale(
                scale: _visible ? 1 : .86,
                duration: const Duration(milliseconds: 750),
                curve: Curves.easeOutBack,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: .35),
                            blurRadius: 38,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Image.asset(
                          'assets/branding/appicon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppInfo.name,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  height: 1.04,
                                  letterSpacing: -1.1,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppInfo.subtitle,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  letterSpacing: .5,
                                ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(74, 24, 74, 0),
                      child: Semantics(
                        label: 'Loading app',
                        value: 'Four second loading progress',
                        child: AnimatedBuilder(
                          animation: _loadingController,
                          builder: (context, _) => ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: _loadingController.value,
                              minHeight: 5,
                              backgroundColor: AppColors.accent.withValues(
                                alpha: .14,
                              ),
                              valueColor: const AlwaysStoppedAnimation(
                                AppColors.accentDeep,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
