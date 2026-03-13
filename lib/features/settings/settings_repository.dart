import '../../core/api/api_client.dart';

class SettingsRepository {
  final _api = ApiClient().dio;

  Future<Map<String, dynamic>> getSubscriptionStatus(String androidId) async {
    final response = await _api.get(
      '/api/v1/users/subscription-status',
      queryParameters: {'androidId': androidId},
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<void> updateCategories(String androidId, List<String> categories) async {
    await _api.patch(
      '/api/v1/users/categories',
      data: {'androidId': androidId, 'categories': categories},
    );
  }
}
