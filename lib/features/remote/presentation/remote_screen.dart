import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/design_tokens.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../models/ac_control_state.dart';
import '../../../models/ac_device.dart';
import '../controllers/ac_controller.dart';
import '../widgets/remote_unlock_prompt.dart';
import '../widgets/temperature_dial.dart';

class RemoteScreen extends ConsumerWidget {
  const RemoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(acControllerProvider);
    final controller = ref.read(acControllerProvider.notifier);
    final device = appState.selectedDevice;
    final control = appState.control;
    if (device == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.alphaBlend(
                  AppColors.accent.withValues(alpha: .09),
                  Theme.of(context).scaffoldBackgroundColor,
                ),
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).scaffoldBackgroundColor,
              ],
              stops: const [0, .46, 1],
            ),
          ),
          child: AppPage(
            maxWidth: 700,
            accentColor: AppColors.cyan,
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                const _RemoteSetupHeader(),
                const SizedBox(height: 28),
                const _RemoteSetupExperience(),
                const SizedBox(height: 20),
                _LuxuryConnectButton(
                  label: 'Find Nearby Devices',
                  icon: Icons.radar_rounded,
                  onPressed: () => context.push('/discovery'),
                ),
                const SizedBox(height: 12),
                _ManualConnectButton(
                  label: 'Connect manually',
                  icon: Icons.lan_outlined,
                  onPressed: () => context.push('/manual-connection'),
                ),
                const SizedBox(height: 16),
                const _ConnectionNote(),
              ],
            ),
          ),
        ),
      );
    }
    if (!appState.remoteUnlocked) {
      return _LockedRemote(
        device: device,
        onUnlock: () => requestRemoteUnlock(context, ref),
        onFindDevice: () => context.push('/discovery'),
      );
    }
    final modeColor = control.mode.color;
    final baseColor = Theme.of(context).scaffoldBackgroundColor;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [0, .34, .72, 1],
            colors: [
              Color.alphaBlend(
                modeColor.withValues(alpha: dark ? .24 : .2),
                baseColor,
              ),
              Color.alphaBlend(
                modeColor.withValues(alpha: dark ? .11 : .09),
                baseColor,
              ),
              baseColor,
              Color.alphaBlend(
                modeColor.withValues(alpha: dark ? .075 : .055),
                baseColor,
              ),
            ],
          ),
        ),
        child: AppPage(
          maxWidth: 700,
          accentColor: modeColor,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              _DeviceHeader(
                device: device,
                modeColor: modeColor,
                onTap: () => _showDeviceSelector(context, ref, modeColor),
              ),
              const SizedBox(height: 14),
              _ClimateConsole(
                device: device,
                control: control,
                onTemperatureChanged: controller.setTemperature,
                onPowerTap: controller.togglePower,
              ),
              const SizedBox(height: 26),
              _SectionTitle(
                eyebrow: 'CLIMATE',
                title: 'Operating mode',
                icon: control.mode.icon,
                color: modeColor,
              ),
              const SizedBox(height: 11),
              AnimatedOpacity(
                opacity: control.isPowered ? 1 : .42,
                duration: AppDuration.normal,
                child: IgnorePointer(
                  ignoring: !control.isPowered,
                  child: _ModeSelector(
                    value: control.mode,
                    onChanged: controller.setMode,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              AnimatedOpacity(
                opacity: control.isPowered ? 1 : .42,
                duration: AppDuration.normal,
                child: IgnorePointer(
                  ignoring: !control.isPowered,
                  child: Column(
                    children: [
                      _ComfortPanel(
                        modeColor: modeColor,
                        fanSpeed: control.fanSpeed,
                        verticalSwing: control.verticalSwing,
                        horizontalSwing: control.horizontalSwing,
                        onFanChanged: controller.setFanSpeed,
                        onVerticalSwing: controller.toggleVerticalSwing,
                        onHorizontalSwing: controller.toggleHorizontalSwing,
                      ),
                      const SizedBox(height: 26),
                      _SectionTitle(
                        eyebrow: 'SHORTCUTS',
                        title: 'Comfort functions',
                        icon: Icons.grid_view_rounded,
                        color: modeColor,
                      ),
                      const SizedBox(height: 11),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.08,
                        children: [
                          _FunctionTile(
                            icon: Icons.schedule_rounded,
                            label: 'Timer',
                            selected: false,
                            color: modeColor,
                            onTap: () => context.push('/timers'),
                          ),
                          _FunctionTile(
                            icon: Icons.eco_rounded,
                            label: 'Eco',
                            selected: control.ecoEnabled,
                            color: modeColor,
                            onTap: () => controller.toggleFunction('eco'),
                          ),
                          _FunctionTile(
                            icon: Icons.bedtime_rounded,
                            label: 'Sleep',
                            selected: control.sleepEnabled,
                            color: modeColor,
                            onTap: () => controller.toggleFunction('sleep'),
                          ),
                          _FunctionTile(
                            icon: Icons.bolt_rounded,
                            label: 'Turbo',
                            selected: control.turboEnabled,
                            color: modeColor,
                            onTap: () => controller.toggleFunction('turbo'),
                          ),
                          _FunctionTile(
                            icon: Icons.lightbulb_rounded,
                            label: 'Light',
                            selected: control.lightEnabled,
                            color: modeColor,
                            onTap: () => controller.toggleFunction('light'),
                          ),
                          _FunctionTile(
                            icon: Icons.volume_off_rounded,
                            label: 'Quiet',
                            selected: control.quietEnabled,
                            color: modeColor,
                            onTap: () => controller.toggleFunction('quiet'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeviceSelector(
    BuildContext context,
    WidgetRef ref,
    Color modeColor,
  ) {
    final state = ref.read(acControllerProvider);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose device',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              for (final device in state.devices)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: modeColor.withValues(alpha: .12),
                    child: Icon(Icons.air_rounded, color: modeColor),
                  ),
                  title: Text(device.room),
                  subtitle: Text('${device.brand} ${device.model}'),
                  trailing: device.id == state.selectedDeviceId
                      ? Icon(Icons.check_circle_rounded, color: modeColor)
                      : null,
                  onTap: () {
                    ref
                        .read(acControllerProvider.notifier)
                        .selectDevice(device.id);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RemoteSetupHeader extends StatelessWidget {
  const _RemoteSetupHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.navyDeep,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: .18)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navyDeep.withValues(alpha: .22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.ac_unit_rounded,
                size: 18,
                color: AppColors.cyan,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'CLIMATE CONCIERGE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.accentDeep,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.35,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text('Remote', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 7),
        Text(
          'A more considered way to feel at home.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: .05,
          ),
        ),
      ],
    );
  }
}

class _RemoteSetupExperience extends StatelessWidget {
  const _RemoteSetupExperience();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.extraLarge),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF16283D), Color(0xFF0A1625)]
              : const [Color(0xFF163554), Color(0xFF091B31)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: .15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: dark ? .42 : .25),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _ConnectionReadinessPill(),
          const SizedBox(height: 22),
          const Center(child: _ClimateEmblem()),
          const SizedBox(height: 24),
          Text(
            'Your ideal climate\nstarts here.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.08,
              letterSpacing: -.9,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Connect a compatible air conditioner to bring temperature, airflow, modes, and timers into one beautifully simple place.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: .72),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          Divider(color: Colors.white.withValues(alpha: .13), height: 1),
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(
                child: _ExperienceDetail(
                  icon: Icons.thermostat_rounded,
                  label: 'Precise\ncomfort',
                ),
              ),
              _DetailDivider(),
              Expanded(
                child: _ExperienceDetail(
                  icon: Icons.air_rounded,
                  label: 'Effortless\nairflow',
                ),
              ),
              _DetailDivider(),
              Expanded(
                child: _ExperienceDetail(
                  icon: Icons.schedule_rounded,
                  label: 'Intuitive\nroutines',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ConnectionReadinessPill extends StatelessWidget {
  const _ConnectionReadinessPill();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.cyan.withValues(alpha: .13),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(color: AppColors.cyan.withValues(alpha: .28)),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _PulseDot(),
        SizedBox(width: 7),
        Text(
          'READY TO CONNECT',
          style: TextStyle(
            color: AppColors.cyan,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.05,
          ),
        ),
      ],
    ),
  );
}

class _PulseDot extends StatelessWidget {
  const _PulseDot();

  @override
  Widget build(BuildContext context) => Container(
    width: 7,
    height: 7,
    decoration: BoxDecoration(
      color: AppColors.cyan,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: AppColors.cyan, blurRadius: 8)],
    ),
  );
}

class _ClimateEmblem extends StatelessWidget {
  const _ClimateEmblem();

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      Container(
        width: 148,
        height: 148,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.cyan.withValues(alpha: .25),
              AppColors.accentDeep.withValues(alpha: .06),
              Colors.transparent,
            ],
            stops: const [0, .52, 1],
          ),
        ),
      ),
      Container(
        width: 104,
        height: 104,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: .06),
          border: Border.all(color: Colors.white.withValues(alpha: .22)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan.withValues(alpha: .2),
              blurRadius: 28,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(
          Icons.ac_unit_rounded,
          color: AppColors.cyan,
          size: 52,
        ),
      ),
    ],
  );
}

