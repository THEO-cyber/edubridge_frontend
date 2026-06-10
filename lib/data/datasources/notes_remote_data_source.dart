import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constants.dart';

class NotesRemoteDataSource {
  Future<List<dynamic>> getNotesForLesson(
      String lessonId, String token) async {
    final res = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.notesForLesson(lessonId)),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  Future<List<dynamic>> getAllNotes(String token) async {
    final res = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.notes),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  Future<Map<String, dynamic>> createNote(
      String lessonId, String content, int? timestamp, String token) async {
    final res = await http.post(
      Uri.parse(
          ApiConstants.baseUrl + ApiConstants.notesForLesson(lessonId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'content': content,
        if (timestamp != null) 'timestamp': timestamp,
      }),
    );
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body);
    }
    throw Exception('Failed to save note');
  }

  Future<void> updateNote(
      String noteId, String content, String token) async {
    await http.patch(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.noteById(noteId)),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'content': content}),
    );
  }

  Future<void> deleteNote(String noteId, String token) async {
    await http.delete(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.noteById(noteId)),
      headers: {'Authorization': 'Bearer $token'},
    );
  }
}
