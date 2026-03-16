import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_constants.dart';

class UserRepository {
  final _supabase = Supabase.instance.client;

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
    await _supabase.rpc('upsert_user', params: {'p_android_id': androidId});
  }

  Future<void> updateCategories(
      String androidId, List<String> categories) async {
    await _supabase.rpc('update_categories', params: {
      'p_android_id': androidId,
      'p_categories': categories,
    });
  }

  Future<Map<String, dynamic>> getSubscriptionStatus(
      String androidId) async {
    final data = await _supabase
        .from('users')
        .select()
        .eq('android_id', androidId)
        .single();
    return data;
  }
}
