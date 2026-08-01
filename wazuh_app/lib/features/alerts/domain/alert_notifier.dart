import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/alert_repository.dart';
import '../../../core/models/alert_model.dart';

class AlertListState {
  final bool isLoading;
  final List<AlertModel> alerts;
  final int total;
  final int page;
  final int totalPages;
  final String? error;
  final Map<String, dynamic>? filter;

  const AlertListState({
    this.isLoading = false,
    this.alerts = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 0,
    this.error,
    this.filter,
  });

  AlertListState copyWith({
    bool? isLoading,
    List<AlertModel>? alerts,
    int? total,
    int? page,
    int? totalPages,
    String? error,
    Map<String, dynamic>? filter,
  }) {
    return AlertListState(
      isLoading: isLoading ?? this.isLoading,
      alerts: alerts ?? this.alerts,
      total: total ?? this.total,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      error: error,
      filter: filter ?? this.filter,
    );
  }
}

class AlertDetailState {
  final bool isLoading;
  final AlertModel? alert;
  final String? error;

  const AlertDetailState({this.isLoading = false, this.alert, this.error});

  AlertDetailState copyWith({bool? isLoading, AlertModel? alert, String? error}) {
    return AlertDetailState(
      isLoading: isLoading ?? this.isLoading,
      alert: alert ?? this.alert,
      error: error,
    );
  }
}

class AlertListNotifier extends StateNotifier<AlertListState> {
  final AlertRepository _repository;
  bool _isLoadingPage = false;

  AlertListNotifier(this._repository) : super(const AlertListState());

  Future<void> loadAlerts({bool append = false}) async {
    if (!append) state = state.copyWith(isLoading: true, error: null);
    _isLoadingPage = true;
    try {
      final result = await _repository.list(
        page: state.page,
        filter: state.filter,
      );
      state = state.copyWith(
        isLoading: false,
        alerts: append ? [...state.alerts, ...result.data] : result.data,
        total: result.total,
        totalPages: result.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _isLoadingPage = false;
    }
  }

  void nextPage() {
    if (state.page < state.totalPages && !_isLoadingPage) {
      state = state.copyWith(page: state.page + 1);
      loadAlerts(append: true);
    }
  }

  void setFilter(Map<String, dynamic> filter) {
    state = state.copyWith(page: 1, filter: filter);
    loadAlerts();
  }
}

class AlertDetailNotifier extends StateNotifier<AlertDetailState> {
  final AlertRepository _repository;

  AlertDetailNotifier(this._repository) : super(const AlertDetailState());

  Future<void> loadAlert(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final alert = await _repository.getById(id);
      state = AlertDetailState(alert: alert);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateStatus(String id, String status) async {
    try {
      await _repository.updateStatus(id, status);
      await loadAlert(id);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final alertRepositoryProvider = Provider<AlertRepository>((ref) => AlertRepository());

final alertListNotifierProvider = StateNotifierProvider<AlertListNotifier, AlertListState>((ref) {
  return AlertListNotifier(ref.read(alertRepositoryProvider));
});

final alertDetailNotifierProvider = StateNotifierProvider.family<AlertDetailNotifier, AlertDetailState, String>((ref, id) {
  return AlertDetailNotifier(ref.read(alertRepositoryProvider));
});
