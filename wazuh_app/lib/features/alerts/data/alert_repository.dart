import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/alert_model.dart';

class AlertRepository {
  final ApiClient _client = ApiClient();

  Future<AlertListResponse> list({int page = 1, int limit = 20, Map<String, dynamic>? filter}) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (filter != null) query.addAll(filter);
    final response = await _client.get(ApiConstants.alerts, queryParameters: query);
    return AlertListResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AlertModel> getById(String id) async {
    final response = await _client.get('${ApiConstants.alerts}/$id');
    return AlertModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AlertModel> updateStatus(String id, String status) async {
    final response = await _client.patch('${ApiConstants.alerts}/$id', data: {'status': status});
    return AlertModel.fromJson(response.data as Map<String, dynamic>);
  }
}
