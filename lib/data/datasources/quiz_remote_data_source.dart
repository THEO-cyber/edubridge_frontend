import '../../core/http_utils.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';

class QuizRemoteDataSource {
  Future<Map<String, dynamic>?> getQuizForLesson(
      String lessonId, String token) async {
    final res = await apiGet(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.quizForLesson(lessonId)),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return null;
  }

  Future<Map<String, dynamic>> startQuiz(
      String quizId, String token) async {
    final res = await apiPost(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.startQuiz(quizId)),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    }
    throw Exception('Failed to start quiz');
  }

  Future<Map<String, dynamic>> submitAttempt(
      String attemptId,
      List<Map<String, dynamic>> answers,
      int timeSpent,
      String token) async {
    final res = await apiPost(
      Uri.parse(
          ApiConstants.baseUrl + ApiConstants.submitQuizAttempt(attemptId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'answers': answers, 'timeSpent': timeSpent}),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    }
    throw Exception('Failed to submit quiz');
  }

  Future<List<dynamic>> getMyAttempts(String quizId, String token) async {
    final res = await apiGet(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.myQuizAttempts(quizId)),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }
}
