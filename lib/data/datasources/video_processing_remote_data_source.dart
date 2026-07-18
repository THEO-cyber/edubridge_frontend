import 'dart:convert';
import 'dart:io';

import 'package:edubridge/constants/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as p;

import '../../core/error_handling.dart';

class VideoProcessingRemoteDataSource {
  static MediaType _mediaType(String filePath) {
    switch (p.extension(filePath).toLowerCase()) {
      case '.mp4':  return MediaType('video', 'mp4');
      case '.mov':  return MediaType('video', 'quicktime');
      case '.avi':  return MediaType('video', 'x-msvideo');
      case '.mkv':  return MediaType('video', 'x-matroska');
      case '.webm': return MediaType('video', 'webm');
      case '.3gp':  return MediaType('video', '3gpp');
      default:      return MediaType('video', 'mp4');
    }
  }

  /// POST /video-processing/upload/:lessonId — multipart field "file"
  Future<Map<String, dynamic>> uploadVideo(
    String lessonId,
    String filePath,
    String token,
  ) async {
    final url = ApiConstants.baseUrl + ApiConstants.uploadVideoForLesson(lessonId);

    final request = http.MultipartRequest('POST', Uri.parse(url))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath(
        'video',
        filePath,
        filename: p.basename(filePath),
        contentType: _mediaType(filePath),
      ));

    final streamed = await request.send().timeout(const Duration(minutes: 10));
    final response = await http.Response.fromStream(streamed);


    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    String msg = 'Upload failed (${response.statusCode})';
    try {
      final body = jsonDecode(response.body);
      final errors = body['errors'];
      if (errors is List && errors.isNotEmpty) {
        msg = errors.join('\n');
      } else {
        msg = body['message']?.toString() ?? msg;
      }
    } catch (_) {
      if (response.body.isNotEmpty) msg = response.body;
    }
    throw ApiException(msg, response.statusCode);
  }

  /// GET /video-processing/:videoId/status
  Future<Map<String, dynamic>> getVideoStatus(
      String videoId, String token) async {
    final response = await http.get(
      Uri.parse(ApiConstants.baseUrl + ApiConstants.videoStatus(videoId)),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw ApiException('Status check failed', response.statusCode);
  }

  /// GET /video-processing/stream/:videoId?quality=720p (legacy direct-stream)
  Future<String> getStreamUrl(String videoId, String token,
      {String quality = '720p'}) async {
    final uri = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.videoStream(videoId)}?quality=$quality',
    );
    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = data['url']?.toString() ?? '';
      if (url.isEmpty) throw ApiException('No stream URL in response', 200);
      return url;
    }
    throw ApiException('Stream URL fetch failed', response.statusCode);
  }

  /// POST /video-processing/initiate-upload/:lessonId
  /// Returns { uploadUrl, videoId } — uploadUrl is a presigned MinIO PUT URL.
  Future<Map<String, dynamic>> initiateUpload(
      String lessonId, String token, String filePath) async {
    final url =
        '${ApiConstants.baseUrl}${ApiConstants.initiateUpload(lessonId)}';
    final filename = p.basename(filePath);
    final mimeType = _mediaType(filePath).toString();
    final fileSize = await File(filePath).length();
    final res = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'filename': filename,
        'mimeType': mimeType,
        'fileSize': fileSize,
      }),
    ).timeout(const Duration(seconds: 30));
    if (res.statusCode == 200 || res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    String msg = 'Failed to initiate upload (${res.statusCode})';
    try {
      msg = (jsonDecode(res.body) as Map)['message']?.toString() ?? msg;
    } catch (_) {}
    throw ApiException(msg, res.statusCode);
  }

  /// PUT [uploadUrl] with raw video bytes — direct to MinIO (no auth header).
  Future<void> uploadToStorage(String uploadUrl, String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final contentType = _mediaType(filePath).toString();
    final res = await http
        .put(
          Uri.parse(uploadUrl),
          headers: {'Content-Type': contentType},
          body: bytes,
        )
        .timeout(const Duration(minutes: 15));
    if (res.statusCode != 200 &&
        res.statusCode != 201 &&
        res.statusCode != 204) {
      throw ApiException(
          'Storage upload failed (${res.statusCode})', res.statusCode);
    }
  }

  /// POST /video-processing/complete-upload/:videoId — triggers server-side processing.
  Future<void> completeUpload(String videoId, String token) async {
    final url =
        '${ApiConstants.baseUrl}${ApiConstants.completeUpload(videoId)}';
    final res = await http.post(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    ).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200 && res.statusCode != 201) {
      String msg = 'Failed to complete upload (${res.statusCode})';
      try {
        msg = (jsonDecode(res.body) as Map)['message']?.toString() ?? msg;
      } catch (_) {}
      throw ApiException(msg, res.statusCode);
    }
  }

  /// GET /video-processing/stream-url/:videoId?quality=720p
  /// Returns a CDN-cached URL that does NOT require auth headers to play.
  Future<String> getStreamUrlCdn(String videoId, String token,
      {String quality = '720p'}) async {
    final url =
        '${ApiConstants.baseUrl}${ApiConstants.streamUrlForVideo(videoId)}?quality=$quality';
    final res = await http.get(
      Uri.parse(url),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final cdnUrl = (data['streamUrl'] ?? data['url'] ?? '').toString();
      if (cdnUrl.isEmpty) throw ApiException('No stream URL in response', 200);
      return cdnUrl;
    }
    throw ApiException('Stream URL fetch failed (${res.statusCode})', res.statusCode);
  }
}
