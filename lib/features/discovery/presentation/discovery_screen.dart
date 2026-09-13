import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/design_tokens.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../models/ac_device.dart';
import '../../remote/controllers/ac_controller.dart';
import '../../remote/widgets/remote_unlock_prompt.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _radarController;
  Timer? _searchTimer;
  var _searching = true;
  var _unlocking = false;
  String? _connectingIp;

  static const List<(String, String, String, IconData)> _results = [];

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat();
    _beginSearch();
  }

  void _beginSearch() {
    _searchTimer?.cancel();
    setState(() => _searching = true);
    if (!_radarController.isAnimating) _radarController.repeat();
    _searchTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      _radarController.stop();
      setState(() => _searching = false);
    });
  }

  Future<void> _connect(String ip) async {
    if (!ref.read(acControllerProvider).remoteUnlocked) {
      setState(() => _unlocking = true);
      final unlocked = await requestRemoteUnlock(context, ref);
      if (!mounted) return;
      setState(() => _unlocking = false);
      if (!unlocked) return;
    }

    setState(() => _connectingIp = ip);
    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    final match = ref
        .read(acControllerProvider)
        .devices
        .where((d) => d.ipAddress == ip);
    if (match.isNotEmpty) {
      ref.read(acControllerProvider.notifier).selectDevice(match.first.id);
    } else {
      final result = _results.firstWhere((item) => item.$2 == ip);
      ref
          .read(acControllerProvider.notifier)
          .addDevice(
            AcDevice(
              id: '${result.$3.toLowerCase()}-${ip.replaceAll('.', '-')}',
              name: result.$1,
              room: 'My Room',
              brand: result.$3,
              model: 'Smart AC',
              ipAddress: ip,
              port: 8080,
              isOnline: true,
              roomTemperature: 24,
            ),
          );
    }
    context.go('/remote');
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightBackground,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleSpacing: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LOCAL DISCOVERY',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.accentDeep,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            Text('Find your AC', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: .72),
                shape: BoxShape.circle,
                border: Border.all(
                  color: scheme.outlineVariant.withValues(alpha: .62),
                ),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.accentDeep,
                size: 19,
              ),
            ),
          ),
        ],
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(
                AppColors.accent.withValues(alpha: .075),
                Theme.of(context).scaffoldBackgroundColor,
              ),
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: AppPage(
          safeTop: false,
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 34),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              const _NetworkReadinessCard(),
              const SizedBox(height: 22),
              AnimatedSwitcher(
                duration: AppDuration.slow,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _searching
                    ? _SearchAnimation(
                        key: const ValueKey('search'),
                        animation: _radarController,
                      )
                    : _results.isEmpty
                    ? const _NoResultBadge(key: ValueKey('empty'))
                    : _ResultBadge(
                        key: const ValueKey('found'),
                        count: _results.length,
                      ),
              ),
              const SizedBox(height: 18),
              _DiscoveryStatus(
                searching: _searching,
                resultCount: _results.length,
              ),
              const SizedBox(height: 24),
              AnimatedSize(
                duration: AppDuration.slow,
                child: _searching
                    ? const _ScanningHint()
                    : Column(
                        children: [
                          if (_results.isEmpty) ...[
                            _NoDevicesGuide(
                              onRetry: _connectingIp == null
                                  ? _beginSearch
                                  : null,
                              onManual: () =>
                                  context.push('/manual-connection'),
                            ),
                            const SizedBox(height: 14),
                          ],
                          for (final result in _results) ...[
                            _DiscoveryResult(
                              name: result.$1,
                              ip: result.$2,
                              brand: result.$3,
                              connecting: _connectingIp == result.$2,
                              disabled: _connectingIp != null || _unlocking,
                              onConnect: () => _connect(result.$2),
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (_results.isNotEmpty)
                            SecondaryButton(
                              label: 'Search again',
                              icon: Icons.refresh_rounded,
                              onPressed: _connectingIp == null
                                  ? _beginSearch
                                  : null,
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
}

class _NetworkReadinessCard extends StatelessWidget {
  const _NetworkReadinessCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: .76),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .58)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.wifi_rounded,
              color: AppColors.accentDeep,
              size: 21,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Before we scan',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  'Keep your phone and air conditioner on the same Wi-Fi network.',
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
    );
  }
}

class _DiscoveryStatus extends StatelessWidget {
  const _DiscoveryStatus({required this.searching, required this.resultCount});

  final bool searching;
  final int resultCount;

  @override
  Widget build(BuildContext context) {
    final title = searching
        ? 'Searching for nearby devices…'
        : resultCount == 0
        ? 'No compatible devices found'
        : '$resultCount compatible ${resultCount == 1 ? 'device' : 'devices'} found';
    final subtitle = searching
        ? 'Checking your local network securely.'
        : resultCount == 0
        ? 'A few simple checks usually solve this.'
        : 'Choose a device to bring it online.';
    return Column(
      children: [
        Text(
          title,
          key: ValueKey(searching),
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ScanningHint extends StatelessWidget {
  const _ScanningHint();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.accent.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(AppRadius.medium),
    ),
    child: const Row(
      children: [
        Icon(Icons.shield_outlined, color: AppColors.accentDeep, size: 18),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'This scan stays on your private local network.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class _NoDevicesGuide extends StatelessWidget {
  const _NoDevicesGuide({required this.onRetry, required this.onManual});

  final VoidCallback? onRetry;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nothing found yet',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 3),
        Text(
          'Try these quick checks, then scan again.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        const _GuideStep(
          number: '1',
          label: 'Turn on Wi-Fi pairing on your AC.',
        ),
        const SizedBox(height: 9),
        const _GuideStep(
          number: '2',
          label: 'Confirm both devices use the same network.',
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: 'Search again',
          icon: Icons.refresh_rounded,
          onPressed: onRetry,
        ),
        const SizedBox(height: 10),
        SecondaryButton(
          label: 'Connect manually',
          icon: Icons.lan_outlined,
          onPressed: onManual,
        ),
      ],
    ),
  );
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.mist,
          shape: BoxShape.circle,
        ),
        child: Text(
          number,
          style: const TextStyle(
            color: AppColors.accentDeep,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: 9),
      Expanded(child: Text(label)),
    ],
  );
}

class _SearchAnimation extends StatelessWidget {
  const _SearchAnimation({required this.animation, super.key});
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => Container(
    height: 278,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFFFF), Color(0xFFEAF7FD)],
      ),
      borderRadius: BorderRadius.circular(AppRadius.extraLarge),
      border: Border.all(color: AppColors.accent.withValues(alpha: .24)),
      boxShadow: [
        BoxShadow(
          color: AppColors.accentDeep.withValues(alpha: .09),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: AnimatedBuilder(
      animation: animation,
      builder: (context, _) => CustomPaint(
        painter: _RadarPainter(
          progress: animation.value,
          lineColor: AppColors.accent,
          fillColor: AppColors.accent.withValues(alpha: .1),
        ),
        child: Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent.withValues(alpha: .45),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentDeep.withValues(alpha: .13),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Icon(
              Icons.air_rounded,
              size: 36,
              color: AppColors.accentDeep,
            ),
          ),
        ),
      ),
    ),
  );
}

