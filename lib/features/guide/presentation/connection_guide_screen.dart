import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/design_tokens.dart';
import '../../../core/widgets/premium_widgets.dart';

class ConnectionGuideScreen extends StatefulWidget {
  const ConnectionGuideScreen({super.key});

  @override
  State<ConnectionGuideScreen> createState() => _ConnectionGuideScreenState();
}

class _ConnectionGuideScreenState extends State<ConnectionGuideScreen> {
  var _selectedBrand = 'LG';

  static const _brands = [
    'LG',
    'Samsung',
    'Daikin',
    'Midea',
    'Gree',
    'Haier',
    'Hisense',
    'TCL',
    'Panasonic',
    'Mitsubishi',
    'Other',
  ];

  static const _preparationSteps = [
    _PreparationData(
      title: 'Join your home Wi-Fi',
      detail: 'Connect this phone to the network you want your AC to use.',
      icon: Icons.wifi_rounded,
    ),
    _PreparationData(
      title: 'Power on your AC',
      detail: 'Keep the unit on and within reliable range of your router.',
      icon: Icons.power_settings_new_rounded,
    ),
    _PreparationData(
      title: 'Start pairing mode',
      detail: 'Wait until the Wi-Fi or wireless indicator begins blinking.',
      icon: Icons.settings_input_antenna_rounded,
    ),
    _PreparationData(
      title: 'Return and discover',
      detail:
          'Come back to AC Remote: Repair & Diagnose and scan for nearby compatible units.',
      icon: Icons.radar_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Connect your AC')),
    body: AppPage(
      safeTop: false,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 34),
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          const _GuideHero(),
          const SizedBox(height: 30),
          const _SectionIntro(
            eyebrow: '01  •  PREPARE',
            title: 'Before you begin',
            description: 'A few quick checks make discovery fast and reliable.',
          ),
          const SizedBox(height: 15),
          const _PreparationTimeline(steps: _preparationSteps),
          const SizedBox(height: 32),
          const _SectionIntro(
            eyebrow: '02  •  PAIR',
            title: 'Choose your brand',
            description: 'We’ll tailor the pairing steps to your AC.',
          ),
          const SizedBox(height: 15),
          _BrandSelector(
            brands: _brands,
            selectedBrand: _selectedBrand,
            onSelected: (brand) => setState(() => _selectedBrand = brand),
          ),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: AppDuration.slow,
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(.035, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _PairingGuideCard(
              key: ValueKey(_selectedBrand),
              brand: _selectedBrand,
              guide: _guideFor(_selectedBrand),
            ),
          ),
          const SizedBox(height: 30),
          _ReadyToConnectCard(
            onDiscover: () => context.push('/discovery'),
            onManual: () => context.push('/manual-connection'),
          ),
        ],
      ),
    ),
  );

  _BrandGuide _guideFor(String brand) => switch (brand) {
    'LG' => const _BrandGuide(
      method: 'Wi-Fi button setup',
      steps: [
        'Locate the Wi-Fi button on the remote or indoor unit.',
        'Press and hold it for about 3 seconds.',
        'Wait for the Wi-Fi indicator to blink, then start discovery.',
      ],
    ),
    'Samsung' => const _BrandGuide(
      method: 'AP mode setup',
      steps: [
        'Keep the AC powered on and the remote nearby.',
        'Hold the Timer button until the AP indicator appears.',
        'Keep the phone close to your router and start discovery.',
      ],
    ),
    'Daikin' => const _BrandGuide(
      method: 'Wireless adapter setup',
      steps: [
        'Open the front panel and locate the wireless setup control.',
        'Press the setup control and select AP mode if prompted.',
        'When the wireless lamp blinks, return and start discovery.',
      ],
    ),
    _ => const _BrandGuide(
      method: 'Standard Wi-Fi setup',
      steps: [
        'Open wireless settings using the remote or indoor unit.',
        'Enable Wi-Fi pairing and wait for the indicator to blink.',
        'Keep the AC powered on, then return and start discovery.',
      ],
    ),
  };
}

