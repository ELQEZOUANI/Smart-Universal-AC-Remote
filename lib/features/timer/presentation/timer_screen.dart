import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/design_tokens.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../models/clima_timer.dart';
import '../../remote/controllers/ac_controller.dart';

class TimerScreen extends ConsumerStatefulWidget {
  const TimerScreen({super.key});

  @override
  ConsumerState<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends ConsumerState<TimerScreen> {
  var _quickMinutes = 60;
  var _hours = 1;
  var _minutes = 0;

  void _startTimer({bool custom = false}) {
    final totalMinutes = custom ? (_hours * 60) + _minutes : _quickMinutes;
    if (totalMinutes == 0) {
      showAppSnackBar(context, 'Choose a duration greater than zero');
      return;
    }
    final now = DateTime.now().add(Duration(minutes: totalMinutes));
    final label =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    ref
        .read(acControllerProvider.notifier)
        .addTimer(
          ClimaTimer(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            time: label,
            action: 'Turn Off',
            detail: 'In ${_durationLabel(totalMinutes)}',
          ),
        );
    showAppSnackBar(context, 'Timer set for ${_durationLabel(totalMinutes)}');
  }

  String _durationLabel(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remainder = minutes % 60;
    return remainder == 0 ? '$hours hr' : '$hours hr $remainder min';
  }

  Future<void> _editTimer(ClimaTimer timer) async {
    final parts = timer.time.split(':');
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
    );
    if (selected == null || !mounted) return;
    ref.read(acControllerProvider.notifier)
      ..removeTimer(timer.id)
      ..addTimer(
        ClimaTimer(
          id: timer.id,
          time:
              '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}',
          action: timer.action,
          detail: timer.detail,
          enabled: timer.enabled,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final timers = ref.watch(acControllerProvider).timers;
    return Scaffold(
      appBar: AppBar(title: const Text('Timers')),
      body: AppPage(
        safeTop: false,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            const AppSectionHeader(title: 'Quick Timer'),
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Turn off after',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in [30, 60, 120, 240])
                        ChoiceChip(
                          label: Text(_durationLabel(option)),
                          selected: _quickMinutes == option,
                          onSelected: (_) =>
                              setState(() => _quickMinutes = option),
                          selectedColor: AppColors.accent.withValues(
                            alpha: .16,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'Start Quick Timer',
                    icon: Icons.play_arrow_rounded,
                    onPressed: _startTimer,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const AppSectionHeader(title: 'Custom Timer'),
            const SizedBox(height: 10),
            GlassCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _TimeSelector(
                          label: 'Hours',
                          value: _hours,
                          max: 23,
                          onChanged: (value) => setState(() => _hours = value),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(13, 0, 13, 3),
                        child: Text(
                          ':',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                      ),
                      Expanded(
                        child: _TimeSelector(
                          label: 'Minutes',
                          value: _minutes,
                          max: 59,
                          step: 5,
                          onChanged: (value) =>
                              setState(() => _minutes = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'Start Timer',
                    icon: Icons.schedule_rounded,
                    onPressed: () => _startTimer(custom: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            AppSectionHeader(
              title: 'Scheduled Timers',
              action: '${timers.length} total',
            ),
            const SizedBox(height: 10),
            if (timers.isEmpty)
              const GlassCard(
                child: EmptyState(
                  icon: Icons.schedule_outlined,
                  title: 'No timers yet',
                  message: 'Create a timer to automate your comfort.',
                ),
              )
            else
              for (final timer in timers) ...[
                _TimerCard(
                  timer: timer,
                  onToggle: () => ref
                      .read(acControllerProvider.notifier)
                      .toggleTimer(timer.id),
                  onEdit: () => _editTimer(timer),
                  onDelete: () => ref
                      .read(acControllerProvider.notifier)
                      .removeTimer(timer.id),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _TimeSelector extends StatelessWidget {
  const _TimeSelector({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });
  final String label;
  final int value;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        label,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<int>(
        initialValue: value,
        alignment: Alignment.center,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        items: [
          for (var number = 0; number <= max; number += step)
            DropdownMenuItem(
              value: number,
              child: Text(number.toString().padLeft(2, '0')),
            ),
        ],
        onChanged: (value) => onChanged(value ?? 0),
      ),
    ],
  );
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({
    required this.timer,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });
  final ClimaTimer timer;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(15),
    child: Row(
      children: [
        Expanded(
          child: AnimatedOpacity(
            duration: AppDuration.fast,
            opacity: timer.enabled ? 1 : .45,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timer.time,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  [timer.action, timer.detail].whereType<String>().join(' • '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          tooltip: 'Timer actions',
          onPressed: () => _showActions(context),
          icon: const Icon(Icons.more_horiz_rounded),
        ),
        Switch(value: timer.enabled, onChanged: (_) => onToggle()),
      ],
    ),
  );

  void _showActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit timer'),
              onTap: () {
                Navigator.pop(context);
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
              ),
              title: const Text(
                'Delete timer',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
