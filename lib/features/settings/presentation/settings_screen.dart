import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/ads/app_open_ad_service.dart';
import '../../../core/constants/app_info.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../remote/controllers/ac_controller.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final settingsController = ref.read(settingsControllerProvider.notifier);
    final appState = ref.watch(acControllerProvider);
    return Scaffold(
      body: AppPage(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            const ScreenHeader(
              title: 'Settings',
              subtitle: 'A considered space for your comfort.',
              leading: AppBrandIcon(
                key: ValueKey('settings-app-icon'),
                size: 62,
                borderRadius: 20,
              ),
            ),
            const SizedBox(height: 30),
            const _SettingsLabel('GENERAL'),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingTile(
                    icon: Icons.thermostat_rounded,
                    title: 'Temperature Unit',
                    subtitle:
                        settings.temperatureUnit == TemperatureUnit.celsius
                        ? 'Celsius (°C)'
                        : 'Fahrenheit (°F)',
                    onTap: () => _showUnitPicker(context, ref),
                  ),
                  _SettingTile(
                    icon: Icons.air_rounded,
                    title: 'Default Device',
                    subtitle:
                        appState.selectedDevice?.room ?? 'No device selected',
                    onTap: () => appState.devices.isEmpty
                        ? showAppSnackBar(context, 'Add a device first')
                        : _showDevicePicker(context, ref),
                  ),
                  _SettingTile(
                    icon: Icons.vibration_rounded,
                    title: 'Haptic Feedback',
                    trailing: _LuxurySwitch(
                      value: settings.haptics,
                      onChanged: (_) => settingsController.toggleHaptics(),
                    ),
                    onTap: settingsController.toggleHaptics,
                  ),
                  _SettingTile(
                    icon: Icons.link_rounded,
                    title: 'Auto Connect',
                    trailing: _LuxurySwitch(
                      value: settings.autoConnect,
                      onChanged: (_) => settingsController.toggleAutoConnect(),
                    ),
                    onTap: settingsController.toggleAutoConnect,
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SettingsLabel('APPEARANCE'),
            GlassCard(
              padding: EdgeInsets.zero,
              child: _SettingTile(
                icon: Icons.contrast_rounded,
                title: 'Theme',
                subtitle: _themeName(settings.themeMode),
                onTap: () => _showThemePicker(context, ref),
                showDivider: false,
              ),
            ),
            const SizedBox(height: 24),
            const _SettingsLabel('LANGUAGE'),
            const GlassCard(
              padding: EdgeInsets.zero,
              child: _SettingTile(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: 'English',
                showDivider: false,
              ),
            ),
            const SizedBox(height: 24),
            const _SettingsLabel('SUPPORT'),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingTile(
                    icon: Icons.menu_book_outlined,
                    title: 'Connection Guide',
                    onTap: () => context.push('/guide'),
                  ),
                  _SettingTile(
                    icon: Icons.fact_check_outlined,
                    title: 'Supported Devices',
                    onTap: () => _info(
                      context,
                      'Supported devices',
                      'Compatibility varies by model. ${AppInfo.name} is designed for supported Wi-Fi-enabled LG, Samsung, Daikin, Midea, Gree, Haier, Hisense, TCL, Panasonic, and Mitsubishi systems.',
                    ),
                  ),
                  _SettingTile(
                    icon: Icons.mail_outline_rounded,
                    title: 'Contact Us',
                    subtitle: AppInfo.supportEmail,
                    onTap: () => _contactUs(context),
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SettingsLabel('LEGAL'),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable:
                        AppOpenAdService.instance.privacyOptionsRequired,
                    builder: (context, required, child) => required
                        ? _SettingTile(
                            icon: Icons.ads_click_rounded,
                            title: 'Ad privacy choices',
                            subtitle: 'Manage your advertising consent',
                            onTap: AppOpenAdService.instance.showPrivacyOptions,
                          )
                        : const SizedBox.shrink(),
                  ),
                  _SettingTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'View the published policy',
                    onTap: () => context.push('/privacy-policy'),
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Image.asset(
                    'assets/branding/appicon.png',
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppInfo.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'DESIGNED FOR EVERYDAY COMFORT  •  VERSION 1.0.0',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.brass,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .7,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _themeName(ThemeMode mode) => switch (mode) {
    ThemeMode.system => 'System',
    ThemeMode.light => 'Light',
    ThemeMode.dark => 'Dark',
  };

  Future<void> _contactUs(BuildContext context) async {
    final email = Uri(
      scheme: 'mailto',
      path: AppInfo.supportEmail,
      queryParameters: {
        'subject': 'Contact ${AppInfo.name}',
        'body':
            'Hello,\n\nAC brand and model:\n\nHow can we help?\n\n'
            'Please do not include Wi-Fi passwords or other credentials.',
      },
    );
    final opened = await _launchExternal(email);
    if (!opened && context.mounted) {
      showAppSnackBar(
        context,
        'Could not open your email app. Contact ${AppInfo.supportEmail}.',
      );
    }
  }

  Future<bool> _launchExternal(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(settingsControllerProvider).themeMode;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose theme',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              RadioGroup<ThemeMode>(
                groupValue: current,
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setTheme(value);
                  }
                  Navigator.pop(context);
                },
                child: Column(
                  children: [
                    for (final mode in ThemeMode.values)
                      RadioListTile<ThemeMode>(
                        value: mode,
                        title: Text(_themeName(mode)),
                        secondary: Icon(switch (mode) {
                          ThemeMode.system => Icons.brightness_auto_rounded,
                          ThemeMode.light => Icons.light_mode_rounded,
                          ThemeMode.dark => Icons.dark_mode_rounded,
                        }),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnitPicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(settingsControllerProvider).temperatureUnit;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Temperature unit',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              RadioGroup<TemperatureUnit>(
                groupValue: current,
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(settingsControllerProvider.notifier)
                        .setUnit(value);
                  }
                  Navigator.pop(context);
                },
                child: Column(
                  children: [
                    for (final unit in TemperatureUnit.values)
                      RadioListTile<TemperatureUnit>(
                        value: unit,
                        title: Text(
                          unit == TemperatureUnit.celsius
                              ? 'Celsius (°C)'
                              : 'Fahrenheit (°F)',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDevicePicker(BuildContext context, WidgetRef ref) {
    final state = ref.read(acControllerProvider);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Default device',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              RadioGroup<String>(
                groupValue: state.selectedDeviceId,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(acControllerProvider.notifier).selectDevice(value);
                  }
                  Navigator.pop(context);
                },
                child: Column(
                  children: [
                    for (final device in state.devices)
                      RadioListTile<String>(
                        value: device.id,
                        title: Text(device.room),
                        subtitle: Text('${device.brand} ${device.model}'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _info(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _SettingsLabel extends StatelessWidget {
  const _SettingsLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 0, 6, 9),
    child: Text(
      label,
      style: const TextStyle(
        color: AppColors.brass,
        fontWeight: FontWeight.w800,
        fontSize: 11.5,
        letterSpacing: 1.5,
      ),
    ),
  );
}

class _LuxurySwitch extends StatelessWidget {
  const _LuxurySwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Switch(
    value: value,
    onChanged: onChanged,
    activeThumbColor: Colors.white,
    activeTrackColor: AppColors.navy,
    inactiveThumbColor: Theme.of(context).colorScheme.surface,
    inactiveTrackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    trackOutlineColor: WidgetStatePropertyAll(
      value
          ? Colors.transparent
          : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .65),
    ),
  );
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = true,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        minTileHeight: 72,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: AppColors.accent.withValues(alpha: .12),
            border: Border.all(color: AppColors.accent.withValues(alpha: .08)),
          ),
          child: Icon(icon, size: 21, color: AppColors.accentDeep),
        ),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: subtitle == null
            ? null
            : Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
        trailing:
            trailing ??
            (onTap == null
                ? null
                : Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: .72),
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )),
        onTap: onTap,
      ),
      if (showDivider) const Divider(height: 1, indent: 80, endIndent: 18),
    ],
  );
}
