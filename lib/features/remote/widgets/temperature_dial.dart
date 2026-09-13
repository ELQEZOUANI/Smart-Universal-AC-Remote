import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/design_tokens.dart';
import '../../../models/ac_control_state.dart';

class TemperatureDial extends StatelessWidget {
  const TemperatureDial({
    required this.temperature,
    required this.mode,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final int temperature;
  final AcMode mode;
  final bool enabled;
  final ValueChanged<int> onChanged;

  void _handlePosition(Offset position, Size size) {
    if (!enabled) return;
    final center = Offset(size.width / 2, size.height / 2);
    final vector = position - center;
    var angle = math.atan2(vector.dy, vector.dx);
    const start = math.pi * .72;
    const sweep = math.pi * 1.56;
    if (angle < start) angle += math.pi * 2;
    final progress = ((angle - start) / sweep).clamp(0.0, 1.0);
    onChanged(16 + (progress * 14).round());
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = math.min(constraints.maxWidth, 310.0);
      final scheme = Theme.of(context).colorScheme;
      final dark = Theme.of(context).brightness == Brightness.dark;
      return Semantics(
        label: 'Temperature $temperature degrees, ${mode.label} mode',
        value: '$temperature degrees Celsius',
        enabled: enabled,
        child: SizedBox.square(
          dimension: size,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) =>
                _handlePosition(details.localPosition, Size.square(size)),
            onTapUp: (details) =>
                _handlePosition(details.localPosition, Size.square(size)),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 16, end: temperature.toDouble()),
              duration: AppDuration.normal,
              curve: Curves.easeOutCubic,
              builder: (context, animatedTemperature, _) => CustomPaint(
                painter: _DialPainter(
                  progress: (animatedTemperature - 16) / 14,
                  enabled: enabled,
                  modeColor: mode.color,
                  trackColor: scheme.outlineVariant,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: AppDuration.slow,
                      curve: Curves.easeOutCubic,
                      width: size * .63,
                      height: size * .63,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(-.2, -.3),
                          radius: .95,
                          colors: [
                            Color.alphaBlend(
                              mode.color.withValues(
                                alpha: enabled ? .075 : .02,
                              ),
                              scheme.surface,
                            ),
                            scheme.surface.withValues(alpha: dark ? .94 : .98),
                          ],
                        ),
                        border: Border.all(
                          color: enabled
                              ? mode.color.withValues(alpha: .22)
                              : scheme.outlineVariant.withValues(alpha: .55),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: mode.color.withValues(
                              alpha: enabled ? (dark ? .18 : .14) : .02,
                            ),
                            blurRadius: 44,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: dark ? .26 : .06,
                            ),
                            blurRadius: 22,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: AppDuration.normal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: mode.color.withValues(
                                alpha: enabled ? .12 : .05,
                              ),
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  mode.icon,
                                  size: 13,
                                  color: enabled
                                      ? mode.color
                                      : scheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 5),
                                AnimatedSwitcher(
                                  duration: AppDuration.fast,
                                  child: Text(
                                    enabled ? mode.label.toUpperCase() : 'OFF',
                                    key: ValueKey(enabled ? mode : 'off'),
                                    style: TextStyle(
                                      color: enabled
                                          ? mode.color
                                          : scheme.onSurfaceVariant,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: size * .025),
                          AnimatedSwitcher(
                            duration: AppDuration.normal,
                            transitionBuilder: (child, animation) =>
                                FadeTransition(
                                  opacity: animation,
                                  child: ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  ),
                                ),
                            child: Text.rich(
                              TextSpan(
                                text: '$temperature',
                                children: [
                                  TextSpan(
                                    text: '°',
                                    style: TextStyle(
                                      fontSize: size * .085,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                              key: ValueKey(temperature),
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(
                                    height: .95,
                                    fontSize: size * .205,
                                    color: enabled
                                        ? scheme.onSurface
                                        : scheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'TARGET TEMPERATURE',
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 8,
                              letterSpacing: 1.15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      left: size * .12,
                      bottom: size * .065,
                      child: _RangeLabel(
                        label: '16°',
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Positioned(
                      right: size * .12,
                      bottom: size * .065,
                      child: _RangeLabel(
                        label: '30°',
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _RangeLabel extends StatelessWidget {
  const _RangeLabel({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
  );
}

class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.progress,
    required this.enabled,
    required this.modeColor,
    required this.trackColor,
  });

  final double progress;
  final bool enabled;
  final Color modeColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width * .41;
    const start = math.pi * .72;
    const sweep = math.pi * 1.56;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..color = trackColor.withValues(alpha: .55)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7;
    final activePaint = Paint()
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + sweep,
        colors: [
          Color.lerp(modeColor, Colors.white, .32)!,
          modeColor,
          Color.lerp(modeColor, Colors.black, .08)!,
        ],
        transform: const GradientRotation(start),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8;

    canvas.drawArc(rect, start, sweep, false, trackPaint);
    if (enabled) {
      canvas.drawArc(rect, start, sweep * progress, false, activePaint);
    }

    for (var index = 0; index <= 42; index++) {
      final tickProgress = index / 42;
      final angle = start + (sweep * tickProgress);
      final active = enabled && tickProgress <= progress;
      final outer =
          center + Offset(math.cos(angle), math.sin(angle)) * (radius + 18);
      final inner =
          center +
          Offset(math.cos(angle), math.sin(angle)) *
              (radius + (index % 7 == 0 ? 10 : 13));
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = active
              ? modeColor.withValues(alpha: .66)
              : trackColor.withValues(alpha: .55)
          ..strokeWidth = index % 7 == 0 ? 2 : 1
          ..strokeCap = StrokeCap.round,
      );
    }

    if (enabled) {
      final knobAngle = start + sweep * progress;
      final knob =
          center + Offset(math.cos(knobAngle), math.sin(knobAngle)) * radius;
      canvas.drawCircle(
        knob,
        12,
        Paint()..color = modeColor.withValues(alpha: .16),
      );
      canvas.drawCircle(knob, 6.5, Paint()..color = Colors.white);
      canvas.drawCircle(
        knob,
        6.5,
        Paint()
          ..color = modeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.enabled != enabled ||
      oldDelegate.modeColor != modeColor ||
      oldDelegate.trackColor != trackColor;
}

extension AcModeUi on AcMode {
  String get label => switch (this) {
    AcMode.auto => 'Auto',
    AcMode.cool => 'Cool',
    AcMode.heat => 'Heat',
    AcMode.dry => 'Dry',
    AcMode.fan => 'Fan',
  };

  String get activeDescription => switch (this) {
    AcMode.auto => 'Adapting automatically',
    AcMode.cool => 'Cooling the room',
    AcMode.heat => 'Warming the room',
    AcMode.dry => 'Reducing humidity',
    AcMode.fan => 'Circulating fresh air',
  };

  IconData get icon => switch (this) {
    AcMode.auto => Icons.auto_awesome_rounded,
    AcMode.cool => Icons.ac_unit_rounded,
    AcMode.heat => Icons.wb_sunny_rounded,
    AcMode.dry => Icons.water_drop_outlined,
    AcMode.fan => Icons.air_rounded,
  };

  Color get color => switch (this) {
    AcMode.auto => const Color(0xFF7567F8),
    AcMode.cool => const Color(0xFF168DFF),
    AcMode.heat => const Color(0xFFFF8A3D),
    AcMode.dry => const Color(0xFF6675E8),
    AcMode.fan => const Color(0xFF20B997),
  };
}

extension FanSpeedUi on FanSpeed {
  String get label => switch (this) {
    FanSpeed.auto => 'Auto',
    FanSpeed.low => 'Low',
    FanSpeed.medium => 'Medium',
    FanSpeed.high => 'High',
    FanSpeed.turbo => 'Turbo',
  };

  int get strength => switch (this) {
    FanSpeed.auto => 3,
    FanSpeed.low => 1,
    FanSpeed.medium => 2,
    FanSpeed.high => 3,
    FanSpeed.turbo => 4,
  };
}
