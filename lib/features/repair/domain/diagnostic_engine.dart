import 'repair_models.dart';

class DiagnosticEngine {
  const DiagnosticEngine();

  List<DiagnosticQuestion> questionsFor(RepairCategory category) =>
      switch (category) {
        RepairCategory.notCooling => _coolingQuestions,
        RepairCategory.notStarting => _powerQuestions,
        RepairCategory.leakingWater => _leakQuestions,
        RepairCategory.weakAirflow => _airflowQuestions,
        RepairCategory.badSmell => _smellQuestions,
        RepairCategory.remote || RepairCategory.wifi => _remoteQuestions,
        RepairCategory.makingNoise => _noiseQuestions,
        _ => _generalQuestions,
      };

  DiagnosticResult evaluate(DiagnosticContext context) {
    final issues = switch (context.category) {
      RepairCategory.notCooling => _coolingIssues(context.answers),
      RepairCategory.notStarting => _powerIssues(context.answers),
      RepairCategory.leakingWater => _leakIssues(context.answers),
      RepairCategory.weakAirflow => _airflowIssues(context.answers),
      RepairCategory.badSmell => _smellIssues(context.answers),
      RepairCategory.remote ||
      RepairCategory.wifi => _remoteIssues(context.answers),
      RepairCategory.makingNoise => _noiseIssues(context.answers),
      _ => _generalIssues(context.category),
    }..sort((a, b) => b.confidence.compareTo(a.confidence));
    return DiagnosticResult(
      category: context.category,
      issues: issues,
      score: issues.isEmpty ? 0 : issues.first.confidence,
    );
  }

  RepairCategory? categoryFromSymptoms(String text) {
    final value = text.toLowerCase();
    if (value.contains('not cold') || value.contains('not cool')) {
      return RepairCategory.notCooling;
    }
    if (value.contains('leak') || value.contains('water')) {
      return RepairCategory.leakingWater;
    }
    if (value.contains('smell') || value.contains('burning')) {
      return RepairCategory.badSmell;
    }
    if (value.contains('noise') ||
        value.contains('buzz') ||
        value.contains('rattl')) {
      return RepairCategory.makingNoise;
    }
    if (value.contains('remote') ||
        value.contains('wifi') ||
        value.contains('wi-fi')) {
      return RepairCategory.remote;
    }
    if (value.contains('outside') && value.contains('fan')) {
      return RepairCategory.outdoorUnit;
    }
    if (value.contains('fan') || value.contains('airflow')) {
      return RepairCategory.weakAirflow;
    }
    return null;
  }

  List<DiagnosticIssue> _coolingIssues(Map<String, String> a) => [
    _issue(
      id: 'dirty_filter',
      title: 'Dirty or restricted airflow',
      description:
          'Restricted airflow can significantly reduce cooling performance.',
      confidence: _score(30, [
        if (a['filter'] == 'dirty') 52,
        if (a['airflow'] == 'weak') 24,
      ]),
      severity: DiagnosticSeverity.safe,
      steps: const [
        RepairStep(
          title: 'Inspect the accessible filter',
          detail: 'Clean it only according to the manufacturer instructions.',
        ),
        RepairStep(
          title: 'Check vents',
          detail: 'Remove visible obstructions from airflow paths.',
        ),
      ],
    ),
    _issue(
      id: 'mode_setting',
      title: 'Operating mode or temperature setting',
      description:
          'Cooling is reduced when Cool mode is not selected or the target temperature is too high.',
      confidence: _score(18, [
        if (a['mode'] == 'no') 62,
        if (a['airTemp'] == 'room') 12,
      ]),
      severity: DiagnosticSeverity.safe,
      steps: const [
        RepairStep(
          title: 'Set Cool mode',
          detail:
              'Choose Cool mode and set a temperature below the room temperature.',
        ),
        RepairStep(
          title: 'Allow time',
          detail: 'Wait a few minutes for normal protection delays to clear.',
        ),
      ],
    ),
    _issue(
      id: 'outdoor_unit',
      title: 'Outdoor unit or system operation issue',
      description:
          'The outdoor unit is needed for normal cooling and may require professional inspection.',
      confidence: _score(25, [
        if (a['outdoor'] == 'no') 48,
        if (a['airTemp'] == 'room') 20,
      ]),
      severity: DiagnosticSeverity.technician,
      steps: const [
        RepairStep(
          title: 'Check visible status',
          detail:
              'After a normal start delay, observe whether the outdoor unit appears to operate.',
        ),
        RepairStep(
          title: 'Record any code',
          detail:
              'If a code appears, use Error Code Lookup before booking service.',
        ),
      ],
    ),
    _issue(
      id: 'refrigeration',
      title: 'Refrigeration or compressor system issue',
      description:
          'A sealed-system or compressor fault can affect cooling even when basic checks are normal.',
      confidence: _score(16, [
        if (a['filter'] == 'clean' &&
            a['mode'] == 'yes' &&
            a['airTemp'] == 'room')
          43,
      ]),
      severity: DiagnosticSeverity.technician,
      steps: const [
        RepairStep(
          title: 'Arrange qualified service',
          detail:
              'Refrigerant and internal electrical work must be handled by a qualified HVAC technician.',
        ),
      ],
    ),
  ];

