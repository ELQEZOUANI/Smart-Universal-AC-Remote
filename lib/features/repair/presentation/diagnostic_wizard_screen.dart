import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/design_tokens.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../domain/diagnostic_engine.dart';
import '../domain/repair_models.dart';

class DiagnosticWizardScreen extends StatefulWidget {
  const DiagnosticWizardScreen({super.key, this.initialCategory});
  final RepairCategory? initialCategory;
  @override
  State<DiagnosticWizardScreen> createState() => _DiagnosticWizardScreenState();
}

class _DiagnosticWizardScreenState extends State<DiagnosticWizardScreen> {
  final _engine = const DiagnosticEngine();
  final _symptoms = TextEditingController();
  final Map<String, String> _answers = {};
  RepairCategory? _category;
  var _index = 0;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
  }

  @override
  void dispose() {
    _symptoms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = _category;
    if (category == null) return _problemPicker(context);
    final questions = _engine.questionsFor(category);
    final question = questions[_index];
    return Scaffold(
      body: AppPage(
        maxWidth: 680,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _index == 0
                      ? () => context.go('/repair')
                      : _previous,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Smart diagnosis',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(onPressed: _restart, child: const Text('Restart')),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Question ${_index + 1} of ${questions.length}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.accentDeep,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: (_index + 1) / questions.length,
                minHeight: 8,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
                color: AppColors.accentDeep,
              ),
            ),
            const SizedBox(height: 24),
            GlassCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(category.icon, color: AppColors.accentDeep),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    question.prompt,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final option in question.options) ...[
                    _OptionTile(
                      label: option.label,
                      selected: _answers[question.id] == option.id,
                      onTap: () =>
                          _answer(question.id, option.id, questions.length),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Answers suggest likely causes; they do not replace a professional inspection.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _problemPicker(BuildContext context) => Scaffold(
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
              Text(
                'Smart diagnosis',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'What problem are you experiencing?',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the closest symptom to start a safe, guided check.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _symptoms,
            onChanged: _matchSymptoms,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Describe the problem (optional)',
              hintText: 'Example: It runs for 10 minutes then stops',
              prefixIcon: Icon(Icons.edit_note_rounded),
            ),
          ),
          const SizedBox(height: 18),
          for (final item in _wizardCategories) ...[
            GlassCard(
              onTap: () => setState(() => _category = item),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(item.icon, color: AppColors.accentDeep),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_rounded),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    ),
  );

  void _matchSymptoms(String value) {
    final match = _engine.categoryFromSymptoms(value);
    if (match != null && _category == null) setState(() => _category = match);
  }

  void _answer(String questionId, String optionId, int total) {
    setState(() => _answers[questionId] = optionId);
    if (_index + 1 < total) {
      Future<void>.delayed(const Duration(milliseconds: 140), () {
        if (mounted) setState(() => _index++);
      });
      return;
    }
    final result = _engine.evaluate(
      DiagnosticContext(
        category: _category!,
        answers: _answers,
        symptoms: _symptoms.text,
      ),
    );
    context.push('/repair/result', extra: result);
  }

  void _previous() => setState(() {
    _answers.remove(_engine.questionsFor(_category!)[_index].id);
    _index--;
  });
  void _restart() => setState(() {
    _answers.clear();
    _index = 0;
    _category = widget.initialCategory;
  });
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Ink(
      decoration: BoxDecoration(
        color: selected
            ? AppColors.accent.withValues(alpha: .11)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: selected
              ? AppColors.accentDeep
              : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected
                    ? AppColors.accentDeep
                    : Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

const _wizardCategories = <RepairCategory>[
  RepairCategory.notCooling,
  RepairCategory.notHeating,
  RepairCategory.notStarting,
  RepairCategory.weakAirflow,
  RepairCategory.leakingWater,
  RepairCategory.makingNoise,
  RepairCategory.badSmell,
  RepairCategory.outdoorUnit,
  RepairCategory.remote,
  RepairCategory.wifi,
];
