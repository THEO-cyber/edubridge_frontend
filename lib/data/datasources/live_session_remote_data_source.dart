import 'dart:convert';
import 'package:edubridge/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import '../../core/error_handling.dart';

class LiveSessionRemoteDataSource {
  Future<List<Map<String, dynamic>>> fetchLiveSessions(String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.liveSessions),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw ApiException('Failed to fetch live sessions', response.statusCode);
    }
  }

  Future<void> requestLiveSession(
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.liveSessionRequest),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Failed to request live session', response.statusCode);
    }
  }

  Future<void> joinLiveSession(String sessionId, String token) async {
    final response = await http.post(
      Uri.parse(
        ApiConstants.baseUrl + ApiConstants.joinLiveSession + '$sessionId/join',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw ApiException('Failed to join live session', response.statusCode);
    }
  }
}
