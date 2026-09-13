import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/design_tokens.dart';
import '../../../core/widgets/premium_widgets.dart';
import '../domain/repair_models.dart';

class DiagnosticResultScreen extends StatelessWidget {
  const DiagnosticResultScreen({super.key, required this.result});
  final DiagnosticResult result;

  @override
  Widget build(BuildContext context) => Scaffold(
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
                  'Diagnosis result',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              IconButton(
                tooltip: 'Start a new diagnosis',
                onPressed: () => context.go('/repair/diagnosis'),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _ResultSummary(result: result),
          const SizedBox(height: 22),
          Text(
            'Based on your answers, these are the most likely causes.',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          for (final issue in result.issues) ...[
            _IssueCard(issue: issue),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 4),
          PrimaryButton(
            label: 'Start a new diagnosis',
            icon: Icons.restart_alt_rounded,
            onPressed: () => context.go('/repair/diagnosis'),
          ),
          const SizedBox(height: 10),
          SecondaryButton(
            label: 'Maintenance checklist',
            icon: Icons.checklist_rounded,
            onPressed: () => context.push('/repair/maintenance'),
          ),
        ],
      ),
    ),
  );
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.result});
  final DiagnosticResult result;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.navy, AppColors.navyDeep],
      ),
      borderRadius: BorderRadius.circular(AppRadius.extraLarge),
    ),
    child: Row(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${result.score}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 19,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DIAGNOSTIC SCORE',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                result.issues.first.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                result.category.label,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue});
  final DiagnosticIssue issue;
  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                issue.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            _Badge(label: issue.likelihood, color: issue.severity.color),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          issue.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),
        for (final step in issue.safeChecks)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 18,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        step.detail,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (issue.technicianRecommended) ...[
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: issue.severity.color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.engineering_rounded,
                  color: issue.severity.color,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Professional service recommended. This may involve internal electrical or refrigeration components.',
                    style: TextStyle(
                      color: issue.severity.color,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
    ),
  );
}
