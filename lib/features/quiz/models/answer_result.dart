class AnswerResult {
  final bool correct;
  final int answer;
  final String explanation;

  const AnswerResult({
    required this.correct,
    required this.answer,
    required this.explanation,
  });

  factory AnswerResult.fromJson(Map<String, dynamic> json) {
    return AnswerResult(
      correct: json['correct'] as bool,
      answer: json['answer'] as int,
      explanation: json['explanation'] as String,
    );
  }
}
