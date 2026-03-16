import '../auth/user_repository.dart';

class SettingsRepository {
  final _userRepo = UserRepository();

  Future<Map<String, dynamic>> getSubscriptionStatus(
      String androidId) async {
    return _userRepo.getSubscriptionStatus(androidId);
  }

  Future<void> updateCategories(
      String androidId, List<String> categories) async {
    await _userRepo.updateCategories(androidId, categories);
  }
}
