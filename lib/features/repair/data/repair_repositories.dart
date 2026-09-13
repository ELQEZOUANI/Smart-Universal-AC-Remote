import '../domain/repair_models.dart';

class BrandRepository {
  const BrandRepository();

  static const _brands = <AcBrand>[
    AcBrand(id: 'other', name: 'Other / Unknown brand'),
    AcBrand(id: 'daikin', name: 'Daikin'),
    AcBrand(id: 'mitsubishi-electric', name: 'Mitsubishi Electric'),
    AcBrand(id: 'mitsubishi-heavy', name: 'Mitsubishi Heavy Industries'),
    AcBrand(id: 'lg', name: 'LG'),
    AcBrand(id: 'samsung', name: 'Samsung'),
    AcBrand(id: 'panasonic', name: 'Panasonic'),
    AcBrand(id: 'gree', name: 'Gree'),
    AcBrand(id: 'midea', name: 'Midea'),
    AcBrand(id: 'carrier', name: 'Carrier'),
    AcBrand(id: 'toshiba', name: 'Toshiba'),
    AcBrand(id: 'fujitsu', name: 'Fujitsu'),
    AcBrand(id: 'hitachi', name: 'Hitachi'),
    AcBrand(id: 'haier', name: 'Haier'),
    AcBrand(id: 'hisense', name: 'Hisense'),
    AcBrand(id: 'tcl', name: 'TCL'),
    AcBrand(id: 'sharp', name: 'Sharp'),
    AcBrand(id: 'bosch', name: 'Bosch'),
    AcBrand(id: 'trane', name: 'Trane'),
    AcBrand(id: 'lennox', name: 'Lennox'),
    AcBrand(id: 'york', name: 'York'),
    AcBrand(id: 'aux', name: 'AUX'),
    AcBrand(id: 'electrolux', name: 'Electrolux'),
    AcBrand(id: 'whirlpool', name: 'Whirlpool'),
    AcBrand(id: 'general', name: 'General'),
    AcBrand(id: 'o-general', name: 'O General'),
    AcBrand(id: 'kenmore', name: 'Kenmore'),
    AcBrand(id: 'rheem', name: 'Rheem'),
    AcBrand(id: 'ruud', name: 'Ruud'),
    AcBrand(id: 'goodman', name: 'Goodman'),
    AcBrand(id: 'american-standard', name: 'American Standard'),
    AcBrand(id: 'sanyo', name: 'Sanyo'),
    AcBrand(id: 'pioneer', name: 'Pioneer'),
    AcBrand(id: 'mrcool', name: 'MRCOOL'),
    AcBrand(id: 'cooper-hunter', name: 'Cooper & Hunter'),
    AcBrand(id: 'kelvinator', name: 'Kelvinator'),
    AcBrand(id: 'vestel', name: 'Vestel'),
  ];

  List<AcBrand> get brands => _brands;

  List<AcBrand> search(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) return brands;
    return brands
        .where((brand) => brand.name.toLowerCase().contains(normalized))
        .toList();
  }

  AcBrand? byId(String? id) {
    if (id == null) return null;
    for (final brand in brands) {
      if (brand.id == id) return brand;
    }
    return null;
  }
}

/// This is intentionally a small, verified local catalogue. Unknown entries
/// return null rather than guessing a manufacturer-specific meaning.
class ErrorCodeRepository {
  const ErrorCodeRepository();

  static const _codes = <ErrorCode>[
    ErrorCode(
      brandId: 'daikin',
      code: 'U4',
      meaning: 'Communication problem between the indoor and outdoor units.',
      causes: [
        'Communication wiring or connection issue',
        'Indoor or outdoor unit has no power',
        'Control-board communication fault',
      ],
      safeChecks: [
        RepairStep(
          title: 'Restart safely',
          detail:
              'Turn the unit off using its normal control, wait a few minutes, then restart it.',
        ),
        RepairStep(
          title: 'Check the display',
          detail: 'Note whether the code returns after the restart.',
        ),
        RepairStep(
          title: 'Check visible power signs',
          detail:
              'Confirm both units appear to have power without opening any electrical panels.',
        ),
      ],
      severity: DiagnosticSeverity.technician,
      relatedSymptoms: [
        'Indoor unit runs without cooling',
        'Outdoor unit does not respond',
      ],
    ),
    ErrorCode(
      brandId: 'lg',
      code: 'CH05',
      meaning: 'Communication problem between the indoor and outdoor units.',
      causes: [
        'Inter-unit communication issue',
        'Power loss at one unit',
        'Internal control or wiring fault',
      ],
      safeChecks: [
        RepairStep(
          title: 'Restart safely',
          detail:
              'Use the normal AC power control and see whether the code returns.',
        ),
        RepairStep(
          title: 'Observe both units',
          detail:
              'Check for normal visible power indicators without removing covers.',
        ),
      ],
      severity: DiagnosticSeverity.technician,
      relatedSymptoms: [
        'AC stops cooling',
        'Indoor or outdoor unit does not operate',
      ],
    ),
  ];

  ErrorCode? find({required String brandId, required String code}) {
    final normalized = code.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    for (final entry in _codes) {
      if (entry.brandId == brandId && entry.code == normalized) return entry;
    }
    return null;
  }

  List<ErrorCode> search(String query) {
    final normalized = query.trim().toUpperCase();
    if (normalized.isEmpty) return const [];
    return _codes.where((entry) => entry.code.contains(normalized)).toList();
  }
}

class MaintenanceRepository {
  const MaintenanceRepository();

  List<RepairStep> get checklist => const [
    RepairStep(
      title: 'Clean accessible filters',
      detail: 'Follow your manufacturer instructions for removable filters.',
    ),
    RepairStep(
      title: 'Check air vents',
      detail: 'Keep supply and return vents free from furniture and dust.',
    ),
    RepairStep(
      title: 'Inspect visible outdoor obstructions',
      detail:
          'Remove leaves or objects around the outdoor unit only when it is safe to do so.',
    ),
    RepairStep(
      title: 'Check drainage signs',
      detail: 'Look for unusual drips or water marks near the indoor unit.',
    ),
    RepairStep(
      title: 'Review unusual sounds',
      detail:
          'Note any clicking, rattling, buzzing, or grinding for a technician.',
    ),
    RepairStep(
      title: 'Check cooling performance',
      detail:
          'Confirm Cool mode and a temperature below the room temperature are selected.',
    ),
    RepairStep(
      title: 'Clean the remote',
      detail:
          'Keep the remote sensor area clean and replace physical remote batteries if needed.',
    ),
  ];
}
