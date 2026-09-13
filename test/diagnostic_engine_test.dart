import 'package:acremote/features/repair/data/repair_repositories.dart';
import 'package:acremote/features/repair/domain/diagnostic_engine.dart';
import 'package:acremote/features/repair/domain/repair_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const engine = DiagnosticEngine();

  test('dirty filter ranks highly for a cooling airflow problem', () {
    final result = engine.evaluate(
      const DiagnosticContext(
        category: RepairCategory.notCooling,
        answers: {
          'airflow': 'yes',
          'airTemp': 'slightly',
          'outdoor': 'yes',
          'filter': 'dirty',
          'mode': 'yes',
        },
      ),
    );
    expect(result.issues.first.id, 'dirty_filter');
    expect(result.issues.first.confidence, greaterThanOrEqualTo(75));
  });

  test('no display ranks a power-related issue highly', () {
    final result = engine.evaluate(
      const DiagnosticContext(
        category: RepairCategory.notStarting,
        answers: {'display': 'no', 'remote': 'yes', 'timer': 'no'},
      ),
    );
    expect(result.issues.first.id, 'power_supply');
  });

  test('dirty filter and drain symptoms rank drainage cause for a leak', () {
    final result = engine.evaluate(
      const DiagnosticContext(
        category: RepairCategory.leakingWater,
        answers: {'drain': 'yes', 'filter': 'dirty'},
      ),
    );
    expect(result.issues.first.id, 'drain');
  });

  test('returns verified local code and never guesses unknown code', () {
    const repository = ErrorCodeRepository();
    expect(
      repository.find(brandId: 'daikin', code: 'u4')?.meaning,
      contains('Communication'),
    );
    expect(repository.find(brandId: 'daikin', code: 'E1'), isNull);
    expect(repository.find(brandId: 'lg', code: 'CH05'), isNotNull);
  });

  test('symptom parsing remains a lightweight category hint', () {
    expect(
      engine.categoryFromSymptoms('The unit is leaking water'),
      RepairCategory.leakingWater,
    );
    expect(
      engine.categoryFromSymptoms('outside fan stopped'),
      RepairCategory.outdoorUnit,
    );
  });
}
