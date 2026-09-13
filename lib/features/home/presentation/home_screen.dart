import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/design_tokens.dart';
import '../../../core/constants/app_info.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../models/ac_device.dart';
import '../../../models/ac_control_state.dart';
import '../../remote/controllers/ac_controller.dart';
import '../../remote/widgets/remote_unlock_prompt.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(acControllerProvider);
    final device = appState.selectedDevice;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Color.alphaBlend(
                AppColors.accent.withValues(alpha: .035),
                Theme.of(context).scaffoldBackgroundColor,
              ),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: AppPage(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HomeHeader(
                      onSettingsTap: () => context.go('/settings'),
                      onRepairTap: () => context.push('/repair'),
                    ),
                    const SizedBox(height: 26),
                    AnimatedSwitcher(
                      duration: AppDuration.slow,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, .025),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: device == null
                          ? _SetupHero(
                              key: const ValueKey('setup-hero'),
                              onConnect: () => context.push('/discovery'),
                            )
                          : _ConnectedHero(
                              key: ValueKey(device.id),
                              device: device,
                              control: appState.control,
                              onTap: () async {
                                final unlocked =
                                    appState.remoteUnlocked ||
                                    await requestRemoteUnlock(context, ref);
                                if (unlocked && context.mounted) {
                                  context.go('/remote');
                                }
                              },
                              onPowerChanged: (_) async {
                                final unlocked =
                                    appState.remoteUnlocked ||
                                    await requestRemoteUnlock(context, ref);
                                if (unlocked) {
                                  await ref
                                      .read(acControllerProvider.notifier)
                                      .togglePower();
                                }
                              },
                            ),
                    ),
                    if (device == null) ...[
                      const SizedBox(height: 22),
                      _SetupActionDeck(
                        onConnect: () => context.push('/discovery'),
                        onRepair: () => context.push('/repair'),
                      ),
                    ],
                    const SizedBox(height: 30),
                    const _SectionIntro(
                      eyebrow: 'YOUR CLIMATE HUB',
                      title: 'Quick actions',
                      subtitle:
                          'Connect, configure, or get help in a few taps.',
                    ),
                    const SizedBox(height: 16),
                    _QuickTools(
                      onDiscover: () => context.push('/discovery'),
                      onManual: () => context.push('/manual-connection'),
                      onGuide: () => context.push('/guide'),
                    ),
                    const SizedBox(height: 34),
                    _DevicesHeader(
                      count: appState.devices.length,
                      onSeeAll: appState.devices.isEmpty
                          ? null
                          : () => context.go('/devices'),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              if (appState.devices.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptyDevicesPanel(
                    onAdd: () => context.push('/discovery'),
                  ),
                )
              else
                SliverList.separated(
                  itemCount: appState.devices.length,
                  itemBuilder: (context, index) {
                    final item = appState.devices[index];
                    return DeviceCard(
                      device: item,
                      onTap: () {
                        ref
                            .read(acControllerProvider.notifier)
                            .selectDevice(item.id);
                        if (ref.read(acControllerProvider).remoteUnlocked) {
                          context.go('/remote');
                          return;
                        }
                        requestRemoteUnlock(context, ref).then((unlocked) {
                          if (unlocked && context.mounted) {
                            context.go('/remote');
                          }
                        });
                      },
                    );
                  },
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                ),
              if (appState.devices.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: SecondaryButton(
                      label: 'Add another device',
                      icon: Icons.add_rounded,
                      onPressed: () => context.push('/discovery'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onSettingsTap, required this.onRepairTap});

  final VoidCallback onSettingsTap;
  final VoidCallback onRepairTap;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppInfo.name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF9A7640),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontFamily: 'Georgia',
                  fontWeight: FontWeight.w500,
                  letterSpacing: -.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _HeaderAction(
          tooltip: 'Brand guides',
          icon: Icons.menu_book_outlined,
          foregroundColor: AppColors.navy,
          onPressed: onRepairTap,
        ),
        const SizedBox(width: 8),
        _HeaderAction(
          tooltip: 'Settings',
          icon: Icons.tune_rounded,
          foregroundColor: scheme.onSurface,
          onPressed: onSettingsTap,
        ),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.tooltip,
    required this.icon,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: .86),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .68)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        color: foregroundColor,
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.accentDeep,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.25,
        ),
      ),
      const SizedBox(height: 4),
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class _SetupHero extends StatelessWidget {
  const _SetupHero({required this.onConnect, super.key});

  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) => _HomeHeroShell(
    light: true,
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HeroBadge(
          icon: Icons.wifi_tethering_rounded,
          label: 'READY TO CONNECT',
          light: true,
        ),
        const SizedBox(height: 18),
        Text(
          'Bring your comfort\nonline.',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            color: AppColors.navyDeep,
            fontFamily: 'Georgia',
            fontSize: 29,
            fontWeight: FontWeight.w500,
            height: 1.12,
            letterSpacing: -.65,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'We’ll find compatible ACs on your Wi-Fi and guide you through a secure setup.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.navy.withValues(alpha: .7),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 17),
        const Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _HeroMeta(
              icon: Icons.lock_outline_rounded,
              label: 'Private setup',
              light: true,
            ),
            _HeroMeta(
              icon: Icons.schedule_rounded,
              label: 'About 2 minutes',
              light: true,
            ),
          ],
        ),
        const SizedBox(height: 19),
        TextButton.icon(
          onPressed: onConnect,
          iconAlignment: IconAlignment.end,
          icon: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF9A7640).withValues(alpha: .55),
              ),
            ),
            child: const Icon(
              Icons.arrow_forward_rounded,
              size: 16,
              color: Color(0xFF9A7640),
            ),
          ),
          label: const Text('Begin setup'),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF9A7640),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    ),
  );
}

