import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = true;
  bool _isPremium = false;
  int _remaining = 20;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final androidId = prefs.getString(androidIdKey) ?? '';
      if (androidId.isEmpty) return;

      final result = await Supabase.instance.client
          .from('users')
          .select('daily_count, is_premium')
          .eq('android_id', androidId)
          .single();

      final remaining =
          (20 - (result['daily_count'] as int? ?? 0)).clamp(0, 20);

      if (mounted) {
        setState(() {
          _isPremium = result['is_premium'] as bool? ?? false;
          _remaining = remaining;
        });
      }
    } catch (_) {
      // 조회 실패 시 기본값 유지
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('설정', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF6B21A8),
        elevation: 0,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _SectionHeader(title: '구독'),
          _SubscriptionTile(
            isPremium: _isPremium,
            remaining: _remaining,
            isLoading: _isLoading,
          ),
          if (!_isLoading && !_isPremium)
            _SettingsTile(
              icon: Icons.workspace_premium,
              iconColor: const Color(0xFFF59E0B),
              title: '프리미엄 구독',
              subtitle: '무제한 퀴즈 + 프리미엄 문제',
              onTap: () => context.push('/payment'),
            ),
          const SizedBox(height: 16),
          _SectionHeader(title: '퀴즈 설정'),
          _SettingsTile(
            icon: Icons.category,
            iconColor: const Color(0xFF6B21A8),
            title: '카테고리 설정',
            subtitle: '관심 카테고리를 선택하세요',
            onTap: () => context.push('/categories').then((changed) {
              if (changed == true) context.pop(true);
            }),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SubscriptionTile extends StatelessWidget {
  final bool isPremium;
  final int? remaining;
  final bool isLoading;

  const _SubscriptionTile({
    required this.isPremium,
    required this.remaining,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isPremium
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.1)
                    : const Color(0xFF6B21A8).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPremium ? Icons.workspace_premium : Icons.person,
                color: isPremium
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFF6B21A8),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: isLoading
                  ? const Text('불러오는 중...',
                      style: TextStyle(color: Colors.black54))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPremium ? '프리미엄 회원' : '무료 회원',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isPremium
                              ? '무제한 퀴즈 이용 중'
                              : '오늘 남은 퀴즈: ${remaining ?? 0}개',
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        subtitle:
            Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      ),
    );
  }
}
