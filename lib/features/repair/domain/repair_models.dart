import 'package:flutter/material.dart';

enum RepairCategory {
  smartDiagnosis,
  errorCode,
  notCooling,
  notHeating,
  notStarting,
  leakingWater,
  makingNoise,
  weakAirflow,
  badSmell,
  remote,
  indoorUnit,
  outdoorUnit,
  compressor,
  fan,
  sensor,
  wifi,
  maintenance;

  String get label => switch (this) {
    RepairCategory.smartDiagnosis => 'Smart diagnosis',
    RepairCategory.errorCode => 'Error code lookup',
    RepairCategory.notCooling => 'AC not cooling',
    RepairCategory.notHeating => 'AC not heating',
    RepairCategory.notStarting => 'AC not turning on',
    RepairCategory.leakingWater => 'AC leaking water',
    RepairCategory.makingNoise => 'AC making noise',
    RepairCategory.weakAirflow => 'Weak airflow',
    RepairCategory.badSmell => 'Bad smell',
    RepairCategory.remote => 'Remote not working',
    RepairCategory.indoorUnit => 'Indoor unit problem',
    RepairCategory.outdoorUnit => 'Outdoor unit problem',
    RepairCategory.compressor => 'Compressor problem',
    RepairCategory.fan => 'Fan problem',
    RepairCategory.sensor => 'Sensor problem',
    RepairCategory.wifi => 'Wi-Fi / smart AC problem',
    RepairCategory.maintenance => 'Maintenance checklist',
  };

  IconData get icon => switch (this) {
    RepairCategory.smartDiagnosis => Icons.health_and_safety_rounded,
    RepairCategory.errorCode => Icons.qr_code_2_rounded,
    RepairCategory.notCooling => Icons.ac_unit_rounded,
    RepairCategory.notHeating => Icons.wb_sunny_outlined,
    RepairCategory.notStarting => Icons.power_settings_new_rounded,
    RepairCategory.leakingWater => Icons.water_drop_outlined,
    RepairCategory.makingNoise => Icons.graphic_eq_rounded,
    RepairCategory.weakAirflow => Icons.air_rounded,
    RepairCategory.badSmell => Icons.cleaning_services_rounded,
    RepairCategory.remote => Icons.settings_remote_rounded,
    RepairCategory.indoorUnit => Icons.home_work_outlined,
    RepairCategory.outdoorUnit => Icons.outdoor_grill_rounded,
    RepairCategory.compressor => Icons.precision_manufacturing_outlined,
    RepairCategory.fan => Icons.mode_fan_off_rounded,
    RepairCategory.sensor => Icons.sensors_rounded,
    RepairCategory.wifi => Icons.wifi_rounded,
    RepairCategory.maintenance => Icons.checklist_rounded,
  };
}

enum DiagnosticSeverity { safe, attention, technician, urgent }

extension DiagnosticSeverityX on DiagnosticSeverity {
  String get label => switch (this) {
    DiagnosticSeverity.safe => 'Safe check',
    DiagnosticSeverity.attention => 'Needs attention',
    DiagnosticSeverity.technician => 'Professional service recommended',
    DiagnosticSeverity.urgent => 'Stop use and seek service',
  };

  Color get color => switch (this) {
    DiagnosticSeverity.safe => const Color(0xFF42C996),
    DiagnosticSeverity.attention => const Color(0xFFFFB85C),
    DiagnosticSeverity.technician => const Color(0xFFFF8B5C),
    DiagnosticSeverity.urgent => const Color(0xFFFF6B75),
  };
}

class AcBrand {
  const AcBrand({
    required this.id,
    required this.name,
    this.categories = const ['Split AC', 'Mini Split', 'Smart AC'],
  });

  final String id;
  final String name;
  final List<String> categories;
}

class DiagnosticOption {
  const DiagnosticOption({required this.id, required this.label});

  final String id;
  final String label;
}

class DiagnosticQuestion {
  const DiagnosticQuestion({
    required this.id,
    required this.prompt,
    required this.options,
  });

  final String id;
  final String prompt;
  final List<DiagnosticOption> options;
}

class RepairStep {
  const RepairStep({required this.title, required this.detail});

  final String title;
  final String detail;
}

class DiagnosticIssue {
  const DiagnosticIssue({
    required this.id,
    required this.title,
    required this.description,
    required this.confidence,
    required this.severity,
    required this.safeChecks,
    required this.technicianRecommended,
  });

  final String id;
  final String title;
  final String description;
  final int confidence;
  final DiagnosticSeverity severity;
  final List<RepairStep> safeChecks;
  final bool technicianRecommended;

  String get likelihood => switch (confidence) {
    >= 75 => 'Very likely',
    >= 55 => 'Likely',
    >= 35 => 'Possible',
    _ => 'Less likely',
  };
}

class DiagnosticResult {
  const DiagnosticResult({
    required this.category,
    required this.issues,
    required this.score,
  });

  final RepairCategory category;
  final List<DiagnosticIssue> issues;
  final int score;
}

class ErrorCode {
  const ErrorCode({
    required this.brandId,
    required this.code,
    required this.meaning,
    required this.causes,
    required this.safeChecks,
    required this.severity,
    required this.relatedSymptoms,
  });

  final String brandId;
  final String code;
  final String meaning;
  final List<String> causes;
  final List<RepairStep> safeChecks;
  final DiagnosticSeverity severity;
  final List<String> relatedSymptoms;
}

class DiagnosticSession {
  const DiagnosticSession({
    required this.category,
    required this.createdAt,
    required this.result,
    this.brandId,
  });

  final RepairCategory category;
  final DateTime createdAt;
  final DiagnosticResult result;
  final String? brandId;
}

class DiagnosticContext {
  const DiagnosticContext({
    required this.category,
    required this.answers,
    this.brandId,
    this.symptoms,
  });

  final RepairCategory category;
  final Map<String, String> answers;
  final String? brandId;
  final String? symptoms;
}

class DiagnosticAssistantResponse {
  const DiagnosticAssistantResponse({required this.summary});

  final String summary;
}

abstract interface class DiagnosticAssistantService {
  Future<DiagnosticAssistantResponse> analyze(DiagnosticContext context);
}
