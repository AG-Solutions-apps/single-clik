// lib/utils/cache_manager.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class CacheManager {
  static const String _PREFIX = 'app_cache_';

  /// Save data to cache with timestamp
  ///
  /// [key] - Unique identifier for the cached data
  /// [value] - Data to be cached (will be JSON encoded)
  static Future<void> set(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonValue = jsonEncode(value);
      await prefs.setString('$_PREFIX$key', jsonValue);
      if (kDebugMode) {
        debugPrint('✅ Cache saved for key: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving cache for key $key: $e');
      }
    }
  }

  /// Get data from cache
  ///
  /// [key] - Unique identifier for the cached data
  /// Returns decoded JSON data or null if not found
  static Future<dynamic> get(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('$_PREFIX$key');
      if (jsonString != null) {
        return jsonDecode(jsonString);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error reading cache for key $key: $e');
      }
    }
    return null;
  }

  /// Remove specific cache entry
  ///
  /// [key] - Unique identifier for the cached data to remove
  static Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_PREFIX$key');
      if (kDebugMode) {
        debugPrint('✅ Cache removed for key: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error removing cache for key $key: $e');
      }
    }
  }

  /// Clear all app cache
  /// Removes all entries with the app cache prefix
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_PREFIX));
      for (final key in keys) {
        await prefs.remove(key);
      }
      if (kDebugMode) {
        debugPrint('✅ All cache cleared (${keys.length} entries removed)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error clearing cache: $e');
      }
    }
  }

  /// Check if cache exists and is still valid (not expired)
  ///
  /// [key] - Unique identifier for the cached data
  /// [maxAge] - Maximum allowed age of the cache
  /// Returns true if cache exists and is within maxAge
  static Future<bool> isValid(String key, Duration maxAge) async {
    try {
      final cachedData = await get(key);
      if (cachedData != null && cachedData['timestamp'] != null) {
        final age =
            DateTime.now().difference(DateTime.parse(cachedData['timestamp']));
        return age < maxAge;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking cache validity: $e');
      }
    }
    return false;
  }

  /// Get the age of cached data
  ///
  /// [key] - Unique identifier for the cached data
  /// Returns Duration of cache age or null if not found
  static Future<Duration?> getCacheAge(String key) async {
    try {
      final cachedData = await get(key);
      if (cachedData != null && cachedData['timestamp'] != null) {
        return DateTime.now()
            .difference(DateTime.parse(cachedData['timestamp']));
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting cache age: $e');
      }
    }
    return null;
  }

  /// Check if cache exists (regardless of age)
  ///
  /// [key] - Unique identifier for the cached data
  /// Returns true if cache exists
  static Future<bool> exists(String key) async {
    try {
      final cachedData = await get(key);
      return cachedData != null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking cache existence: $e');
      }
      return false;
    }
  }

  /// Get cache size information
  ///
  /// Returns a map with total entries and total size in bytes
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_PREFIX));
      int totalSize = 0;

      for (final key in keys) {
        final value = prefs.getString(key);
        if (value != null) {
          totalSize += value.length * 2; // Approximate size in bytes (UTF-16)
        }
      }

      return {
        'entryCount': keys.length,
        'totalSizeBytes': totalSize,
        'totalSizeKB': (totalSize / 1024).toStringAsFixed(2),
        'totalSizeMB': (totalSize / (1024 * 1024)).toStringAsFixed(2),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting cache info: $e');
      }
      return {
        'entryCount': 0,
        'totalSizeBytes': 0,
        'totalSizeKB': '0',
        'totalSizeMB': '0',
      };
    }
  }

  /// Clear expired cache entries
  ///
  /// [maxAge] - Maximum allowed age for cache entries
  /// Returns number of entries cleared
  static Future<int> clearExpired(Duration maxAge) async {
    int clearedCount = 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_PREFIX));

      for (final key in keys) {
        final jsonString = prefs.getString(key);
        if (jsonString != null) {
          try {
            final data = jsonDecode(jsonString);
            if (data != null && data['timestamp'] != null) {
              final age =
                  DateTime.now().difference(DateTime.parse(data['timestamp']));
              if (age >= maxAge) {
                await prefs.remove(key);
                clearedCount++;
              }
            }
          } catch (e) {
            // If can't parse, remove it
            await prefs.remove(key);
            clearedCount++;
          }
        }
      }

      if (kDebugMode) {
        debugPrint('✅ Cleared $clearedCount expired cache entries');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error clearing expired cache: $e');
      }
    }
    return clearedCount;
  }

  /// Helper method to save data with automatic timestamp
  ///
  /// [key] - Unique identifier for the cached data
  /// [data] - Data to be cached
  /// [customTimestamp] - Optional custom timestamp (defaults to now)
  static Future<void> saveWithTimestamp(String key, dynamic data,
      {DateTime? customTimestamp}) async {
    final cacheData = {
      'data': data,
      'timestamp': (customTimestamp ?? DateTime.now()).toIso8601String(),
    };
    await set(key, cacheData);
  }

  /// Helper method to get data from timestamped cache
  ///
  /// [key] - Unique identifier for the cached data
  /// Returns just the data part, or null if not found
  static Future<dynamic> getData(String key) async {
    final cachedData = await get(key);
    if (cachedData != null && cachedData['data'] != null) {
      return cachedData['data'];
    }
    return null;
  }

  /// Update only the timestamp of cached data (refresh without changing data)
  ///
  /// [key] - Unique identifier for the cached data
  static Future<void> refreshTimestamp(String key) async {
    try {
      final cachedData = await get(key);
      if (cachedData != null) {
        cachedData['timestamp'] = DateTime.now().toIso8601String();
        await set(key, cachedData);
        if (kDebugMode) {
          debugPrint('✅ Timestamp refreshed for key: $key');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error refreshing timestamp: $e');
      }
    }
  }
}
