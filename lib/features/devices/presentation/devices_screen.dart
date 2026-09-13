import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/premium_widgets.dart';
import '../../remote/controllers/ac_controller.dart';

class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(acControllerProvider).devices;
    return Scaffold(
      body: AppPage(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  ScreenHeader(
                    title: 'My Devices',
                    subtitle: '${devices.length} air conditioners',
                    trailing: IconButton.filled(
                      tooltip: 'Add device',
                      onPressed: () => context.push('/discovery'),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            if (devices.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.air_rounded,
                  title: 'No devices',
                  message: 'Discover or manually add an air conditioner.',
                ),
              )
            else
              SliverLayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.crossAxisExtent > 620 ? 2 : 1;
                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      mainAxisExtent: 120,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final device = devices[index];
                      return DeviceCard(
                        device: device,
                        onTap: () => context.push('/devices/${device.id}'),
                      );
                    }, childCount: devices.length),
                  );
                },
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SecondaryButton(
                  label: 'Add Device',
                  icon: Icons.add_rounded,
                  onPressed: () => context.push('/discovery'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
