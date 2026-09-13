import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ads/app_open_ad_service.dart';
import '../constants/design_tokens.dart';

class AppShell extends StatelessWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const _destinations = [
    ('Home', Icons.home_rounded, '/home'),
    ('Remote', Icons.ac_unit_rounded, '/remote'),
    ('Devices', Icons.devices_other_rounded, '/devices'),
    ('Repair', Icons.handyman_rounded, '/repair'),
    ('Settings', Icons.tune_rounded, '/settings'),
  ];

  int _indexForLocation(String location) {
    if (location.startsWith('/remote') || location.startsWith('/timers')) {
      return 1;
    }
    if (location.startsWith('/devices')) return 2;
    if (location.startsWith('/repair')) return 3;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _indexForLocation(GoRouterState.of(context).uri.path);
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? .34 : .11),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    height: 70,
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: dark ? .74 : .76),
                      border: Border.all(
                        color: (dark ? scheme.outlineVariant : AppColors.navy)
                            .withValues(alpha: dark ? .48 : .1),
                      ),
                    ),
                    child: Row(
                      children: [
                        for (
                          var index = 0;
                          index < _destinations.length;
                          index++
                        )
                          Expanded(
                            child: _NavItem(
                              label: _destinations[index].$1,
                              icon: _destinations[index].$2,
                              selected: currentIndex == index,
                              onTap: () async {
                                if (currentIndex == index) return;
                                if (_destinations[index].$3 == '/settings') {
                                  await AppOpenAdService.instance
                                      .showInterstitialForSettingsEntry();
                                }
                                if (context.mounted) {
                                  context.go(_destinations[index].$3);
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: AnimatedContainer(
        duration: AppDuration.normal,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: .14)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected
                  ? AppColors.accentDeep
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.accentDeep
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
