import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';
import 'inputState.dart';

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
  Load Users:
  Look at currentSessionIds
  Grab Docs from Shared Pref
  Query Firebase for Docs not in Shared Pref
  Return Docs
  = = = = = = = = = */ 

  Future<List<Map<String, dynamic>>> loadUsers(InputState inputState) async {
    if (kDebugMode) {
      print('loadUsers called, currentUserId: $_currentUserId');
    }
    try {
      // Get session IDs using InputState
      final sessionUserIds = await inputState.getInput('currentSessionList');
      
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
    if (kDebugMode) {print("Refresh Triggered:");}

    final inputState = Provider.of<InputState>(context, listen: false);

    try {
      if (_currentUserId == null) return;
      final prefs = await SharedPreferences.getInstance();

      /* = = = = = = = = = 
      Move currentSessionList Ids to ignoreList
      = = = = = = = = = = */

      final currentSessionIds = await inputState.getInput('currentSessionList');
      // currentSessionIdsNonPending = currentSessionIds minus Ids that are in pending match docs with currentSessionId
      // Move all currentSessionIdsNonPending to ignoreList
      final ignoreIds = await inputState.getInput('ignoreList');

      /* = = = = = = = = = 
      Fetch all inputs and build filters
      = = = = = = = = = = */

      final userInputs = await await inputState.syncInputs();
      // final seekingInputs = _buildSeekingFilters(userInputs);

      /* = = = = = = = = = 
      Query Firebase with filters
      = = = = = = = = = = */
      
      // final newUsers = await _queryFilteredUsers(seekingInputs, ignoreIds, /* ids from current match docs pending */);

      /* = = = = = = = = = 
      Save New Users to Local, Remove Old Users
      = = = = = = = = = = */

      // final usersJson = newUsers.map((user) => jsonEncode(user)).toList();
      // delete user docs in users_[currentSessionId] that match currentSessionIdsNonPending
      // await prefs.setStringList('users_$currentUserId', usersJson);

      /* = = = = = = = = = 
      Save New User Ids to currentSessionList, Merge all Local Inputs with Firebase
      = = = = = = = = = = */

      // final newUserIds = newUsers.map((user) => user['userId'] as String).toList();
      // call function to accept fetched userIds and add them to the currentSessionList
      // await inputState.syncInputsToFirebase(userInputs, _currentUserId!);
      
      /* = = = = = = = = = 
      Navigate back to matches page - triggering loadUsers to load New Users
      = = = = = = = = = = */
      
      Navigator.pushNamed(context, '/matches');

      print("test of Refresh with only InputSync is complete");

      // if (kDebugMode) {print('User Provider: Refreshed ${newUsers.length} discoverable users');}
      
    } catch (e) {
      if (kDebugMode) {
        print('User Provider Error: Refresh failed - $e');
      }
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

  /* = = = = = = = = = 
  MISC Helper Methods
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