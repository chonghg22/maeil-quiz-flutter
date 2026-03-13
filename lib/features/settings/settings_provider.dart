import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../quiz/quiz_provider.dart';
import 'settings_repository.dart';

class SubscriptionStatus {
  final bool isPremium;
  final int dailyCount;

  const SubscriptionStatus({required this.isPremium, required this.dailyCount});

  int get remaining => (20 - dailyCount).clamp(0, 20);
}

final subscriptionProvider = FutureProvider<SubscriptionStatus>((ref) async {
  final androidId = await ref.watch(androidIdProvider.future);
  final repo = SettingsRepository();
  final data = await repo.getSubscriptionStatus(androidId);
  return SubscriptionStatus(
    isPremium: data['isPremium'] as bool? ?? false,
    dailyCount: data['dailyCount'] as int? ?? 0,
  );
});
