import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/design_tokens.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../domain/repair_models.dart';
import 'controllers/repair_controller.dart';

class ErrorCodeLookupScreen extends ConsumerStatefulWidget {
  const ErrorCodeLookupScreen({super.key});
  @override
  ConsumerState<ErrorCodeLookupScreen> createState() =>
      _ErrorCodeLookupScreenState();
}

class _ErrorCodeLookupScreenState extends ConsumerState<ErrorCodeLookupScreen> {
  final _code = TextEditingController();
  ErrorCode? _result;
  var _searched = false;
  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brandRepo = ref.watch(brandRepositoryProvider);
    final repair = ref.watch(repairControllerProvider);
    final brand = brandRepo.byId(repair.selectedBrandId);
    return Scaffold(
      body: AppPage(
        maxWidth: 680,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/repair'),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Error code lookup',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Only verified manufacturer-specific entries are shown. Unknown codes are never guessed.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            GlassCard(
              onTap: _chooseBrand,
              child: Row(
                children: [
                  const Icon(
                    Icons.factory_outlined,
                    color: AppColors.accentDeep,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Brand', style: TextStyle(fontSize: 12)),
                        Text(
                          brand?.name ?? 'Choose a brand',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.expand_more_rounded),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _lookup(),
              decoration: const InputDecoration(
                labelText: 'Error code',
                hintText: 'Example: U4, CH05',
                prefixIcon: Icon(Icons.qr_code_2_rounded),
              ),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Look up code',
              icon: Icons.search_rounded,
              onPressed: _lookup,
            ),
            if (_searched) ...[
              const SizedBox(height: 20),
              _result == null
                  ? _UnsupportedCode(
                      onDiagnose: () => context.go('/repair/diagnosis'),
                    )
                  : _CodeResult(code: _result!),
            ],
          ],
        ),
      ),
    );
  }

  void _lookup() {
    final id = ref.read(repairControllerProvider).selectedBrandId;
    setState(() {
      _searched = true;
      _result = id == null
          ? null
          : ref
                .read(errorCodeRepositoryProvider)
                .find(brandId: id, code: _code.text);
    });
  }

  Future<void> _chooseBrand() async {
    final brands = ref.read(brandRepositoryProvider).brands;
    final selected = await showModalBottomSheet<AcBrand>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.only(bottom: 22),
          children: [
            for (final brand in brands)
              ListTile(
                title: Text(brand.name),
                onTap: () => Navigator.pop(context, brand),
              ),
          ],
        ),
      ),
    );
    if (selected != null) {
      ref
          .read(repairControllerProvider.notifier)
          .selectBrand(selected.id == 'other' ? null : selected.id);
    }
  }
}

class _UnsupportedCode extends StatelessWidget {
  const _UnsupportedCode({required this.onDiagnose});
  final VoidCallback onDiagnose;
  @override
  Widget build(BuildContext context) => GlassCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.info_outline_rounded,
          color: AppColors.accentDeep,
          size: 30,
        ),
        const SizedBox(height: 12),
        Text(
          'No verified information available',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'We do not currently have verified information for this code. Check the manufacturer manual or use the generic diagnostic wizard.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        SecondaryButton(
          label: 'Start smart diagnosis',
          icon: Icons.auto_awesome_rounded,
          onPressed: onDiagnose,
        ),
      ],
    ),
  );
}

class _CodeResult extends StatelessWidget {
  const _CodeResult({required this.code});
  final ErrorCode code;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: code.severity.color.withValues(alpha: .1),
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: code.severity.color.withValues(alpha: .25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ERROR CODE ${code.code}',
              style: TextStyle(
                color: code.severity.color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              code.meaning,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Possible causes',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            for (final cause in code.causes)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 7,
                      color: AppColors.accentDeep,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(cause)),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            Text(
              'Safe things to check',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            for (final step in code.safeChecks)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${step.title}: ${step.detail}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(height: 1.35),
                ),
              ),
            const Divider(),
            Text(
              code.severity.label,
              style: TextStyle(
                color: code.severity.color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