  List<DiagnosticIssue> _powerIssues(Map<String, String> a) => [
    _issue(
      id: 'power_supply',
      title: 'Power supply or breaker issue',
      description: 'No display or response can indicate a supply issue.',
      confidence: _score(30, [if (a['display'] == 'no') 54]),
      severity: DiagnosticSeverity.attention,
      steps: const [
        RepairStep(
          title: 'Check normal power controls',
          detail:
              'Confirm the plug or isolator is in its normal operating state without opening electrical panels.',
        ),
        RepairStep(
          title: 'Check for a delay',
          detail:
              'Wait a few minutes after a power interruption before retrying.',
        ),
      ],
    ),
    _issue(
      id: 'remote_timer',
      title: 'Remote, timer, or control setting',
      description:
          'A timer, battery, or selected control issue can prevent a normal start.',
      confidence: _score(22, [
        if (a['remote'] == 'no') 48,
        if (a['timer'] == 'yes') 45,
      ]),
      severity: DiagnosticSeverity.safe,
      steps: const [
        RepairStep(
          title: 'Check timer settings',
          detail: 'Cancel any stop timer and retry.',
        ),
        RepairStep(
          title: 'Check the remote',
          detail:
              'Replace physical remote batteries and confirm the correct device is selected in the app.',
        ),
      ],
    ),
    _issue(
      id: 'control_fault',
      title: 'Internal control or communication fault',
      description:
          'If power is present but the unit remains unresponsive, professional inspection may be needed.',
      confidence: _score(16, [
        if (a['display'] == 'yes' && a['remote'] == 'yes') 44,
      ]),
      severity: DiagnosticSeverity.technician,
      steps: const [
        RepairStep(
          title: 'Check for an error code',
          detail:
              'Record any display code before contacting a qualified technician.',
        ),
      ],
    ),
  ];

  List<DiagnosticIssue> _leakIssues(Map<String, String> a) => [
    _issue(
      id: 'drain',
      title: 'Drainage restriction or hose issue',
      description:
          'A blocked drain path can cause water to collect and overflow.',
      confidence: _score(34, [if (a['drain'] == 'yes') 48]),
      severity: DiagnosticSeverity.attention,
      steps: const [
        RepairStep(
          title: 'Stop and protect the area',
          detail: 'Turn the unit off normally if water is actively dripping.',
        ),
        RepairStep(
          title: 'Arrange service if it continues',
          detail: 'A technician can safely inspect the internal drain system.',
        ),
      ],
    ),
    _issue(
      id: 'filter_freeze',
      title: 'Dirty filter or frozen indoor coil',
      description:
          'Restricted airflow can contribute to condensation or ice-related leaking.',
      confidence: _score(25, [if (a['filter'] == 'dirty') 45]),
      severity: DiagnosticSeverity.safe,
      steps: const [
        RepairStep(
          title: 'Clean the accessible filter',
          detail: 'Follow the AC manufacturer instructions.',
        ),
        RepairStep(
          title: 'Allow the unit to thaw',
          detail: 'Turn cooling off and seek service if icing returns.',
        ),
      ],
    ),
    _issue(
      id: 'installation_drain',
      title: 'Drain routing or installation issue',
      description:
          'Persistent leaks may need a professional to inspect the drain routing or installation.',
      confidence: 30,
      severity: DiagnosticSeverity.technician,
      steps: const [
        RepairStep(
          title: 'Book qualified service',
          detail:
              'Do not open the indoor unit or alter concealed drain connections.',
        ),
      ],
    ),
  ];

