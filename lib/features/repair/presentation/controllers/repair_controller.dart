import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repair_repositories.dart';

class RepairState {
  const RepairState({
    this.selectedBrandId,
    this.completedMaintenance = const {},
  });

  final String? selectedBrandId;
  final Set<String> completedMaintenance;

  RepairState copyWith({
    String? selectedBrandId,
    bool clearBrand = false,
    Set<String>? completedMaintenance,
  }) => RepairState(
    selectedBrandId: clearBrand
        ? null
        : selectedBrandId ?? this.selectedBrandId,
    completedMaintenance: completedMaintenance ?? this.completedMaintenance,
  );
}

class RepairController extends Notifier<RepairState> {
  static const _brandKey = 'climalink.repair.selected_brand';
  static const _maintenanceKey = 'climalink.repair.maintenance';

  @override
  RepairState build() {
    unawaited(_restore());
    return const RepairState();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    state = RepairState(
      selectedBrandId: prefs.getString(_brandKey),
      completedMaintenance: (prefs.getStringList(_maintenanceKey) ?? const [])
          .toSet(),
    );
  }

  void selectBrand(String? brandId) {
    state = state.copyWith(
      selectedBrandId: brandId,
      clearBrand: brandId == null,
    );
    unawaited(_persist());
  }

  void toggleMaintenance(String itemId) {
    final next = {...state.completedMaintenance};
    next.contains(itemId) ? next.remove(itemId) : next.add(itemId);
    state = state.copyWith(completedMaintenance: next);
    unawaited(_persist());
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      if (state.selectedBrandId == null)
        prefs.remove(_brandKey)
      else
        prefs.setString(_brandKey, state.selectedBrandId!),
      prefs.setStringList(_maintenanceKey, state.completedMaintenance.toList()),
    ]);
  }
}

final repairControllerProvider =
    NotifierProvider<RepairController, RepairState>(RepairController.new);
final brandRepositoryProvider = Provider<BrandRepository>(
  (ref) => const BrandRepository(),
);
final errorCodeRepositoryProvider = Provider<ErrorCodeRepository>(
  (ref) => const ErrorCodeRepository(),
);
final maintenanceRepositoryProvider = Provider<MaintenanceRepository>(
  (ref) => const MaintenanceRepository(),
);
