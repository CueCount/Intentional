import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class MatchCountService {
  static const int _initialCount = 12000;
  static const int _minCount = 25;
  static const int _minReduction = 150;
  static const int _maxReduction = 200;
  
  /// Gets the current refined matches count for the user
  /// Reduces count by random amount on each navigation call
  static Future<int> getRefinedMatchesCount() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return _initialCount;
    
    final prefs = await SharedPreferences.getInstance();
    final key = 'refined_matches_count_$userId';
    
    // Get current count, default to initial if not set
    int currentCount = prefs.getInt(key) ?? _initialCount;
    
    // If we're at or below minimum, don't reduce further
    if (currentCount <= _minCount) {
      return currentCount;
    }
    
    // Calculate random reduction
    final random = Random();
    final reduction = _minReduction + random.nextInt(_maxReduction - _minReduction + 1);
    
    // Apply reduction but don't go below minimum
    int newCount = currentCount - reduction;
    if (newCount < _minCount) {
      newCount = _minCount;
    }
    
    // Save the new count
    await prefs.setInt(key, newCount);
        
    return newCount;
  }
  
  /// Gets the current count without reducing it (for display purposes)
  static Future<int> getCurrentCount() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return _initialCount;
    
    final prefs = await SharedPreferences.getInstance();
    final key = 'refined_matches_count_$userId';
    
    return prefs.getInt(key) ?? _initialCount;
  }
  
  /// Resets the count back to initial value
  static Future<void> resetCount() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final key = 'refined_matches_count_$userId';
    
    await prefs.setInt(key, _initialCount);
  }
  
  /// Sets a specific count (useful for testing or manual adjustments)
  static Future<void> setCount(int count) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final key = 'refined_matches_count_$userId';
    
    await prefs.setInt(key, count);
  }
  
  /// Gets count reduction simulation for testing
  static Map<String, dynamic> simulateReduction(int currentCount) {
    if (currentCount <= _minCount) {
      return {
        'currentCount': currentCount,
        'reduction': 0,
        'newCount': currentCount,
        'atMinimum': true
      };
    }
    
    final random = Random();
    final reduction = _minReduction + random.nextInt(_maxReduction - _minReduction + 1);
    int newCount = currentCount - reduction;
    
    if (newCount < _minCount) {
      newCount = _minCount;
    }
    
    return {
      'currentCount': currentCount,
      'reduction': reduction,
      'newCount': newCount,
      'atMinimum': newCount <= _minCount
    };
  }
}