class _SetupActionDeck extends StatelessWidget {
  const _SetupActionDeck({required this.onConnect, required this.onRepair});

  final VoidCallback onConnect;
  final VoidCallback onRepair;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Choose an action', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 13),
      _HomeActionRow(
        onTap: onConnect,
        icon: Icons.router_outlined,
        iconColor: AppColors.accentDeep,
        iconBackground: AppColors.accent.withValues(alpha: .15),
        title: 'Set up your AC',
        subtitle: 'Secure Wi-Fi guided setup',
      ),
      const SizedBox(height: 12),
      _HomeActionRow(
        onTap: onRepair,
        icon: Icons.handyman_rounded,
        iconColor: const Color(0xFF9A7640),
        iconBackground: const Color(0xFF9A7640).withValues(alpha: .13),
        title: 'Explore brand guides',
        subtitle: 'Setup, care, and repair support',
      ),
    ],
  );
}

class _HomeActionRow extends StatelessWidget {
  const _HomeActionRow({
    required this.onTap,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
  });

  final VoidCallback onTap;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: .9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: .65),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .045),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: .72),
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: scheme.onSurfaceVariant,
                    size: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectedHero extends StatelessWidget {
  const _ConnectedHero({
    required this.device,
    required this.control,
    required this.onTap,
    required this.onPowerChanged,
    super.key,
  });

  final AcDevice device;
  final AcControlState control;
  final VoidCallback onTap;
  final ValueChanged<bool> onPowerChanged;

  @override
  Widget build(BuildContext context) => _HomeHeroShell(
    onTap: onTap,
    semanticsLabel: 'Open ${device.room} remote',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const _HeroBadge(
              icon: Icons.location_on_outlined,
              label: 'PRIMARY DEVICE',
            ),
            const Spacer(),
            Switch(
              value: control.isPowered,
              onChanged: onPowerChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.cyan.withValues(alpha: .65),
              inactiveThumbColor: Colors.white70,
              inactiveTrackColor: Colors.white24,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          device.room,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -.7,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${device.brand} ${device.model}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white.withValues(alpha: .65)),
        ),
        const SizedBox(height: 28),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: AppDuration.normal,
                child: Text(
                  control.isPowered ? '${control.temperature}°' : 'Off',
                  key: ValueKey('${control.isPowered}-${control.temperature}'),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w300,
                    height: .9,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _HeroBadge(
                  icon: control.isPowered
                      ? Icons.ac_unit_rounded
                      : Icons.power_settings_new_rounded,
                  label: control.isPowered
                      ? control.mode.name.toUpperCase()
                      : 'STANDBY',
                ),
                const SizedBox(height: 9),
                Text(
                  device.roomTemperature == null
                      ? 'Room temperature —'
                      : 'Room ${device.roomTemperature!.round()}°C',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .66),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: .1)),
          ),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: device.isOnline ? AppColors.success : Colors.white54,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  device.isOnline ? 'Connected and ready' : 'Device offline',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 19,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _HomeHeroShell extends StatelessWidget {
  const _HomeHeroShell({
    required this.child,
    this.onTap,
    this.semanticsLabel,
    this.padding = const EdgeInsets.all(24),
    this.light = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticsLabel;
  final EdgeInsets padding;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final content = ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.extraLarge),
      child: Stack(
        children: [
          Positioned(
            right: -68,
            top: -74,
            child: Container(
              width: 205,
              height: 205,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: (light ? AppColors.accentDeep : Colors.white)
                      .withValues(alpha: light ? .1 : .09),
                  width: 38,
                ),
              ),
            ),
          ),
          Positioned(
            right: 14,
            bottom: 75,
            child: Icon(
              Icons.ac_unit_rounded,
              color: (light ? AppColors.accentDeep : Colors.white).withValues(
                alpha: light ? .055 : .04,
              ),
              size: 126,
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
    return Semantics(
      button: onTap != null,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.extraLarge),
            gradient: light
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0, .52, 1],
                    colors: [
                      Color(0xFFFFFFFF),
                      Color(0xFFF0F8FC),
                      Color(0xFFDFF1F8),
                    ],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0, .48, 1],
                    colors: [
                      Color(0xFF103D72),
                      AppColors.navy,
                      AppColors.navyDeep,
                    ],
                  ),
            border: Border.all(
              color: (light ? AppColors.navy : Colors.white).withValues(
                alpha: light ? .08 : .04,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: (light ? AppColors.navyDeep : AppColors.navyDeep)
                    .withValues(alpha: light ? .1 : .3),
                blurRadius: light ? 28 : 38,
                offset: Offset(0, light ? 14 : 20),
              ),
            ],
          ),
          child: onTap == null
              ? content
              : InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(AppRadius.extraLarge),
                  child: content,
                ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.icon,
    required this.label,
    this.light = false,
  });

  final IconData icon;
  final String label;
  final bool light;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: (light ? AppColors.accentDeep : Colors.white).withValues(
        alpha: light ? .08 : .1,
      ),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(
        color: (light ? AppColors.accentDeep : Colors.white).withValues(
          alpha: light ? .12 : .1,
        ),
      ),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: light ? AppColors.accentDeep : AppColors.cyan,
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: light ? AppColors.navy : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: .8,
          ),
        ),
      ],
    ),
  );
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({
    required this.icon,
    required this.label,
    this.light = false,
  });

  final IconData icon;
  final String label;
  final bool light;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icon,
        color: light ? AppColors.navy.withValues(alpha: .5) : Colors.white54,
        size: 15,
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: TextStyle(
          color: light ? AppColors.navy.withValues(alpha: .58) : Colors.white60,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _QuickTools extends StatelessWidget {
  const _QuickTools({
    required this.onDiscover,
    required this.onManual,
    required this.onGuide,
  });

  final VoidCallback onDiscover;
  final VoidCallback onManual;
  final VoidCallback onGuide;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 360;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _ToolCard(
              icon: Icons.radar_rounded,
              title: compact ? 'Discover' : 'Auto discover',
              subtitle: compact ? null : 'Scan Wi-Fi',
              onTap: onDiscover,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ToolCard(
              icon: Icons.lan_outlined,
              title: 'Manual IP',
              subtitle: compact ? null : 'Connect directly',
              onTap: onManual,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ToolCard(
              icon: Icons.auto_stories_outlined,
              title: compact ? 'Guide' : 'Setup guide',
              subtitle: compact ? null : 'Get help',
              onTap: onGuide,
            ),
          ),
        ],
      );
    },
  );
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: dark ? .7 : .72),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: dark ? .13 : .62),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? .14 : .045),
                  blurRadius: 20,
                  offset: const Offset(0, 9),
                ),
              ],
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(icon, color: AppColors.accentDeep, size: 20),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
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

class _DevicesHeader extends StatelessWidget {
  const _DevicesHeader({required this.count, required this.onSeeAll});

  final int count;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          'My devices',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      if (onSeeAll != null)
        TextButton(onPressed: onSeeAll, child: const Text('See all'))
      else
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            '$count connected',
            style: const TextStyle(
              color: AppColors.accentDeep,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
    ],
  );
}

class _EmptyDevicesPanel extends StatelessWidget {
  const _EmptyDevicesPanel({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(22),
      borderRadius: AppRadius.extraLarge,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.accent.withValues(alpha: .18),
                      AppColors.cyan.withValues(alpha: .1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(19),
                ),
                child: const Icon(
                  Icons.devices_other_rounded,
                  color: AppColors.accentDeep,
                  size: 27,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your climate hub is ready',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add an air conditioner to control temperature, modes, and schedules from one place.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: .5),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.success,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Secure local control • No subscription required',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Add your first device',
            icon: Icons.add_rounded,
            onPressed: onAdd,
          ),
        ],
      ),
    );
  }
}
