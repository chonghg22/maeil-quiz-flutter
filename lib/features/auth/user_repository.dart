import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_constants.dart';

class UserRepository {
  final _api = ApiClient().dio;

  Future<String> getOrCreateAndroidId() async {
    final prefs = await SharedPreferences.getInstance();
    String? androidId = prefs.getString(androidIdKey);

    if (androidId == null) {
      androidId = const Uuid().v4();
      await prefs.setString(androidIdKey, androidId);
    }

    return androidId;
  }

  Future<void> register(String androidId) async {
    await _api.post(
      '/api/v1/users/register',
      data: {'androidId': androidId},
    );
  }
}
