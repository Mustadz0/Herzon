import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:herzon/data/models/post_model.dart';

class CacheService {
  static const String _postsBox = 'posts_cache';
  static const String _storiesBox = 'stories_cache';
  static const String _userBox = 'user_cache';

  static Box? _postsCache;
  static Box? _storiesCache;
  static Box? _userCache;

  static Future<void> init() async {
    _postsCache = await Hive.openBox(_postsBox);
    _storiesCache = await Hive.openBox(_storiesBox);
    _userCache = await Hive.openBox(_userBox);
  }

  static Box _getBox(String name) {
    switch (name) {
      case _postsBox:
        return _postsCache!;
      case _storiesBox:
        return _storiesCache!;
      case _userBox:
        return _userCache!;
      default:
        throw Exception('Unknown box: $name');
    }
  }

  static Future<void> cachePosts(List<PostModel> posts) async {
    final box = _getBox(_postsBox);
    final jsonList = posts.map((e) => jsonEncode(e.toJson())).toList();
    await box.put('posts', jsonList);
  }

  static List<PostModel>? getCachedPosts() {
    final box = _getBox(_postsBox);
    final raw = box.get('posts');
    if (raw == null) return null;
    try {
      return (raw as List<dynamic>)
          .map((e) => PostModel.fromJson(jsonDecode(e as String) as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearCache() async {
    await _postsCache?.clear();
    await _storiesCache?.clear();
    await _userCache?.clear();
  }
}