class _ExperienceDetail extends StatelessWidget {
  const _ExperienceDetail({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: AppColors.cyan, size: 19),
      const SizedBox(height: 7),
      Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: .72),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
    ],
  );
}

class _DetailDivider extends StatelessWidget {
  const _DetailDivider();

  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 28,
    color: Colors.white.withValues(alpha: .13),
  );
}

class _LuxuryConnectButton extends StatelessWidget {
  const _LuxuryConnectButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 60,
    width: double.infinity,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF3294F5), AppColors.accentDeep],
        ),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentDeep.withValues(alpha: .28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .1,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 19,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ManualConnectButton extends StatelessWidget {
  const _ManualConnectButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          backgroundColor: scheme.surface.withValues(alpha: .5),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: .75)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 9),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _ConnectionNote extends StatelessWidget {
  const _ConnectionNote();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.lock_outline_rounded,
        size: 14,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      const SizedBox(width: 7),
      Text(
        'Private, local connection',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _LockedRemote extends StatelessWidget {
  const _LockedRemote({
    required this.device,
    required this.onUnlock,
    required this.onFindDevice,
  });

  final AcDevice device;
  final Future<bool> Function() onUnlock;
  final VoidCallback onFindDevice;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AppPage(
      maxWidth: 700,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          ScreenHeader(title: 'Remote', subtitle: '${device.room} is ready'),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
            child: Column(
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.accent, AppColors.accentDeep],
                    ),
                    borderRadius: BorderRadius.circular(27),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentDeep.withValues(alpha: .24),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Your climate console is locked',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Watch one rewarded ad to unlock every remote control permanently on this installation.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.air_rounded, color: AppColors.accentDeep),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              device.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              '${device.brand} ${device.model}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const ConnectionStatus(online: true, compact: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Unlock remote',
            icon: Icons.play_circle_fill_rounded,
            onPressed: onUnlock,
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Find another device',
            icon: Icons.radar_rounded,
            onPressed: onFindDevice,
          ),
        ],
      ),
    ),
  );
}

