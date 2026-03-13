import '../../core/api/api_client.dart';
import 'models/answer_result.dart';
import 'models/question.dart';

class QuizRepository {
  final _api = ApiClient().dio;

  Future<List<Question>> fetchFeed({
    required String androidId,
    required int cursor,
    int size = 10,
  }) async {
    final response = await _api.get(
      '/api/v1/questions/feed',
      queryParameters: {
        'androidId': androidId,
        'cursor': cursor,
        'size': size,
      },
    );

    final data = response.data['data'];
    final List<dynamic> list = data is List ? data : [];
    return list.map((e) => Question.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AnswerResult> submitAnswer({
    required int questionId,
    required String androidId,
    required int answer,
  }) async {
    final response = await _api.post(
      '/api/v1/questions/$questionId/answer',
      data: {'androidId': androidId, 'answer': answer},
    );

    return AnswerResult.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}
