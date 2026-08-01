import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/agent_notifier.dart';
import '../../../shared/widgets/status_badge.dart';

class AgentListPage extends ConsumerStatefulWidget {
  const AgentListPage({super.key});

  @override
  ConsumerState<AgentListPage> createState() => _AgentListPageState();
}

class _AgentListPageState extends ConsumerState<AgentListPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(agentNotifierProvider.notifier).loadAgents());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(agentNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agents'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(agentNotifierProvider.notifier).loadAgents(),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.agents.isEmpty
              ? const Center(child: Text('No agents'))
              : RefreshIndicator(
                  onRefresh: () => ref.read(agentNotifierProvider.notifier).loadAgents(),
                  child: ListView.builder(
                    itemCount: state.agents.length,
                    itemBuilder: (context, index) {
                      final agent = state.agents[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: agent.status == 'active'
                                      ? Colors.green.withValues(alpha: 0.2)
                                      : Colors.grey.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.devices,
                                  color: agent.status == 'active' ? Colors.green : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      agent.name,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ID: ${agent.wazuhAgentId}',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    if (agent.ip != null)
                                      Text(
                                        agent.ip!,
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    if (agent.osName != null)
                                      Text(
                                        '${agent.osName} ${agent.osVersion ?? ''}',
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                  ],
                                ),
                              ),
                              StatusBadge(status: agent.status),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
