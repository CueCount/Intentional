import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';

class UserSyncProvider extends ChangeNotifier {
  // Private variables
  StreamSubscription<QuerySnapshot>? _usersListener;
  String? _currentUserId;
  bool _isListening = false;
  
  // Public getters
  bool get isListening => _isListening;
  String? get currentUserId => _currentUserId;
  
  // Cached user data
  List<Map<String, dynamic>> _allUsers = [];
  
  // Getters for cached data
  List<Map<String, dynamic>> get allUsers => List.from(_allUsers);
  
  /* = = = = = = = = = 
  Start / Stop Listening
  = = = = = = = = = */

  Future<void> startListening(String userId) async {
    if (_isListening && _currentUserId == userId) {
      if (kDebugMode) {
        print('User Provider: Already listening for user: $userId');
      }
      return;
    }
    
    await stopListening();
    _currentUserId = userId;
    
    try {
      // Initial sync from Firebase to populate cache
      await _initialSync(userId);
      
      // Start real-time listener for available users
      _startUsersListener(userId);
      
      _isListening = true;
      notifyListeners();
      
      if (kDebugMode) {
        print('User Provider: Started listening for available users');
      }
    } catch (e) {
      if (kDebugMode) {
        print('User Provider Error: Failed to start listening - $e');
      }
    }
  }
  
  Future<void> stopListening() async {
    await _usersListener?.cancel();
    
    _usersListener = null;
    _currentUserId = null;
    _isListening = false;
    
    notifyListeners();
    
    if (kDebugMode) {
      print('User Provider: Stopped listening');
    }
  }
  
  void _startUsersListener(String userId) {
    _usersListener = FirebaseFirestore.instance
        .collection('users')
        // Remove the available filter - get all users
        .snapshots()
        .listen(
          (snapshot) => _handleUserChanges(snapshot, userId),
          onError: (error) {
            if (kDebugMode) {
              print('User Provider Error: Listener error - $error');
            }
          },
        );
  }
  
  /* = = = = = = = = = 
  Handle Changes
  = = = = = = = = = */

  Future<void> _handleUserChanges(QuerySnapshot snapshot, String userId) async {
    try {
      // Get all users except current user
      final allUsers = snapshot.docs
          .where((doc) => doc.id != userId)
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'userId': doc.id,
              'nameFirst': data['nameFirst'],
              'birthDate': _convertDateToString(data['birthDate']),
              'photos': data['photos'],
              'location': _convertGeoPointToMap(data['location']),
              // Add placeholder for future filters
              'filters': _applyUserFilters(data), // Placeholder for future filtering
            };
          })
          .toList();
    
      
      // Save to SharedPreferences
      await _saveUsersToSharedPrefs(allUsers, userId);
      
      notifyListeners();

    } catch (e) {
      if (kDebugMode) {
        print('User Provider Error: Failed to handle user changes - $e');
      }
    }
  }
  
  Map<String, dynamic> _applyUserFilters(Map<String, dynamic> userData) {
    // TODO: Add filtering logic based on user preferences
    // Example: age range, location radius, interests, etc.
    return {
      'passesAgeFilter': true,
      'passesLocationFilter': true,
      'passesInterestFilter': true,
    };
  }
  
  /* = = = = = = = = = 
  Fetching and Saving Data 
  = = = = = = = = = */

  Future<void> _initialSync(String userId) async {
    try {
      // Load cached data first
      await _loadUsersFromSharedPrefs(userId);
      
      // Check if Firebase sync is needed
      final shouldSync = await _shouldSyncFromFirebase(userId);
      
      if (shouldSync) {
        if (kDebugMode) {
          print('User Provider: Syncing from Firebase due to stale/missing cache');
        }
        
        // Sync from Firebase
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .get();
        
        await _handleUserChanges(usersSnapshot, userId);
        
        // Update sync timestamp
        await _updateLastSyncTimestamp(userId);
      } else {
        if (kDebugMode) {
          print('User Provider: Using cached data (fresh)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('User Provider Error: Initial sync failed - $e');
      }
    }
  }
  
  Future<void> _loadUsersFromSharedPrefs(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final usersJson = prefs.getStringList('users_$userId') ?? [];
      _allUsers = usersJson.map((jsonString) => 
        Map<String, dynamic>.from(jsonDecode(jsonString))
      ).toList();
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('User Provider Error: Failed to load from SharedPreferences - $e');
      }
    }
  }
  
  Future<void> _saveUsersToSharedPrefs(List<Map<String, dynamic>> users, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = users.map((user) => jsonEncode(user)).toList();
      await prefs.setStringList('users_$userId', usersJson);
    } catch (e) {
      if (kDebugMode) {
        print('User Provider Error: Failed to save to SharedPreferences - $e');
      }
    }
  }
  
  List<Map<String, dynamic>> getAllUsers() {
    print('UserProvider getAllUsers called: ${_allUsers.length} users available');
    return List.from(_allUsers);
  }

  /* = = = = = = = = = 
  Helper Methods
  = = = = = = = = = */
  
  Future<bool> _shouldSyncFromFirebase(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we have cached data
      final cachedUsers = prefs.getStringList('users_$userId');
      
      if (cachedUsers?.isEmpty ?? true) {
        return true;
      }
      
      // Check last sync timestamp
      final lastSyncString = prefs.getString('last_user_sync_$userId');
      if (lastSyncString == null) {
        return true;
      }
      
      final lastSync = DateTime.parse(lastSyncString);
      final now = DateTime.now();
      final timeDifference = now.difference(lastSync);
      
      // Sync if last sync was more than 10 minutes ago (users change less frequently)
      const syncThreshold = Duration(minutes: 10);
      return timeDifference > syncThreshold;
      
    } catch (e) {
      if (kDebugMode) {
        print('User Provider Error: Failed to check sync status - $e');
      }
      return true;
    }
  }
  
  Future<void> _updateLastSyncTimestamp(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_user_sync_$userId', DateTime.now().toIso8601String());
    } catch (e) {
      if (kDebugMode) {
        print('User Provider Error: Failed to update sync timestamp - $e');
      }
    }
  }

  String? _convertDateToString(dynamic dateValue) {
    if (dateValue == null) return null;
    
    try {
      if (dateValue is Timestamp) {
        // Firebase Timestamp
        return dateValue.toDate().toIso8601String();
      } else if (dateValue is int) {
        // Unix timestamp in milliseconds
        return DateTime.fromMillisecondsSinceEpoch(dateValue).toIso8601String();
      } else if (dateValue is String) {
        // Already a string
        return dateValue;
      } else {
        // Unknown format
        return null;
      }
    } catch (e) {
      print('Error converting date: $dateValue, error: $e');
      return null;
    }
  }

  Map<String, dynamic>? _convertGeoPointToMap(dynamic geoValue) {
    if (geoValue == null) return null;
    
    try {
      if (geoValue is GeoPoint) {
        return {
          'latitude': geoValue.latitude,
          'longitude': geoValue.longitude,
        };
      } else if (geoValue is Map) {
        // Already converted
        return Map<String, dynamic>.from(geoValue);
      } else {
        return null;
      }
    } catch (e) {
      print('Error converting GeoPoint: $geoValue, error: $e');
      return null;
    }
  }

  /* = = = = = = = = = 
  Override
  = = = = = = = = = */

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

}