class _RadarPainter extends CustomPainter {
  const _RadarPainter({
    required this.progress,
    required this.lineColor,
    required this.fillColor,
  });
  final double progress;
  final Color lineColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) * .42;
    final fill = Paint()..color = fillColor;
    final stroke = Paint()
      ..color = lineColor.withValues(alpha: .28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final fraction in [.33, .64, .94]) {
      canvas.drawCircle(
        center,
        radius * fraction,
        stroke..color = lineColor.withValues(alpha: .16),
      );
    }
    for (var index = 0; index < 3; index++) {
      final phase = (progress + index / 3) % 1;
      canvas.drawCircle(
        center,
        radius * phase,
        stroke..color = lineColor.withValues(alpha: 1 - phase),
      );
    }
    final sweep = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 1.5,
        colors: [
          lineColor.withValues(alpha: 0),
          lineColor.withValues(alpha: .04),
          lineColor.withValues(alpha: .34),
          lineColor.withValues(alpha: 0),
        ],
        stops: const [.0, .55, .92, 1],
        transform: GradientRotation(progress * math.pi * 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, sweep);
    canvas.drawCircle(center, 44, fill);
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _ResultBadge extends StatelessWidget {
  const _ResultBadge({required this.count, super.key});
  final int count;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 278,
    child: Center(
      child: Container(
        width: 132,
        height: 132,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.success.withValues(alpha: .12),
          border: Border.all(color: AppColors.success.withValues(alpha: .3)),
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 58,
          color: AppColors.success,
        ),
      ),
    ),
  );
}

class _NoResultBadge extends StatelessWidget {
  const _NoResultBadge({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 278,
    child: Center(
      child: Container(
        width: 132,
        height: 132,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: .7),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Icon(
          Icons.wifi_find_rounded,
          size: 50,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ),
  );
}

class _DiscoveryResult extends StatelessWidget {
  const _DiscoveryResult({
    required this.name,
    required this.ip,
    required this.brand,
    required this.connecting,
    required this.disabled,
    required this.onConnect,
  });
  final String name;
  final String ip;
  final String brand;
  final bool connecting;
  final bool disabled;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(15),
    child: Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: AppColors.accent.withValues(alpha: .11),
          ),
          child: const Icon(Icons.air_rounded, color: AppColors.accentDeep),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 3),
              Text(
                '$brand • $ip',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        FilledButton(
          onPressed: disabled ? null : onConnect,
          child: connecting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Connect'),
        ),
      ],
    ),
  );
}