class _DeviceHeader extends StatelessWidget {
  const _DeviceHeader({
    required this.device,
    required this.modeColor,
    required this.onTap,
  });

  final AcDevice device;
  final Color modeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    padding: const EdgeInsets.all(12),
    borderRadius: AppRadius.large,
    color: Theme.of(context).colorScheme.surface.withValues(alpha: .72),
    child: Row(
      children: [
        AnimatedContainer(
          duration: AppDuration.normal,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: modeColor.withValues(alpha: .13),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: modeColor.withValues(alpha: .18)),
          ),
          child: Icon(Icons.air_rounded, color: modeColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      device.room,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                ],
              ),
              Text(
                '${device.brand} ${device.model}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        ConnectionStatus(online: device.isOnline, compact: true),
      ],
    ),
  );
}

class _ClimateConsole extends StatelessWidget {
  const _ClimateConsole({
    required this.device,
    required this.control,
    required this.onTemperatureChanged,
    required this.onPowerTap,
  });

  final AcDevice device;
  final AcControlState control;
  final ValueChanged<int> onTemperatureChanged;
  final VoidCallback onPowerTap;

  @override
  Widget build(BuildContext context) {
    final modeColor = control.mode.color;
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      borderRadius: AppRadius.extraLarge,
      color: scheme.surface.withValues(
        alpha: Theme.of(context).brightness == Brightness.dark ? .72 : .78,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: control.isPowered ? modeColor : scheme.outline,
                        shape: BoxShape.circle,
                        boxShadow: [
                          if (control.isPowered)
                            BoxShadow(
                              color: modeColor.withValues(alpha: .5),
                              blurRadius: 8,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        control.isPowered ? 'CLIMATE ACTIVE' : 'CLIMATE PAUSED',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: control.isPowered
                              ? modeColor
                              : scheme.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.25,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'RANGE  16°—30°',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: .6,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          AnimatedOpacity(
            opacity: control.isPowered ? 1 : .52,
            duration: AppDuration.normal,
            child: TemperatureDial(
              temperature: control.temperature,
              mode: control.mode,
              enabled: control.isPowered,
              onChanged: onTemperatureChanged,
            ),
          ),
          AnimatedOpacity(
            opacity: control.isPowered ? 1 : .42,
            duration: AppDuration.normal,
            child: IgnorePointer(
              ignoring: !control.isPowered,
              child: _TemperatureStepper(
                roomTemperature: device.roomTemperature,
                modeColor: modeColor,
                onDecrease: () => onTemperatureChanged(control.temperature - 1),
                onIncrease: () => onTemperatureChanged(control.temperature + 1),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Divider(
            color: scheme.outlineVariant.withValues(alpha: .55),
            height: 1,
          ),
          const SizedBox(height: 13),
          _PowerStrip(
            powered: control.isPowered,
            mode: control.mode,
            onTap: onPowerTap,
          ),
        ],
      ),
    );
  }
}

class _TemperatureStepper extends StatelessWidget {
  const _TemperatureStepper({
    required this.roomTemperature,
    required this.modeColor,
    required this.onDecrease,
    required this.onIncrease,
  });

  final double? roomTemperature;
  final Color modeColor;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: modeColor.withValues(alpha: .075),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(color: modeColor.withValues(alpha: .13)),
    ),
    child: Row(
      children: [
        _TemperatureButton(
          icon: Icons.remove_rounded,
          label: 'Decrease temperature',
          color: modeColor,
          onTap: onDecrease,
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                'ROOM TEMPERATURE',
                maxLines: 1,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .9,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${roomTemperature?.round() ?? '--'}°C',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        _TemperatureButton(
          icon: Icons.add_rounded,
          label: 'Increase temperature',
          color: modeColor,
          onTap: onIncrease,
        ),
      ],
    ),
  );
}

class _TemperatureButton extends StatelessWidget {
  const _TemperatureButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: IconButton(
      onPressed: onTap,
      icon: Icon(icon),
      iconSize: 23,
      color: color,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(46),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface.withValues(alpha: .8),
        side: BorderSide(color: color.withValues(alpha: .14)),
      ),
    ),
  );
}

