import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/ad_banner_widget.dart';
import '../../shared/widgets/ad_interstitial_helper.dart';
import 'models/answer_result.dart';
import 'models/question.dart';
import 'quiz_provider.dart';

class QuizFeedScreen extends ConsumerStatefulWidget {
  const QuizFeedScreen({super.key});

  @override
  ConsumerState<QuizFeedScreen> createState() => _QuizFeedScreenState();
}

class _QuizFeedScreenState extends ConsumerState<QuizFeedScreen> {
  final _pageController = PageController();
  final _adInterstitial = AdInterstitialHelper();
  int _answerCount = 0;

  @override
  void initState() {
    super.initState();
    _adInterstitial.preload();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _adInterstitial.dispose();
    super.dispose();
  }

  void _onPageChanged(int index, QuizState quizState) {
    // 마지막 2개 남으면 추가 로딩
    if (index >= quizState.questions.length - 2) {
      ref.read(quizProvider.notifier).loadMore();
    }
  }

  void _goToNextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _onNext() {
    if (_answerCount > 0 && _answerCount % 15 == 0) {
      _adInterstitial.show(onDismissed: _goToNextPage);
    } else {
      _goToNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(quizProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      bottomNavigationBar: const AdBannerWidget(),
      appBar: AppBar(
        title: const Text('매일퀴즈', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF6B21A8),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings').then((categoryChanged) {
              if (categoryChanged == true) {
                ref.invalidate(quizProvider);
              }
            }),
          ),
        ],
      ),
      body: quizAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6B21A8))),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('퀴즈를 불러올 수 없습니다\n$e', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(quizProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
        data: (quizState) {
          if (quizState.questions.isEmpty) {
            return const Center(child: Text('오늘의 퀴즈를 모두 풀었어요! 내일 다시 오세요.'));
          }

          return PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) => _onPageChanged(index, quizState),
            itemCount: quizState.questions.length + (quizState.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= quizState.questions.length) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF6B21A8)));
              }
              final question = quizState.questions[index];
              final selected = quizState.selectedAnswers[question.id];
              final result = quizState.answerResults[question.id];
              final isLoading = quizState.loadingQuestions.contains(question.id);

              return _QuizCard(
                question: question,
                selectedAnswer: selected,
                answerResult: result,
                isSubmitting: isLoading,
                onAnswerSelected: (answer) {
                  if (selected == null && !isLoading) {
                    ref.read(quizProvider.notifier).submitAnswer(question.id, answer);
                    setState(() => _answerCount++);
                  }
                },
                onNext: _onNext,
              );
            },
          );
        },
      ),
    );
  }
}

class _QuizCard extends StatelessWidget {
  final Question question;
  final int? selectedAnswer;
  final AnswerResult? answerResult;
  final bool isSubmitting;
  final ValueChanged<int> onAnswerSelected;
  final VoidCallback onNext;

  const _QuizCard({
    required this.question,
    required this.selectedAnswer,
    required this.answerResult,
    required this.isSubmitting,
    required this.onAnswerSelected,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 카테고리 배지
              _CategoryBadge(category: question.category),
              const SizedBox(height: 20),

              // 문제 내용
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.content,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 보기 버튼 4개
                      ...List.generate(4, (i) {
                        final optionIndex = i + 1;
                        final optionText = question.options[i];
                        return _OptionButton(
                          index: optionIndex,
                          text: optionText,
                          selectedAnswer: selectedAnswer,
                          correctAnswer: answerResult?.answer,
                          isSubmitting: isSubmitting,
                          onTap: () => onAnswerSelected(optionIndex),
                        );
                      }),

                      // 해설
                      if (answerResult != null) ...[
                        const SizedBox(height: 16),
                        _ExplanationBox(
                          correct: answerResult!.correct,
                          explanation: answerResult!.explanation,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: onNext,
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('다음 문제'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B21A8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 스크롤 힌트 (답변 전에만 표시)
              if (selectedAnswer == null && !isSubmitting)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 28),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String category;

  const _CategoryBadge({required this.category});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF6B21A8).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: Color(0xFF6B21A8),
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _OptionButton extends StatelessWidget {
  final int index;
  final String text;
  final int? selectedAnswer;
  final int? correctAnswer;
  final bool isSubmitting;
  final VoidCallback onTap;

  const _OptionButton({
    required this.index,
    required this.text,
    required this.selectedAnswer,
    required this.correctAnswer,
    required this.isSubmitting,
    required this.onTap,
  });

  Color _getBackgroundColor() {
    if (selectedAnswer == null) return const Color(0xFFF8F8F8);
    // 로딩 중: 선택한 보기만 노란색
    if (isSubmitting && index == selectedAnswer) return Colors.amber.withValues(alpha: 0.1);
    if (correctAnswer != null && index == correctAnswer) return const Color(0xFFDCFCE7);
    if (index == selectedAnswer && selectedAnswer != correctAnswer) return const Color(0xFFFFE4E6);
    return const Color(0xFFF8F8F8);
  }

  Color _getBorderColor() {
    if (selectedAnswer == null) return const Color(0xFFE5E7EB);
    // 로딩 중: 선택한 보기만 노란색
    if (isSubmitting && index == selectedAnswer) return Colors.amber;
    if (correctAnswer != null && index == correctAnswer) return const Color(0xFF22C55E);
    if (index == selectedAnswer && selectedAnswer != correctAnswer) return const Color(0xFFEF4444);
    return const Color(0xFFE5E7EB);
  }

  Color _getTextColor() {
    if (selectedAnswer == null) return const Color(0xFF374151);
    // 로딩 중: 선택한 보기만 노란색
    if (isSubmitting && index == selectedAnswer) return Colors.amber.shade700;
    if (correctAnswer != null && index == correctAnswer) return const Color(0xFF16A34A);
    if (index == selectedAnswer && selectedAnswer != correctAnswer) return const Color(0xFFDC2626);
    return const Color(0xFF9CA3AF);
  }

  bool get _isSelected => selectedAnswer == index;

  @override
  Widget build(BuildContext context) {
    // 로딩 중이거나 이미 선택된 경우 모든 버튼 비활성화
    final isDisabled = isSubmitting || selectedAnswer != null;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _getBackgroundColor(),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _getBorderColor(), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: _getBorderColor().withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _getBorderColor(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 15,
                        color: _getTextColor(),
                        fontWeight: selectedAnswer != null && index == correctAnswer
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                  // 선택한 버튼에만 스피너 표시
                  if (isSubmitting && _isSelected) ...[
                    const SizedBox(width: 8),
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF6B21A8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExplanationBox extends StatelessWidget {
  final bool correct;
  final String explanation;

  const _ExplanationBox({required this.correct, required this.explanation});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: correct ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: correct ? const Color(0xFF86EFAC) : const Color(0xFFFCD34D),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            correct ? Icons.check_circle_outline : Icons.info_outline,
            color: correct ? const Color(0xFF16A34A) : const Color(0xFFD97706),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  correct ? '정답입니다!' : '오답입니다',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: correct ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  explanation,
                  style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF374151)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
