import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/answer_result.dart';
import 'models/question.dart';

class QuizRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Question>> fetchFeed({
    required String androidId,
    required int cursor,
    String category = '',
    int size = 10,
  }) async {
    final data = await _supabase.rpc('get_quiz_feed', params: {
      'p_android_id': androidId,
      'p_category': category,
      'p_cursor': cursor,
      'p_size': size,
    });

    final List<dynamic> list = data is List ? data : [];
    return list
        .map((e) => Question.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AnswerResult> submitAnswer({
    required int questionId,
    required String androidId,
    required bool isCorrect,
    required int correctAnswer,
    required String explanation,
  }) async {
    final userResult = await _supabase
        .from('users')
        .select('id')
        .eq('android_id', androidId)
        .single();
    final userId = userResult['id'];

    try {
      await _supabase.from('user_history').insert({
        'user_id': userId,
        'question_id': questionId,
        'is_correct': isCorrect,
      });
    } catch (_) {
      // 히스토리 저장 실패해도 일일 카운트는 증가
    }

    await _supabase.rpc('increment_daily_count',
        params: {'p_android_id': androidId});

    return AnswerResult(
      correct: isCorrect,
      answer: correctAnswer,
      explanation: explanation,
    );
  }
}
