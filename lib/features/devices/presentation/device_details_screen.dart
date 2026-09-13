import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/design_tokens.dart';
import '../../../core/constants/app_info.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../../../models/ac_device.dart';
import '../../remote/controllers/ac_controller.dart';

class DeviceDetailsScreen extends ConsumerWidget {
  const DeviceDetailsScreen({required this.deviceId, super.key});
  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(acControllerProvider).devices;
    final matches = devices.where((device) => device.id == deviceId);
    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.device_unknown_rounded,
          title: 'Device not found',
          message: 'This device may have been removed.',
        ),
      );
    }
    final device = matches.first;
    final controller = ref.read(acControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Device Details')),
      body: AppPage(
        safeTop: false,
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 30),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(AppRadius.large),
                    ),
                    child: const Icon(
                      Icons.air_rounded,
                      color: AppColors.accentDeep,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    device.name,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 7),
                  ConnectionStatus(online: device.isOnline),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Column(
                children: [
                  _DetailRow(label: 'Room', value: device.room),
                  _DetailRow(label: 'Brand', value: device.brand),
                  _DetailRow(label: 'Model', value: device.model),
                  _DetailRow(label: 'IP Address', value: device.ipAddress),
                  _DetailRow(
                    label: 'Port',
                    value: '${device.port}',
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Open Remote',
              icon: Icons.ac_unit_rounded,
              onPressed: () {
                controller.selectDevice(device.id);
                context.go('/remote');
              },
            ),
            const SizedBox(height: 18),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.edit_outlined,
                    title: 'Rename Device',
                    onTap: () => _editText(
                      context,
                      title: 'Rename device',
                      initialValue: device.name,
                      onSave: (value) =>
                          controller.renameDevice(device.id, value),
                    ),
                  ),
                  _ActionTile(
                    icon: Icons.meeting_room_outlined,
                    title: 'Change Room',
                    onTap: () => _editText(
                      context,
                      title: 'Change room',
                      initialValue: device.room,
                      onSave: (value) =>
                          controller.changeRoom(device.id, value),
                    ),
                  ),
                  _ActionTile(
                    icon: Icons.refresh_rounded,
                    title: 'Reconnect',
                    onTap: () {
                      controller.reconnect(device.id);
                      showAppSnackBar(context, 'Connection restored');
                    },
                  ),
                  _ActionTile(
                    icon: Icons.delete_outline_rounded,
                    title: 'Remove Device',
                    destructive: true,
                    showDivider: false,
                    onTap: () => _confirmRemove(context, device, controller),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editText(
    BuildContext context, {
    required String title,
    required String initialValue,
    required ValueChanged<String> onSave,
  }) async {
    final textController = TextEditingController(text: initialValue);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: textController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, textController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    textController.dispose();
    if (value != null && value.isNotEmpty) onSave(value);
  }

  Future<void> _confirmRemove(
    BuildContext context,
    AcDevice device,
    AcController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
        title: const Text('Remove device?'),
        content: Text(
          '${device.name} will be removed from ${AppInfo.name}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      controller.removeDevice(device.id);
      context.go('/devices');
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      if (showDivider) const Divider(height: 1),
    ],
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.destructive = false,
    this.showDivider = true,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool destructive;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ListTile(
        leading: Icon(icon, color: destructive ? AppColors.danger : null),
        title: Text(
          title,
          style: TextStyle(color: destructive ? AppColors.danger : null),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
      if (showDivider) const Divider(height: 1, indent: 56),
    ],
  );
}
