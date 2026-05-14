import 'dart:convert';

import 'package:edubridge/constants/api_constants.dart';
import 'package:http/http.dart' as http;

import '../../core/error_handling.dart';

class VideoProcessingRemoteDataSource {
  Future<Map<String, dynamic>> uploadLessonVideo(
    String filePath,
    String token, {
    String? lessonId,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(ApiConstants.baseUrl + ApiConstants.uploadVideo),
    )..headers['Authorization'] = 'Bearer $token';

    if (lessonId != null && lessonId.isNotEmpty) {
      request.fields['lessonId'] = lessonId;
    }

    request.files.add(await http.MultipartFile.fromPath('video', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Failed to upload lesson video', response.statusCode);
  }
}