  List<DiagnosticIssue> _airflowIssues(Map<String, String> a) => [
    _issue(
      id: 'filter_airflow',
      title: 'Dirty filter or blocked airflow',
      description:
          'A blocked filter is a common, user-serviceable cause of weak airflow.',
      confidence: _score(35, [if (a['filter'] == 'dirty') 48]),
      severity: DiagnosticSeverity.safe,
      steps: const [
        RepairStep(
          title: 'Clean the accessible filter',
          detail: 'Use the manufacturer’s cleaning guidance.',
        ),
        RepairStep(
          title: 'Open vents',
          detail: 'Remove visible obstructions from vents and air inlets.',
        ),
      ],
    ),
    _issue(
      id: 'fan_setting',
      title: 'Fan speed or airflow setting',
      description:
          'Low fan speed or a quiet setting can make airflow feel weak.',
      confidence: _score(28, [if (a['fanSetting'] == 'low') 46]),
      severity: DiagnosticSeverity.safe,
      steps: const [
        RepairStep(
          title: 'Increase fan speed',
          detail: 'Select Auto or a higher fan setting and compare airflow.',
        ),
      ],
    ),
    _issue(
      id: 'fan_fault',
      title: 'Indoor fan or internal airflow issue',
      description:
          'A continuing airflow problem after safe checks may need service.',
      confidence: 25,
      severity: DiagnosticSeverity.technician,
      steps: const [
        RepairStep(
          title: 'Arrange service',
          detail: 'Do not remove covers or reach into the indoor unit.',
        ),
      ],
    ),
  ];

  List<DiagnosticIssue> _smellIssues(Map<String, String> a) => [
    _issue(
      id: 'filter_odour',
      title: 'Filter or moisture buildup',
      description: 'Dust and retained moisture can create a musty smell.',
      confidence: _score(35, [if (a['smell'] == 'musty') 42]),
      severity: DiagnosticSeverity.safe,
      steps: const [
        RepairStep(
          title: 'Clean the accessible filter',
          detail:
              'Follow manufacturer instructions and allow it to dry completely.',
        ),
      ],
    ),
    _issue(
      id: 'drain_odour',
      title: 'Drainage or indoor-unit hygiene issue',
      description:
          'Persistent odours may need professional cleaning of internal components.',
      confidence: 30,
      severity: DiagnosticSeverity.attention,
      steps: const [
        RepairStep(
          title: 'Use normal ventilation',
          detail:
              'Ventilate the room and arrange service if the smell persists.',
        ),
      ],
    ),
    _issue(
      id: 'electrical_smell',
      title: 'Possible electrical issue',
      description:
          'A burning or electrical smell needs prompt professional attention.',
      confidence: _score(15, [if (a['smell'] == 'burning') 75]),
      severity: DiagnosticSeverity.urgent,
      steps: const [
        RepairStep(
          title: 'Stop using the unit',
          detail: 'Turn it off using normal controls and do not restart it.',
        ),
        RepairStep(
          title: 'Contact qualified service',
          detail: 'An HVAC professional should inspect the unit.',
        ),
      ],
    ),
  ];

  List<DiagnosticIssue> _remoteIssues(Map<String, String> a) => [
    _issue(
      id: 'connection',
      title: 'Remote or network connection issue',
      description:
          'The AC and app may need the same network or a renewed pairing.',
      confidence: _score(30, [if (a['network'] == 'no') 48]),
      severity: DiagnosticSeverity.safe,
      steps: const [
        RepairStep(
          title: 'Check the selected device',
          detail: 'Confirm the correct AC is selected in the app.',
        ),
        RepairStep(
          title: 'Check the network',
          detail:
              'Ensure the phone and smart AC use the expected Wi-Fi network.',
        ),
      ],
    ),
    _issue(
      id: 'physical_remote',
      title: 'Physical remote battery or receiver issue',
      description:
          'A physical remote may need fresh batteries or a clear line to the indoor-unit receiver.',
      confidence: _score(25, [if (a['battery'] == 'old') 48]),
      severity: DiagnosticSeverity.safe,
      steps: const [
        RepairStep(
          title: 'Replace batteries',
          detail: 'Install fresh batteries in the physical remote and retry.',
        ),
      ],
    ),
  ];

