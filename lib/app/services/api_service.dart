// services/api_service.dart
import 'dart:convert';
import 'package:four_dimentional_scrolling/app/model/video_model.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static int _currentPage = 1;
  static bool _hasMore = true;

  static Future<List<VideoModel>> fetchMainVideos({bool reset = false}) async {
    if (reset) {
      _currentPage = 1;
      _hasMore = true;
    }

    if (!_hasMore) return [];

    final response = await http.get(Uri.parse('https://api.wemotions.app/feed?page=$_currentPage'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List posts = data['posts'];
      if (posts.isEmpty) {
        _hasMore = false;
      } else {
        _currentPage++;
      }
      return posts.map((json) => VideoModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load main videos');
    }
  }

  static bool get hasMore => _hasMore;
  
  static Future<List<VideoModel>> fetchReplies(int postId) async {
    final response = await http.get(Uri.parse('https://api.wemotions.app/posts/$postId/replies'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List posts = data['post'];
      return posts.map((json) => VideoModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load replies');
    }
  }}
