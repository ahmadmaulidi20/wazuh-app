import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/agent_model.dart';

class AgentRepository {
  final ApiClient _client = ApiClient();

  Future<List<AgentModel>> list() async {
    final response = await _client.get(ApiConstants.agents);
    return (response.data as List<dynamic>)
        .map((e) => AgentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