class _PowerStrip extends StatelessWidget {
  const _PowerStrip({
    required this.powered,
    required this.mode,
    required this.onTap,
  });

  final bool powered;
  final AcMode mode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = mode.color;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Semantics(
          button: true,
          label: powered ? 'Turn AC off' : 'Turn AC on',
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: AnimatedContainer(
              duration: AppDuration.normal,
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: powered
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color.lerp(color, Colors.white, .18)!, color],
                      )
                    : null,
                color: powered ? null : scheme.surfaceContainerHighest,
                border: Border.all(
                  color: powered
                      ? color.withValues(alpha: .7)
                      : scheme.outlineVariant,
                  width: 1.5,
                ),
                boxShadow: [
                  if (powered)
                    BoxShadow(
                      color: color.withValues(alpha: .32),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                ],
              ),
              child: Icon(
                Icons.power_settings_new_rounded,
                color: powered ? Colors.white : scheme.onSurfaceVariant,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                powered ? mode.activeDescription : 'Air conditioner is off',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 3),
              Text(
                powered ? 'Tap power to pause' : 'Tap power to resume comfort',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        AnimatedContainer(
          duration: AppDuration.normal,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: powered
                ? color.withValues(alpha: .1)
                : scheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: Icon(
            powered ? Icons.energy_savings_leaf_rounded : Icons.pause_rounded,
            color: powered ? color : scheme.onSurfaceVariant,
            size: 18,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.eyebrow,
    required this.title,
    required this.icon,
    required this.color,
  });

  final String eyebrow;
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      AnimatedContainer(
        duration: AppDuration.normal,
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: color, size: 19),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              eyebrow,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    ],
  );
}

class _ModeSelector extends StatelessWidget {
  const _ModeSelector({required this.value, required this.onChanged});

