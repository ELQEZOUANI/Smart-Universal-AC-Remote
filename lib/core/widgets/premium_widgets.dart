import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/ac_device.dart';
import '../constants/app_info.dart';
import '../constants/design_tokens.dart';

class AppPage extends StatelessWidget {
  const AppPage({
    required this.child,
    super.key,
    this.maxWidth = 760,
    this.padding = const EdgeInsets.fromLTRB(20, 12, 20, 128),
    this.safeTop = true,
    this.accentColor,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;
  final bool safeTop;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = accentColor ?? AppColors.accent;
    return Stack(
      children: [
        Positioned(
          top: -125,
          right: -95,
          child: _Glow(
            size: 320,
            color: accent.withValues(alpha: dark ? .11 : .13),
          ),
        ),
        Positioned(
          top: 360,
          left: -155,
          child: _Glow(
            size: 300,
            color: accent.withValues(alpha: dark ? .055 : .06),
          ),
        ),
        SafeArea(
          top: safeTop,
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, this.size = 260});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    ),
  );
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.borderRadius = AppRadius.large,
    this.color,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final decoration = BoxDecoration(
      color: color ?? scheme.surface.withValues(alpha: dark ? .84 : .94),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: (dark ? scheme.outlineVariant : AppColors.navy).withValues(
          alpha: dark ? .45 : .1,
        ),
      ),
      boxShadow: [
        BoxShadow(
          color: (dark ? Colors.black : AppColors.navyDeep).withValues(
            alpha: dark ? .2 : .065,
          ),
          blurRadius: 28,
          offset: const Offset(0, 13),
        ),
      ],
    );
    final content = Padding(padding: padding, child: child);
    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: content,
        ),
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    required this.title,
    super.key,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}

class AppBrandIcon extends StatelessWidget {
  const AppBrandIcon({super.key, this.size = 48, this.borderRadius});

  final double size;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? size * .3;
    return Semantics(
      label: '${AppInfo.name} app icon',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentDeep.withValues(alpha: .24),
              blurRadius: size * .4,
              offset: Offset(0, size * .16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.asset('assets/branding/appicon.png', fit: BoxFit.cover),
        ),
      ),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (leading != null) ...[leading!, const SizedBox(width: 14)],
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppInfo.name.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.brass,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(title, style: Theme.of(context).textTheme.headlineLarge),
            if (subtitle != null) ...[
              const SizedBox(height: 5),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
      ?trailing,
    ],
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 58,
    child: FilledButton(
      onPressed: loading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
      child: AnimatedSwitcher(
        duration: AppDuration.fast,
        child: loading
            ? const SizedBox.square(
                key: ValueKey('loading'),
                dimension: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Row(
                key: const ValueKey('label'),
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 9),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
      ),
    ),
  );
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 56,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 20),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha: .72),
        side: BorderSide(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: .72),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
      ),
    ),
  );
}

class ConnectionStatus extends StatelessWidget {
  const ConnectionStatus({
    required this.online,
    super.key,
    this.compact = false,
  });

  final bool online;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = online
        ? AppColors.success
        : Theme.of(context).colorScheme.outline;
    return Semantics(
      label: online ? 'Connected' : 'Offline',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 10,
          vertical: 5,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              online ? (compact ? 'Online' : 'Connected') : 'Offline',
              style: TextStyle(
                color: color,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DeviceCard extends StatelessWidget {
  const DeviceCard({required this.device, super.key, this.onTap});

  final AcDevice device;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: .11),
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: const Icon(Icons.air_rounded, color: AppColors.accentDeep),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(device.room, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(
                '${device.brand} ${device.model}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 7),
              ConnectionStatus(online: device.isOnline, compact: true),
            ],
          ),
        ),
        if (device.isOnline && device.roomTemperature != null)
          Text(
            '${device.roomTemperature!.round()}°',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w400),
          ),
        const SizedBox(width: 4),
        Icon(
          Icons.chevron_right_rounded,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ],
    ),
  );
}

class QuickActionCard extends StatelessWidget {
  const QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    padding: const EdgeInsets.all(10),
    borderRadius: AppRadius.medium,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: AppColors.accentDeep, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          maxLines: 2,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(height: 1.2),
        ),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44, color: AppColors.accent),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );
}

void showAppSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
      ),
    );
}
