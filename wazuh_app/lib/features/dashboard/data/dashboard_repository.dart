import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/dashboard_data.dart';

class DashboardRepository {
  final ApiClient _client = ApiClient();

  Future<DashboardData> getStats() async {
    final response = await _client.get(ApiConstants.dashboard);
    return DashboardData.fromJson(response.data as Map<String, dynamic>);
  }
}
