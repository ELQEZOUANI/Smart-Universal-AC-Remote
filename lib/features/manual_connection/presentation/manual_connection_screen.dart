import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/premium_widgets.dart';
import '../../../models/ac_device.dart';
import '../../remote/controllers/ac_controller.dart';
import '../../remote/widgets/remote_unlock_prompt.dart';

class ManualConnectionScreen extends ConsumerStatefulWidget {
  const ManualConnectionScreen({super.key});

  @override
  ConsumerState<ManualConnectionScreen> createState() =>
      _ManualConnectionScreenState();
}

class _ManualConnectionScreenState
    extends ConsumerState<ManualConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Guest Room AC');
  final _ipController = TextEditingController(text: '192.168.1.24');
  final _portController = TextEditingController(text: '8080');
  var _brand = 'LG';
  var _loading = false;

  static const _brands = ['LG', 'Samsung', 'Daikin', 'Midea', 'Gree', 'Other'];

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  String? _validateIp(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter an IP address';
    final parts = value.trim().split('.');
    if (parts.length != 4 ||
        parts.any(
          (part) => int.tryParse(part) == null || int.parse(part) > 255,
        )) {
      return 'Use a valid IPv4 address';
    }
    return null;
  }

  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    if (!ref.read(acControllerProvider).remoteUnlocked) {
      final unlocked = await requestRemoteUnlock(context, ref);
      if (!mounted || !unlocked) return;
    }
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    final id = 'manual-${DateTime.now().millisecondsSinceEpoch}';
    ref
        .read(acControllerProvider.notifier)
        .addDevice(
          AcDevice(
            id: id,
            name: _nameController.text.trim(),
            room: _nameController.text.trim().replaceAll(RegExp(r'\s*AC$'), ''),
            brand: _brand,
            model: 'Smart AC',
            ipAddress: _ipController.text.trim(),
            port: int.parse(_portController.text),
            isOnline: true,
            roomTemperature: 24,
          ),
        );
    showAppSnackBar(context, 'Device connected successfully');
    context.go('/remote');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Connect manually')),
    body: AppPage(
      safeTop: false,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const BouncingScrollPhysics(),
          children: [
            Text(
              'Enter your AC network information.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 26),
            GlassCard(
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'AC Name',
                      prefixIcon: Icon(Icons.label_outline_rounded),
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 2
                        ? 'Enter a device name'
                        : null,
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: _brand,
                    decoration: const InputDecoration(
                      labelText: 'Brand',
                      prefixIcon: Icon(Icons.apartment_rounded),
                    ),
                    items: [
                      for (final brand in _brands)
                        DropdownMenuItem(value: brand, child: Text(brand)),
                    ],
                    onChanged: (value) =>
                        setState(() => _brand = value ?? _brand),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _ipController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'IP Address',
                      hintText: '192.168.1.24',
                      prefixIcon: Icon(Icons.lan_outlined),
                    ),
                    validator: _validateIp,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _portController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      prefixIcon: Icon(Icons.numbers_rounded),
                    ),
                    validator: (value) {
                      final port = int.tryParse(value ?? '');
                      if (port == null || port < 1 || port > 65535) {
                        return 'Enter a port from 1 to 65535';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _connect(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            PrimaryButton(
              label: 'Connect Device',
              icon: Icons.link_rounded,
              loading: _loading,
              onPressed: _connect,
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              label: 'View Connection Guide',
              icon: Icons.menu_book_outlined,
              onPressed: _loading ? null : () => context.push('/guide'),
            ),
          ],
        ),
      ),
    ),
  );
}