class _GuideHero extends StatelessWidget {
  const _GuideHero();

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppRadius.extraLarge),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.navy, AppColors.navyDeep],
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.navyDeep.withValues(alpha: .27),
          blurRadius: 34,
          offset: const Offset(0, 18),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.extraLarge),
      child: Stack(
        children: [
          Positioned(
            right: -54,
            top: -66,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: .075),
                  width: 32,
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: Icon(
              Icons.wifi_find_rounded,
              color: Colors.white.withValues(alpha: .055),
              size: 118,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: .1),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.cyan,
                        size: 14,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'GUIDED SETUP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .9,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Connect with\nconfidence.',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.03,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'A focused walkthrough from pairing mode to your first successful connection.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: .7),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                const Wrap(
                  spacing: 10,
                  runSpacing: 9,
                  children: [
                    _HeroMetric(
                      icon: Icons.format_list_numbered_rounded,
                      label: '4 simple steps',
                    ),
                    _HeroMetric(
                      icon: Icons.schedule_rounded,
                      label: 'About 2 minutes',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .085),
      borderRadius: BorderRadius.circular(AppRadius.pill),
      border: Border.all(color: Colors.white.withValues(alpha: .08)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 15),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _SectionIntro extends StatelessWidget {
  const _SectionIntro({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.accentDeep,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.05,
        ),
      ),
      const SizedBox(height: 7),
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 5),
      Text(
        description,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    ],
  );
}

class _PreparationTimeline extends StatelessWidget {
  const _PreparationTimeline({required this.steps});

  final List<_PreparationData> steps;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.fromLTRB(18, 20, 18, 4),
    borderRadius: AppRadius.extraLarge,
    child: Column(
      children: [
        for (var index = 0; index < steps.length; index++)
          _PreparationStep(
            number: index + 1,
            data: steps[index],
            isLast: index == steps.length - 1,
          ),
      ],
    ),
  );
}

class _PreparationStep extends StatelessWidget {
  const _PreparationStep({
    required this.number,
    required this.data,
    required this.isLast,
  });

  final int number;
  final _PreparationData data;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 38,
            child: Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.accent, AppColors.accentDeep],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentDeep.withValues(alpha: .2),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.accent.withValues(alpha: .35),
                            scheme.outlineVariant.withValues(alpha: .45),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 18 : 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(
                      data.icon,
                      color: AppColors.accentDeep,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.detail,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.38,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandSelector extends StatelessWidget {
  const _BrandSelector({
    required this.brands,
    required this.selectedBrand,
    required this.onSelected,
  });

  final List<String> brands;
  final String selectedBrand;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: dark ? .72 : .82),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: .55)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final brand in brands)
            _BrandChip(
              label: brand,
              selected: selectedBrand == brand,
              onTap: () => onSelected(brand),
            ),
        ],
      ),
    );
  }
}

class _BrandChip extends StatelessWidget {
  const _BrandChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label air conditioner',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: AnimatedContainer(
            duration: AppDuration.normal,
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              gradient: selected
                  ? const LinearGradient(
                      colors: [AppColors.accent, AppColors.accentDeep],
                    )
                  : null,
              color: selected ? null : scheme.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : scheme.outlineVariant.withValues(alpha: .7),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.accentDeep.withValues(alpha: .2),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: AppDuration.fast,
                  child: selected
                      ? const Padding(
                          key: ValueKey('selected'),
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('unselected')),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : scheme.onSurface,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PairingGuideCard extends StatelessWidget {
  const _PairingGuideCard({
    required this.brand,
    required this.guide,
    super.key,
  });

  final String brand;
  final _BrandGuide guide;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: AppRadius.extraLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accent.withValues(alpha: .14),
                  AppColors.cyan.withValues(alpha: .045),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.extraLarge),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.accent, AppColors.accentDeep],
                    ),
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentDeep.withValues(alpha: .22),
                        blurRadius: 16,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Text(
                    brand.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$brand pairing guide',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        guide.method,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: .12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: AppColors.success,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PAIRING SEQUENCE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .95,
                  ),
                ),
                const SizedBox(height: 15),
                for (var index = 0; index < guide.steps.length; index++) ...[
                  _InstructionRow(number: index + 1, text: guide.steps[index]),
                  if (index != guide.steps.length - 1)
                    const SizedBox(height: 14),
                ],
                const SizedBox(height: 19),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Button names and indicator behavior vary by model. Check the manufacturer manual if pairing mode does not start.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                      ),
                    ],
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

class _InstructionRow extends StatelessWidget {
  const _InstructionRow({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: .11),
          shape: BoxShape.circle,
        ),
        child: Text(
          '$number',
          style: const TextStyle(
            color: AppColors.accentDeep,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      const SizedBox(width: 11),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.42,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    ],
  );
}

class _ReadyToConnectCard extends StatelessWidget {
  const _ReadyToConnectCard({required this.onDiscover, required this.onManual});

  final VoidCallback onDiscover;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GlassCard(
      padding: const EdgeInsets.all(22),
      borderRadius: AppRadius.extraLarge,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: .12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.success.withValues(alpha: .24),
              ),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.success,
              size: 30,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Ready to connect?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            'Keep the Wi-Fi indicator blinking while AC Remote: Repair & Diagnose searches.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: 'Find my AC',
            icon: Icons.radar_rounded,
            onPressed: onDiscover,
          ),
          const SizedBox(height: 9),
          TextButton.icon(
            onPressed: onManual,
            icon: const Icon(Icons.lan_outlined, size: 18),
            label: const Text('Connect with IP address'),
          ),
        ],
      ),
    );
  }
}

class _PreparationData {
  const _PreparationData({
    required this.title,
    required this.detail,
    required this.icon,
  });

  final String title;
  final String detail;
  final IconData icon;
}

class _BrandGuide {
  const _BrandGuide({required this.method, required this.steps});

  final String method;
  final List<String> steps;
}
