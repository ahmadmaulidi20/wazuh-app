import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/dashboard_repository.dart';
import '../../../core/models/dashboard_data.dart';

class DashboardState {
  final bool isLoading;
  final DashboardData? data;
  final String? error;

  const DashboardState({this.isLoading = false, this.data, this.error});

  DashboardState copyWith({bool? isLoading, DashboardData? data, String? error}) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;

  DashboardNotifier(this._repository) : super(const DashboardState());

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repository.getStats();
      state = DashboardState(data: data);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) => DashboardRepository());

final dashboardNotifierProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref.read(dashboardRepositoryProvider));
});