  List<DiagnosticIssue> _noiseIssues(Map<String, String> a) => [
    _issue(
      id: 'normal_noise',
      title: 'Normal operating or expansion noise',
      description:
          'Light clicks or gentle airflow sounds can occur during normal operation.',
      confidence: _score(36, [if (a['noise'] == 'clicking') 38]),
      severity: DiagnosticSeverity.safe,
      steps: const [
        RepairStep(
          title: 'Observe the pattern',
          detail:
              'Note when the sound occurs and whether performance is otherwise normal.',
        ),
      ],
    ),
    _issue(
      id: 'mechanical_noise',
      title: 'Fan or mechanical vibration issue',
      description:
          'Rattling, grinding, or persistent buzzing should be assessed by a technician.',
      confidence: _score(22, [
        if (a['noise'] == 'grinding' || a['noise'] == 'rattling') 60,
      ]),
      severity: DiagnosticSeverity.technician,
      steps: const [
        RepairStep(
          title: 'Avoid invasive checks',
          detail: 'Do not remove covers or attempt internal repairs.',
        ),
        RepairStep(
          title: 'Book service',
          detail: 'Describe the sound and when it happens.',
        ),
      ],
    ),
  ];

  List<DiagnosticIssue> _generalIssues(RepairCategory category) => [
    _issue(
      id: 'general_check',
      title: 'Operating setting or maintenance item',
      description:
          'Start with safe operating-mode, temperature, filter, and visible-obstruction checks.',
      confidence: 55,
      severity: DiagnosticSeverity.safe,
      steps: const [
        RepairStep(
          title: 'Review settings',
          detail:
              'Check the selected mode, target temperature, and fan setting.',
        ),
        RepairStep(
          title: 'Inspect the filter',
          detail:
              'Clean accessible filters according to the manufacturer instructions.',
        ),
      ],
    ),
    _issue(
      id: 'professional_review',
      title: 'Internal system issue',
      description:
          'If the problem remains after safe checks, a qualified technician should inspect internal components.',
      confidence: 35,
      severity: DiagnosticSeverity.technician,
      steps: const [
        RepairStep(
          title: 'Record symptoms',
          detail:
              'Note behaviour, timing, and any error code for a technician.',
        ),
      ],
    ),
  ];

  DiagnosticIssue _issue({
    required String id,
    required String title,
    required String description,
    required int confidence,
    required DiagnosticSeverity severity,
    required List<RepairStep> steps,
  }) => DiagnosticIssue(
    id: id,
    title: title,
    description: description,
    confidence: confidence.clamp(5, 95),
    severity: severity,
    safeChecks: steps,
    technicianRecommended:
        severity == DiagnosticSeverity.technician ||
        severity == DiagnosticSeverity.urgent,
  );

  int _score(int base, List<int> contributions) =>
      base + contributions.fold(0, (total, value) => total + value);
}

