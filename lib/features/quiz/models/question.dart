class Question {
  final int id;
  final String category;
  final String content;
  final String option1;
  final String option2;
  final String option3;
  final String option4;
  final int correctAnswer;
  final String explanation;

  const Question({
    required this.id,
    required this.category,
    required this.content,
    required this.option1,
    required this.option2,
    required this.option3,
    required this.option4,
    required this.correctAnswer,
    required this.explanation,
  });

  List<String> get options => [option1, option2, option3, option4];

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int,
      category: json['category'] as String,
      content: json['content'] as String,
      option1: json['option1'] as String,
      option2: json['option2'] as String,
      option3: json['option3'] as String,
      option4: json['option4'] as String,
      correctAnswer: json['correct_answer'] as int,
      explanation: json['explanation'] as String,
    );
  }
}
