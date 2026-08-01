import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/agent_repository.dart';
import '../../../core/models/agent_model.dart';

class AgentState {
  final bool isLoading;
  final List<AgentModel> agents;
  final String? error;

  const AgentState({this.isLoading = false, this.agents = const [], this.error});

  AgentState copyWith({bool? isLoading, List<AgentModel>? agents, String? error}) {
    return AgentState(
      isLoading: isLoading ?? this.isLoading,
      agents: agents ?? this.agents,
      error: error,
    );
  }
}

class AgentNotifier extends StateNotifier<AgentState> {
  final AgentRepository _repository;

  AgentNotifier(this._repository) : super(const AgentState());

  Future<void> loadAgents() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final agents = await _repository.list();
      state = AgentState(agents: agents);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final agentRepositoryProvider = Provider<AgentRepository>((ref) => AgentRepository());

final agentNotifierProvider = StateNotifierProvider<AgentNotifier, AgentState>((ref) {
  return AgentNotifier(ref.read(agentRepositoryProvider));
});
