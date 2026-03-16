import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _userRepo = UserRepository();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final androidId = await _userRepo.getOrCreateAndroidId();
      await _userRepo.register(androidId);
      await _resetDailyCountIfNeeded(androidId);
    } catch (e) {
      debugPrint('init error: $e');
    }

    if (mounted) context.go('/quiz');
  }

  Future<void> _resetDailyCountIfNeeded(String androidId) async {
    final supabase = Supabase.instance.client;
    final today = DateTime.now().toLocal().toString().substring(0, 10);
    await supabase
        .from('users')
        .update({
          'daily_count': 0,
          'daily_reset_at': DateTime.now().toIso8601String(),
        })
        .eq('android_id', androidId)
        .lt('daily_reset_at', today);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B21A8),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '매일퀴즈',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '매일 새로운 지식을 채우세요',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}