  final AcMode value;
  final ValueChanged<AcMode> onChanged;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(7),
    borderRadius: AppRadius.large,
    color: Theme.of(context).colorScheme.surface.withValues(alpha: .76),
    child: Row(
      children: [
        for (final mode in AcMode.values)
          Expanded(
            child: Semantics(
              button: true,
              selected: value == mode,
              label: '${mode.label} mode',
              child: InkWell(
                onTap: () => onChanged(mode),
                borderRadius: BorderRadius.circular(17),
                child: AnimatedContainer(
                  duration: AppDuration.normal,
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    vertical: 11,
                    horizontal: 2,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    gradient: value == mode
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.lerp(mode.color, Colors.white, .12)!,
                              mode.color,
                            ],
                          )
                        : null,
                    boxShadow: [
                      if (value == mode)
                        BoxShadow(
                          color: mode.color.withValues(alpha: .24),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        mode.icon,
                        size: 21,
                        color: value == mode
                            ? Colors.white
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 5),
                      FittedBox(
                        child: Text(
                          mode.label,
                          style: TextStyle(
                            color: value == mode ? Colors.white : null,
                            fontSize: 10,
                            fontWeight: value == mode
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _ComfortPanel extends StatelessWidget {
  const _ComfortPanel({
    required this.modeColor,
    required this.fanSpeed,
    required this.verticalSwing,
    required this.horizontalSwing,
    required this.onFanChanged,
    required this.onVerticalSwing,
    required this.onHorizontalSwing,
  });

  final Color modeColor;
  final FanSpeed fanSpeed;
  final bool verticalSwing;
  final bool horizontalSwing;
  final ValueChanged<FanSpeed> onFanChanged;
  final VoidCallback onVerticalSwing;
  final VoidCallback onHorizontalSwing;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(16),
    borderRadius: AppRadius.extraLarge,
    color: Theme.of(context).colorScheme.surface.withValues(alpha: .76),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PanelLabel(
          icon: Icons.air_rounded,
          label: 'Fan speed',
          color: modeColor,
        ),
        const SizedBox(height: 12),
        _FanSelector(
          value: fanSpeed,
          color: modeColor,
          onChanged: onFanChanged,
        ),
        const SizedBox(height: 18),
        Divider(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: .55),
        ),
        const SizedBox(height: 12),
        _PanelLabel(
          icon: Icons.waves_rounded,
          label: 'Airflow direction',
          color: modeColor,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ControlTile(
                icon: Icons.swap_vert_rounded,
                label: 'Vertical',
                selected: verticalSwing,
                color: modeColor,
                onTap: onVerticalSwing,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ControlTile(
                icon: Icons.swap_horiz_rounded,
                label: 'Horizontal',
                selected: horizontalSwing,
                color: modeColor,
                onTap: onHorizontalSwing,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _PanelLabel extends StatelessWidget {
  const _PanelLabel({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(width: 8),
      Text(label, style: Theme.of(context).textTheme.titleMedium),
    ],
  );
}

class _FanSelector extends StatelessWidget {
  const _FanSelector({
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final FanSpeed value;
  final Color color;
  final ValueChanged<FanSpeed> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: .5),
      borderRadius: BorderRadius.circular(AppRadius.medium),
    ),
    child: Row(
      children: [
        for (final speed in FanSpeed.values)
          Expanded(
            child: InkWell(
              onTap: () => onChanged(speed),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: AppDuration.fast,
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 1),
                decoration: BoxDecoration(
                  color: value == speed
                      ? color.withValues(alpha: .13)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: value == speed
                      ? Border.all(color: color.withValues(alpha: .2))
                      : null,
                ),
                child: Column(
                  children: [
                    _FanBars(
                      strength: speed.strength,
                      automatic: speed == FanSpeed.auto,
                      color: value == speed
                          ? color
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      child: Text(
                        speed.label,
                        style: TextStyle(
                          color: value == speed ? color : null,
                          fontSize: 9,
                          fontWeight: value == speed
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _FanBars extends StatelessWidget {
  const _FanBars({
    required this.strength,
    required this.automatic,
    required this.color,
  });

  final int strength;
  final bool automatic;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (automatic) {
      return Icon(Icons.auto_awesome_rounded, color: color, size: 17);
    }
    return SizedBox(
      height: 17,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 1; index <= 4; index++)
            AnimatedContainer(
              duration: AppDuration.fast,
              width: 3,
              height: 5.0 + (index * 2.7),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: index <= strength ? color : color.withValues(alpha: .2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ],
      ),
    );
  }
}

class _ControlTile extends StatelessWidget {
  const _ControlTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: AnimatedContainer(
        duration: AppDuration.fast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          color: selected
              ? color.withValues(alpha: .12)
              : Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: .45),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: .25)
                : Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: .45),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: selected
                  ? color
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 21,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
            AnimatedContainer(
              duration: AppDuration.fast,
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: selected
                    ? color
                    : Theme.of(context).colorScheme.outlineVariant,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FunctionTile extends StatelessWidget {
  const _FunctionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    padding: const EdgeInsets.all(9),
    borderRadius: AppRadius.medium,
    color: selected
        ? color.withValues(alpha: .13)
        : Theme.of(context).colorScheme.surface.withValues(alpha: .74),
    child: Stack(
      children: [
        Align(
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                duration: AppDuration.fast,
                scale: selected ? 1.08 : 1,
                child: Icon(
                  icon,
                  size: 23,
                  color: selected
                      ? color
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: selected ? color : null,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 1,
          right: 1,
          child: AnimatedContainer(
            duration: AppDuration.fast,
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: selected ? color : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    ),
  );
}
