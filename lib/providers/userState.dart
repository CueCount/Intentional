import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'matchState.dart';

class UserSyncProvider extends ChangeNotifier {
  // Private variables
  String? _currentUserId;
  bool _isListening = false;
  
  // Public getters
  bool get isListening => _isListening;
  String? get currentUserId => _currentUserId;

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }
  
  /* = = = = = = = = = 
  NOT DOING THIS RIGHT NOW DUE TO READ COSTS
  Listen for User Changes:
  Listen to IDs in current_sesh_IDs
  If the Doc is deleted clear it
  If the Doc is in active match clear it
  = = = = = = = = = */

  /* = = = = = = = = = 
  Load Users:
  Look at current_sesh_IDs
  Grab Docs from Shared Pref
  Query Firebase for Docs not in Shared Pref
  Return Docs
  = = = = = = = = = */ 

  Future<List<Map<String, dynamic>>> loadUsers() async {
    if (kDebugMode) {
      print('loadUsers called, currentUserId: $_currentUserId');
    }
    try {
      if (_currentUserId == null) {
        if (kDebugMode) {
          print('User Provider Error: No current user ID set');
        }
        return [];
      }

      // Get current session IDs from SharedPreferences
      final sessionUserIds = await _getCurrentSessionUserIds(_currentUserId!);
      
      if (sessionUserIds.isEmpty) {
        if (kDebugMode) {
          print('User Provider: No session user IDs found');
        }
        return [];
      }

      if (kDebugMode) {
        print('User Provider: Loading ${sessionUserIds.length} users from $_currentUserId');
      }

      final List<Map<String, dynamic>> loadedUsers = [];

      // Process each user ID in the session
      for (String userId in sessionUserIds) {
        try {
          // Try to get user data from SharedPreferences cache
          Map<String, dynamic>? userData = await _getUserFromCache(userId, _currentUserId!);
          
          if (userData != null) {
            loadedUsers.add(userData);
            if (kDebugMode) {
              print('User Provider: Loaded $userId from cache');
            }
          } else {
            // User data missing from cache - fetch from Firebase
            if (kDebugMode) {
              print('User Provider: User $userId missing, fetching from Firebase');
            }
            
            userData = await getUserByID(userId);
            
            if (userData != null) {
              // Store the fetched user data in cache
              await _storeUserInCache(userData, _currentUserId!);
              loadedUsers.add(userData);
              
              if (kDebugMode) {
                print('User Provider: Fetched and cached $userId from Firebase');
              }
            } else {
              if (kDebugMode) {
                print('User Provider Warning: Could not fetch user $userId from Firebase');
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('User Provider Error: Failed to load user $userId - $e');
          }
          // Skip this user and continue with others
          continue; 
        }
      }

      return loadedUsers;

    } catch (e) {
      if (kDebugMode) {
        print('User Provider Error: Failed to load users - $e');
      }
      return [];
    }
  }

  Future<List<String>> _getCurrentSessionUserIds(String currentUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInputsJson = prefs.getString('inputs_$currentUserId');
      
      if (userInputsJson != null) {
        final userInputs = jsonDecode(userInputsJson);
        final sessionList = userInputs['currentSeshList'];
        
        if (sessionList is List) {
          return List<String>.from(sessionList);
        }
      }
      
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('User Provider Error: Failed to get session user IDs - $e');
      }
      return [];
    }
  }

  Future<Map<String, dynamic>?> _getUserFromCache(String userId, String currentSessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get the StringList of all users for this session
      final usersList = prefs.getStringList('users_$currentSessionId') ?? [];
      
      // Search through the list for the specific user
      for (String userJson in usersList) {
        final userData = jsonDecode(userJson);
        if (userData['userId'] == userId) {
          return Map<String, dynamic>.from(userData);
        }
      }
      
      // User not found in the list
      return null;
      
    } catch (e) {
      if (kDebugMode) {
        print('User Provider Error: Failed to get user $userId from cache - $e');
      }
      return null;
    }
  }

  Future<void> _storeUserInCache(Map<String, dynamic> userData, String currentSessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = userData['userId'];
      
      if (userId != null) {
        // Get existing list or create empty
        List<String> usersList = prefs.getStringList('users_$currentSessionId') ?? [];
        
        // Check if user already exists and update, or add new
        bool found = false;
        for (int i = 0; i < usersList.length; i++) {
          final existingUser = jsonDecode(usersList[i]);
          if (existingUser['userId'] == userId) {
            usersList[i] = jsonEncode(userData);  // Update existing
            found = true;
            break;
          }
        }
        
        if (!found) {
          usersList.add(jsonEncode(userData));  // Add new
        }
        
        // Save updated list
        await prefs.setStringList('users_$currentSessionId', usersList);
        
        if (kDebugMode) {
          print('User Provider: Stored $userId -> users_$currentSessionId (${usersList.length} users total)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('User Provider Error: Failed to store user in cache - $e');
      }
    }
  }

  Future<Map<String, dynamic>?> getUserByID(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'userId': doc.id,
          'nameFirst': data['nameFirst'],
          'birthDate': _convertDateToString(data['birthDate']),
          'photos': data['photos'],
          'location': _convertGeoPointToMap(data['location']),
          // Add any other fields you need
        };
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('User Provider Error: Failed to get user $userId by ID - $e');
      }
      return null;
    }
  }

  /* = = = = = = = = = 
  Refresh Triggered:
  Grab current_sesh_IDs
  Send all to ignore_IDs list except those with Match Docs status = "ignored" || "pending"
  Grab Need Inputs from current ID in Input Provider
  Send them to Filter Function
  Return Seeking Inputs
  Query Firebase for Docs matching Seeking Inputs
  Return User Docs, Save to Shared Pref users_currentseshID and save IDs to current_sesh_IDs list
  Grab all Inputs and Lists from current ID in Input Provider
  Sync them to Firebase User Doc
  Trigger Route to Matches Page (which itself will grab new Docs)
  = = = = = = = = = */ 

  Future<void> refreshDiscoverableUsers(BuildContext context) async {
    if (kDebugMode) {
      print("Refresh Triggered:");
    }
    try {
      if (_currentUserId == null) return;

      final currentSeshIds = await _getCurrentSessionUserIds(_currentUserId!);
      final ignoreIds = await _getIgnoreIds(_currentUserId!);
      final userInputs = await _getUserInputs(_currentUserId!);
      final seekingInputs = _buildSeekingFilters(userInputs);
      
      final newUsers = await _queryFilteredUsers(seekingInputs, ignoreIds);
      final newUserIds = newUsers.map((user) => user['userId'] as String).toList();
      
      await _saveNewSession(newUsers, newUserIds, _currentUserId!);
      await _syncInputsToFirebase(userInputs, _currentUserId!);
      
      if (kDebugMode) {
        print('User Provider: Refreshed ${newUsers.length} discoverable users');
      }
      
      Navigator.pushNamed(context, '/matches');
      
    } catch (e) {
      if (kDebugMode) {
        print('User Provider Error: Refresh failed - $e');
      }
    }
  }

  Future<List<String>> _getIgnoreIds(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final matchesJson = prefs.getStringList('matches_$userId') ?? [];
      
      final ignoreIds = <String>[];
      for (String matchJson in matchesJson) {
        final match = jsonDecode(matchJson);
        final status = match['matchData']['status'];
        
        if (status == 'ignored' || status == 'pending') {
          final targetUserId = match['requesterUserId'] == userId 
              ? match['requestedUserId'] 
              : match['requesterUserId'];
          ignoreIds.add(targetUserId);
        }
      }
      
      return ignoreIds;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> _getUserInputs(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final inputsJson = prefs.getString('inputs_$userId');
      
      if (inputsJson != null) {
        return Map<String, dynamic>.from(jsonDecode(inputsJson));
      }
      
      return {};
    } catch (e) {
      return {};
    }
  }

  Map<String, dynamic> _buildSeekingFilters(Map<String, dynamic> userInputs) {
    final filters = <String, dynamic>{};
    
    if (userInputs['seeking'] != null) {
      filters['gender'] = userInputs['seeking'];
    }
    
    return filters;
  }

  Future<List<Map<String, dynamic>>> _queryFilteredUsers(
    Map<String, dynamic> filters, 
    List<String> ignoreIds
  ) async {
    try {
      Query query = FirebaseFirestore.instance.collection('users');
      
      if (filters['gender'] != null) {
        query = query.where('gender', whereIn: filters['gender']);
      }
      
      if (filters['minAge'] != null) {
        query = query.where('age', isGreaterThanOrEqualTo: filters['minAge']);
      }
      
      if (filters['maxAge'] != null) {
        query = query.where('age', isLessThanOrEqualTo: filters['maxAge']);
      }
      
      query = query.limit(20);
      
      final snapshot = await query.get();
      
      final users = snapshot.docs
          .where((doc) => !ignoreIds.contains(doc.id))
          .where((doc) => doc.id != _currentUserId)
          .take(9)
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return {
              'userId': doc.id,
              'nameFirst': data['nameFirst'],
              'birthDate': _convertDateToString(data['birthDate']),
              'photos': data['photos'],
              'location': _convertGeoPointToMap(data['location']),
              'gender': data['gender'],
              'age': data['age'],
            };
          })
          .toList();
      
      return users;
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveNewSession(
    List<Map<String, dynamic>> users, 
    List<String> userIds, 
    String currentUserId
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final usersJson = users.map((user) => jsonEncode(user)).toList();
      await prefs.setStringList('users_$currentUserId', usersJson);
    
      final currentUserInputs = await _getUserInputs(currentUserId);
      currentUserInputs['currentSeshList'] = userIds;
      await prefs.setString('inputs_$currentUserId', jsonEncode(currentUserInputs));
      
    } catch (e) {
      if (kDebugMode) {
        print('User Provider Error: Failed to save session - $e');
      }
    }
  }

  Future<void> _syncInputsToFirebase(Map<String, dynamic> inputs, String userId) async {
    try {
      if (inputs.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update(inputs);
      }
    } catch (e) {
      if (kDebugMode) {
        print('User Provider Error: Failed to sync inputs - $e');
      }
    }
  }

  /* = = = = = = = = = 
  Get User Doc by ID:
  Receive userID and query Firebase for it's Doc
  return user Doc
  = = = = = = = = = */



  /* = = = = = = = = = 
  Helper Methods
  = = = = = = = = = */

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

}