const _yesNo = [
  DiagnosticOption(id: 'yes', label: 'Yes'),
  DiagnosticOption(id: 'no', label: 'No'),
];
const _coolingQuestions = [
  DiagnosticQuestion(
    id: 'airflow',
    prompt: 'Is air coming from the indoor unit?',
    options: _yesNo,
  ),
  DiagnosticQuestion(
    id: 'airTemp',
    prompt: 'How does the air feel?',
    options: [
      DiagnosticOption(id: 'cold', label: 'Cold'),
      DiagnosticOption(id: 'slightly', label: 'Slightly cool'),
      DiagnosticOption(id: 'room', label: 'Room temperature'),
    ],
  ),
  DiagnosticQuestion(
    id: 'outdoor',
    prompt: 'After a normal start delay, does the outdoor unit appear to run?',
    options: _yesNo,
  ),
  DiagnosticQuestion(
    id: 'filter',
    prompt: 'Does the accessible filter look dirty?',
    options: [
      DiagnosticOption(id: 'dirty', label: 'Dirty'),
      DiagnosticOption(id: 'clean', label: 'Clean or recently cleaned'),
      DiagnosticOption(id: 'unsure', label: 'Not sure'),
    ],
  ),
  DiagnosticQuestion(
    id: 'mode',
    prompt: 'Is Cool mode selected with a temperature below room temperature?',
    options: _yesNo,
  ),
];
const _powerQuestions = [
  DiagnosticQuestion(
    id: 'display',
    prompt: 'Does the indoor unit show any display light or response?',
    options: _yesNo,
  ),
  DiagnosticQuestion(
    id: 'remote',
    prompt: 'Does the physical remote or app show a response?',
    options: _yesNo,
  ),
  DiagnosticQuestion(
    id: 'timer',
    prompt: 'Is a stop timer or schedule currently active?',
    options: _yesNo,
  ),
];
const _leakQuestions = [
  DiagnosticQuestion(
    id: 'drain',
    prompt:
        'Is water dripping from the indoor unit or wall-mounted drain area?',
    options: _yesNo,
  ),
  DiagnosticQuestion(
    id: 'filter',
    prompt: 'Does the accessible filter look dirty?',
    options: [
      DiagnosticOption(id: 'dirty', label: 'Dirty'),
      DiagnosticOption(id: 'clean', label: 'Clean'),
      DiagnosticOption(id: 'unsure', label: 'Not sure'),
    ],
  ),
];
const _airflowQuestions = [
  DiagnosticQuestion(
    id: 'filter',
    prompt: 'Does the accessible filter look dirty?',
    options: [
      DiagnosticOption(id: 'dirty', label: 'Dirty'),
      DiagnosticOption(id: 'clean', label: 'Clean'),
      DiagnosticOption(id: 'unsure', label: 'Not sure'),
    ],
  ),
  DiagnosticQuestion(
    id: 'fanSetting',
    prompt: 'Which fan setting is selected?',
    options: [
      DiagnosticOption(id: 'low', label: 'Low or quiet'),
      DiagnosticOption(id: 'high', label: 'Auto or high'),
      DiagnosticOption(id: 'unsure', label: 'Not sure'),
    ],
  ),
];
const _smellQuestions = [
  DiagnosticQuestion(
    id: 'smell',
    prompt: 'Which smell is closest?',
    options: [
      DiagnosticOption(id: 'musty', label: 'Musty or dusty'),
      DiagnosticOption(id: 'burning', label: 'Burning or electrical'),
      DiagnosticOption(id: 'other', label: 'Other'),
    ],
  ),
];
const _remoteQuestions = [
  DiagnosticQuestion(
    id: 'network',
    prompt:
        'Are the phone and smart AC connected to the expected Wi-Fi network?',
    options: _yesNo,
  ),
  DiagnosticQuestion(
    id: 'battery',
    prompt: 'If using a physical remote, are its batteries fresh?',
    options: [
      DiagnosticOption(id: 'fresh', label: 'Fresh batteries'),
      DiagnosticOption(id: 'old', label: 'Old or unknown batteries'),
      DiagnosticOption(id: 'na', label: 'Not using a physical remote'),
    ],
  ),
];
const _noiseQuestions = [
  DiagnosticQuestion(
    id: 'noise',
    prompt: 'Which sound is closest?',
    options: [
      DiagnosticOption(id: 'clicking', label: 'Clicking'),
      DiagnosticOption(id: 'buzzing', label: 'Buzzing'),
      DiagnosticOption(id: 'rattling', label: 'Rattling'),
      DiagnosticOption(id: 'grinding', label: 'Grinding-like'),
    ],
  ),
];
const _generalQuestions = [
  DiagnosticQuestion(
    id: 'error',
    prompt: 'Is an error code currently displayed?',
    options: _yesNo,
  ),
  DiagnosticQuestion(
    id: 'recent',
    prompt: 'Was the AC recently installed or serviced?',
    options: _yesNo,
  ),
];
