import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/app_open_ad_service.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../controllers/ac_controller.dart';

/// Requests an explicit rewarded-ad opt-in and persists the remote entitlement.
Future<bool> requestRemoteUnlock(BuildContext context, WidgetRef ref) async {
  if (ref.read(acControllerProvider).remoteUnlocked) return true;

  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const _RemoteUnlockDialog(),
  );
  if (accepted != true || !context.mounted) return false;

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _PreparingRewardDialog(),
  );
  final earned = await AppOpenAdService.instance.showRewardedRemoteUnlock(
    onRewardEarned: () =>
        ref.read(acControllerProvider.notifier).unlockRemote(),
  );
  if (!context.mounted) return false;
  Navigator.of(context, rootNavigator: true).pop();

  if (earned) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Remote unlocked permanently.')),
    );
    return true;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'The reward was not completed. Your remote is still locked.',
      ),
    ),
  );
  return false;
}

class _RemoteUnlockDialog extends StatelessWidget {
  const _RemoteUnlockDialog();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      contentPadding: const EdgeInsets.fromLTRB(22, 24, 22, 10),
      actionsPadding: const EdgeInsets.fromLTRB(22, 4, 22, 20),
      icon: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.accent, AppColors.accentDeep],
          ),
          borderRadius: BorderRadius.circular(21),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentDeep.withValues(alpha: .24),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(
          Icons.lock_open_rounded,
          color: Colors.white,
          size: 29,
        ),
      ),
      title: const Text('Unlock your remote', textAlign: TextAlign.center),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Watch one rewarded ad to permanently unlock temperature, modes, fan, timers, and comfort controls on this installation.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            const _RewardBenefit(
              icon: Icons.workspace_premium_rounded,
              label: 'One-time unlock',
            ),
            const SizedBox(height: 9),
            const _RewardBenefit(
              icon: Icons.all_inclusive_rounded,
              label: 'No repeat ad for remote access',
            ),
            const SizedBox(height: 14),
            Text(
              'You may close the ad, but access unlocks only after the reward is earned.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: PrimaryButton(
            label: 'Watch ad & unlock',
            icon: Icons.play_circle_fill_rounded,
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
        ),
      ],
    );
  }
}

class _RewardBenefit extends StatelessWidget {
  const _RewardBenefit({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const SizedBox(width: 8),
      Icon(icon, color: AppColors.accentDeep, size: 20),
      const SizedBox(width: 9),
      Flexible(
        child: Text(label, style: Theme.of(context).textTheme.labelLarge),
      ),
    ],
  );
}

class _PreparingRewardDialog extends StatelessWidget {
  const _PreparingRewardDialog();

  @override
  Widget build(BuildContext context) => const PopScope(
    canPop: false,
    child: AlertDialog(
      content: Row(
        children: [
          SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(width: 18),
          Expanded(child: Text('Preparing your unlock…')),
        ],
      ),
    ),
  );
}
