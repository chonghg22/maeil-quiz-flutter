import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/app_constants.dart';
import 'models/answer_result.dart';
import 'models/question.dart';
import 'quiz_repository.dart';

// androidId provider
final androidIdProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(androidIdKey) ?? '';
});

// Quiz state
class QuizState {
  final List<Question> questions;
  final int cursor;
  final bool isLoadingMore;
  final bool hasMore;
  final String category;
  final bool isDailyLimitReached;
  final Map<int, AnswerResult> answerResults; // questionId -> result
  final Map<int, int> selectedAnswers; // questionId -> selected option (1-4)
  final Set<int> loadingQuestions; // 답변 제출 중인 questionId

  const QuizState({
    this.questions = const [],
    this.cursor = 0,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.category = 'IT',
    this.isDailyLimitReached = false,
    this.answerResults = const {},
    this.selectedAnswers = const {},
    this.loadingQuestions = const {},
  });

  QuizState copyWith({
    List<Question>? questions,
    int? cursor,
    bool? isLoadingMore,
    bool? hasMore,
    String? category,
    bool? isDailyLimitReached,
    Map<int, AnswerResult>? answerResults,
    Map<int, int>? selectedAnswers,
    Set<int>? loadingQuestions,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      cursor: cursor ?? this.cursor,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      category: category ?? this.category,
      isDailyLimitReached: isDailyLimitReached ?? this.isDailyLimitReached,
      answerResults: answerResults ?? this.answerResults,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      loadingQuestions: loadingQuestions ?? this.loadingQuestions,
    );
  }
}

class QuizNotifier extends AsyncNotifier<QuizState> {
  final _repo = QuizRepository();

  @override
  Future<QuizState> build() async {
    final androidId = await ref.watch(androidIdProvider.future);

    String category = 'IT';
    try {
      final userResult = await Supabase.instance.client
          .from('users')
          .select('categories')
          .eq('android_id', androidId)
          .maybeSingle();

      if (userResult != null && userResult['categories'] != null) {
        final categories = userResult['categories'];
        if (categories is List && categories.isNotEmpty) {
          category = categories[0].toString();
        } else if (categories is String && categories.isNotEmpty) {
          category = categories;
        }
      }
    } catch (e) {
      debugPrint('categories fetch error: $e');
      // 네트워크 오류 시 기본 카테고리(IT)로 진행
    }

    final questions = await _repo.fetchFeed(
      androidId: androidId,
      cursor: 0,
      category: category,
    );
    final nextCursor = questions.isNotEmpty ? questions.last.id : 0;
    return QuizState(
      questions: questions,
      cursor: nextCursor,
      hasMore: questions.length >= 10,
      category: category,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final androidId = await ref.read(androidIdProvider.future);
      final more = await _repo.fetchFeed(
        androidId: androidId,
        cursor: current.cursor,
        category: current.category,
      );
      final nextCursor = more.isNotEmpty ? more.last.id : current.cursor;
      state = AsyncData(current.copyWith(
        questions: [...current.questions, ...more],
        cursor: nextCursor,
        isLoadingMore: false,
        hasMore: more.length >= 10,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> submitAnswer(int questionId, int answer) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // 선택한 보기 + 로딩 상태 즉시 반영
    state = AsyncData(current.copyWith(
      selectedAnswers: {...current.selectedAnswers, questionId: answer},
      loadingQuestions: {...current.loadingQuestions, questionId},
    ));

    try {
      final androidId = await ref.read(androidIdProvider.future);
      final question =
          current.questions.firstWhere((q) => q.id == questionId);
      final isCorrect = answer + 1 == question.correctAnswer; // answer: 0-based, correctAnswer: 1-based
      final result = await _repo.submitAnswer(
        questionId: questionId,
        androidId: androidId,
        isCorrect: isCorrect,
        correctAnswer: question.correctAnswer,
        explanation: question.explanation,
      );
      bool isDailyLimitReached = false;
      try {
        final countResult = await Supabase.instance.client
            .from('users')
            .select('daily_count')
            .eq('android_id', androidId)
            .single();
        isDailyLimitReached = (countResult['daily_count'] as int) >= 20;
      } catch (_) {}

      final updated = state.valueOrNull ?? current;
      state = AsyncData(updated.copyWith(
        answerResults: {...updated.answerResults, questionId: result},
        loadingQuestions: {...updated.loadingQuestions}..remove(questionId),
        isDailyLimitReached: isDailyLimitReached,
      ));
    } catch (_) {
      final updated = state.valueOrNull ?? current;
      state = AsyncData(updated.copyWith(
        loadingQuestions: {...updated.loadingQuestions}..remove(questionId),
      ));
    }
  }
}

final quizProvider = AsyncNotifierProvider<QuizNotifier, QuizState>(
  QuizNotifier.new,
);
