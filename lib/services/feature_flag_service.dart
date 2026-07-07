import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeatureFlagService {
  static Map<String, dynamic> _flags = {};
  static Map<String, String> _experiments = {};
  static const String _cacheBoxName = 'feature_flags';
  static Box? _cacheBox;

  static Future<void> init() async {
    _cacheBox = await Hive.openBox(_cacheBoxName);
    await _loadFromCache();
    await refresh();
  }

  static Future<void> _loadFromCache() async {
    if (_cacheBox == null) return;
    final cached = _cacheBox!.get('flags') as Map?;
    if (cached != null) {
      _flags = Map<String, dynamic>.from(cached);
    }
    final cachedExp = _cacheBox!.get('experiments') as Map?;
    if (cachedExp != null) {
      _experiments = Map<String, String>.from(
        (cachedExp).map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        ),
      );
    }
  }

  static Future<void> refresh() async {
    try {
      final client = Supabase.instance.client;
      final flagsResult = await client.rpc('get_user_feature_flags');
      if (flagsResult is Map<String, dynamic>) {
        _flags = flagsResult;
      }

      final expResult = await client.rpc('get_user_experiments');
      if (expResult is List) {
        for (final row in expResult) {
          if (row is Map<String, dynamic>) {
            _experiments[row['experiment_name'] as String] =
                row['variant_name'] as String;
          }
        }
      }
      await _saveToCache();
    } catch (e) {
      // Use cached defaults if RPC fails
      if (_flags.isEmpty) {
        _flags = _defaultFlags();
      }
    }
  }

  static Map<String, dynamic> _defaultFlags() => {
    'show_ridesharing': {'enabled': false},
    'show_polls': {'enabled': true},
    'show_pages': {'enabled': false},
    'show_gamification': {'enabled': true},
    'max_post_length': {'value': 500},
    'nearby_radius': {'value': 2000},
  };

  static Future<void> _saveToCache() async {
    if (_cacheBox == null) return;
    await _cacheBox!.put('flags', _flags);
    await _cacheBox!.put('experiments', _experiments);
  }

  static bool isEnabled(String key, {bool defaultValue = false}) {
    final value = _flags[key];
    if (value is bool) return value;
    if (value is Map && value['enabled'] is bool) {
      return value['enabled'] as bool;
    }
    return defaultValue;
  }

  static dynamic getValue(String key, {dynamic defaultValue}) {
    return _flags.containsKey(key) ? _flags[key] : defaultValue;
  }

  static String getExperimentVariant(
    String experimentName, {
    String defaultVariant = 'control',
  }) {
    return _experiments[experimentName] ?? defaultVariant;
  }
}
