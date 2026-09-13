import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ads/app_open_ad_service.dart';
import '../../../core/constants/design_tokens.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../domain/repair_models.dart';
import 'controllers/repair_controller.dart';

class RepairHomeScreen extends ConsumerStatefulWidget {
  const RepairHomeScreen({super.key});

  @override
  ConsumerState<RepairHomeScreen> createState() => _RepairHomeScreenState();
}

class _RepairHomeScreenState extends ConsumerState<RepairHomeScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final repair = ref.watch(repairControllerProvider);
    final brand = ref
        .watch(brandRepositoryProvider)
        .byId(repair.selectedBrandId);
    final categories = _categories
        .where(
          (item) =>
              _query.isEmpty ||
              item.label.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      extendBody: true,
      body: AppPage(
        maxWidth: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 128),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            ScreenHeader(
              title: 'Online brand guides',
              subtitle:
                  'Setup, care, and repair help for the AC brand you own.',
              trailing: IconButton.filled(
                tooltip: 'Maintenance checklist',
                onPressed: () => context.push('/repair/maintenance'),
                icon: const Icon(Icons.checklist_rounded),
              ),
            ),
            const SizedBox(height: 20),
            _RepairHero(
              onPickBrand: () => _pickBrand(context),
              onDiagnose: () => _openWithInterstitial('/repair/diagnosis'),
            ),
            const SizedBox(height: 18),
            _BrandSelector(value: brand, onTap: () => _pickBrand(context)),
            const SizedBox(height: 16),
            TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search brands, setup, or care',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: .8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  borderSide: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outlineVariant.withValues(alpha: .55),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              brand == null ? 'Explore popular guides' : '${brand.name} guides',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              brand == null
                  ? 'Choose a brand anytime to personalise your guide library.'
                  : 'Helpful setup, care, and repair topics for your ${brand.name} air conditioner.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final count = constraints.maxWidth > 620 ? 3 : 2;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: count,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 112,
                  ),
                  itemBuilder: (context, index) => _CategoryCard(
                    category: categories[index],
                    onTap: () {
                      if (categories[index] == RepairCategory.errorCode) {
                        context.push('/repair/error-code');
                      } else if (categories[index] ==
                          RepairCategory.maintenance) {
                        context.push('/repair/maintenance');
                      } else {
                        context.push(
                          '/repair/diagnosis',
                          extra: categories[index],
                        );
                      }
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            _SafetyNote(onTap: () => context.push('/repair/maintenance')),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBrand(BuildContext context) async {
    final repository = ref.read(brandRepositoryProvider);
    final picked = await showModalBottomSheet<AcBrand>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _BrandPicker(brands: repository.brands),
    );
    if (picked != null) {
      ref
          .read(repairControllerProvider.notifier)
          .selectBrand(picked.id == 'other' ? null : picked.id);
    }
  }

  Future<void> _openWithInterstitial(String location) async {
    await AppOpenAdService.instance.showInterstitialForNavigation();
    if (mounted) context.push(location);
  }
}

class _RepairHero extends StatelessWidget {
  const _RepairHero({required this.onPickBrand, required this.onDiagnose});

  final VoidCallback onPickBrand;
  final VoidCallback onDiagnose;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.navy, AppColors.navyDeep],
      ),
      borderRadius: BorderRadius.circular(AppRadius.extraLarge),
      boxShadow: [
        BoxShadow(
          color: AppColors.navyDeep.withValues(alpha: .24),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.handyman_rounded, color: AppColors.cyan, size: 16),
              SizedBox(width: 6),
              Text(
                'ONLINE BRAND GUIDES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Guidance tailored\nto your air conditioner.',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose your AC brand to explore setup, care, and repair guidance in one easy-to-follow library.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white70, height: 1.4),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: onPickBrand,
                icon: const Icon(Icons.factory_outlined),
                label: const Text('Choose a brand'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.navyDeep,
                  minimumSize: const Size(0, 50),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onDiagnose,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Diagnostic'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cyan,
                  backgroundColor: Colors.transparent,
                  side: BorderSide(
                    color: AppColors.cyan.withValues(alpha: .72),
                  ),
                  minimumSize: const Size(0, 50),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _BrandSelector extends StatelessWidget {
  const _BrandSelector({required this.value, required this.onTap});
  final AcBrand? value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(
            Icons.factory_outlined,
            color: AppColors.accentDeep,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR AC BRAND',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value?.name ?? 'Choose your brand',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        const Icon(Icons.expand_more_rounded),
      ],
    ),
  );
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});
  final RepairCategory category;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(category.icon, color: AppColors.accentDeep, size: 20),
        ),
        const Spacer(),
        Text(
          category.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
      ],
    ),
  );
}

class _SafetyNote extends StatelessWidget {
  const _SafetyNote({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GlassCard(
    onTap: onTap,
    color: AppColors.warning.withValues(alpha: .1),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.shield_outlined, color: AppColors.warning),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Safety first',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'This tool only suggests safe checks. Refrigerant, electrical, and internal repairs require a qualified HVAC technician.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(height: 1.35),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _BrandPicker extends StatefulWidget {
  const _BrandPicker({required this.brands});
  final List<AcBrand> brands;
  @override
  State<_BrandPicker> createState() => _BrandPickerState();
}

class _BrandPickerState extends State<_BrandPicker> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final visible = widget.brands
        .where(
          (brand) => brand.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose your AC brand',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              onChanged: (value) => setState(() => query = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Search brands',
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: visible.length,
                itemBuilder: (_, index) => ListTile(
                  leading: const Icon(Icons.factory_outlined),
                  title: Text(visible[index].name),
                  onTap: () => Navigator.pop(context, visible[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _categories = <RepairCategory>[
  RepairCategory.notCooling,
  RepairCategory.notHeating,
  RepairCategory.notStarting,
  RepairCategory.leakingWater,
  RepairCategory.makingNoise,
  RepairCategory.weakAirflow,
  RepairCategory.badSmell,
  RepairCategory.remote,
  RepairCategory.indoorUnit,
  RepairCategory.outdoorUnit,
  RepairCategory.compressor,
  RepairCategory.fan,
  RepairCategory.sensor,
  RepairCategory.wifi,
  RepairCategory.maintenance,
  RepairCategory.errorCode,
];
