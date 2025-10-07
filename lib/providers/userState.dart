import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';
import 'inputState.dart';
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
            if (kDebugMode) {
              print('User Provider: User $userId missing, fetching from Firebase');
            }
            
            userData = await getUserByID(userId);
            
            if (userData != null) {
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
    if (kDebugMode) {print("🔄 Refresh Triggered");}
    final inputState = Provider.of<InputState>(context, listen: false);
    final matchProvider = Provider.of<MatchSyncProvider>(context, listen: false);

    try {
      if (_currentUserId == null) return;
      
      // Step 1: Clean up currentSessionList
      final usersToRemove = await _filterAndMoveNonPendingUsers(inputState, matchProvider);
      
      // Step 2: Get user inputs and build filters
      final userInputs = await inputState.getAllInputs();
      final filterInputs = _buildFilterInputs(userInputs);
      
      // Step 3: Get ignore list
      final ignoreIds = await inputState.getInput('ignoreList') ?? [];
      final ignoreIdsList = List<String>.from(ignoreIds);
      
      // Step 4: Query for new users with retry logic
      final newUsers = await _queryWithRetryLogic(filterInputs, ignoreIdsList.toSet());
      
      // Step 5: Update local storage
      await _updateLocalUserStorage(newUsers, usersToRemove, context);
      
      // Step 6: Update currentSessionList
      await _updateCurrentSessionList(inputState, newUsers);
      
      // Navigate to matches page
      Navigator.pushNamed(context, '/matches');
      
      if (kDebugMode) {print('✅ Refresh complete: Found ${newUsers.length} new users');}
    } catch (e) {
      if (kDebugMode) {print('User Provider Error: Refresh failed - $e');}
    }
  }

  // Step 1: Filter and Move Non-Pending Users
  Future<List<String>> _filterAndMoveNonPendingUsers(
    InputState inputState,
    MatchSyncProvider matchProvider
  ) async {
    // Get currentSessionList
    final currentSessionIds = await inputState.getInput('currentSessionList');
    if (currentSessionIds == null || currentSessionIds.isEmpty) {
      return [];
    }
    final currentSessionList = List<String>.from(currentSessionIds);
    
    if (currentSessionList.isNotEmpty) {
      // Get existing ignore list
      final existingIgnoreIds = await inputState.getInput('ignoreList') ?? [];
      final ignoreList = List<String>.from(existingIgnoreIds);
      
      // Add non-pending to ignore list
      ignoreList.addAll(currentSessionList);
      
      // Save updated ignore list
      await inputState.saveNeedLocally({
        'ignoreList': ignoreList,
      });

      // Instead of saving anything, just clear the currentSessionList 
      await inputState.saveNeedLocally({
        'currentSessionList': [],  // Empty list
      });
      
      if (kDebugMode) {
        print('📋 Moved ${currentSessionList.length} users to ignore list');
      }
    }
    
    return currentSessionList;
  }

  // Step 2: Build Filter Inputs - Placeholder
  Map<String, dynamic> _buildFilterInputs(Map<String, dynamic> userInputs) {
    // Placeholder function - returns empty map for now
    // TODO: Implement filter building logic
    return {};
  }

  // Step 3: Query With Retry Logic
  Future<List<Map<String, dynamic>>> _queryWithRetryLogic(
    Map<String, dynamic> filterInputs,
    Set<String> excludedIds,
  ) async {
    final List<Map<String, dynamic>> collectedUsers = [];
    const int targetCount = 7;
    const int maxAttempts = 4;
    
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      if (collectedUsers.length >= targetCount) break;
      
      try {
        final randomOffset = attempt * 10;
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .limit(7 + randomOffset)
            .get();
        
        final queryResults = snapshot.docs
            .where((doc) => !excludedIds.contains(doc.id))
            .where((doc) => doc.id != _currentUserId)
            .map((doc) {
              final data = doc.data();
              final cleanedData = _convertTimestampsToStrings(data);
              return {
                'userId': doc.id,
                ...cleanedData,
              };
            })
            .toList();
        
        // Filter out already collected users
        final existingIds = collectedUsers.map((u) => u['userId'] as String).toSet();
        var newUniqueUsers = queryResults
            .where((user) => !existingIds.contains(user['userId']))
            .toList();
        
        // STEP 1: Filter out users with pending cases
        if (newUniqueUsers.isNotEmpty) {
          final userIds = newUniqueUsers.map((u) => u['userId'] as String).toList();
          
          // Query cases where status = pending AND userId is in our list
          final casesSnapshot = await FirebaseFirestore.instance
              .collection('cases')
              .where('status', isEqualTo: 'pending')
              .where('userId', whereIn: userIds)  // whereIn has limit of 10 items
              .get();
          
          final usersWithPendingCases = casesSnapshot.docs
              .map((doc) => doc.data()['userId'] as String)
              .toSet();
          
          // Filter them out
          newUniqueUsers = newUniqueUsers
              .where((user) => !usersWithPendingCases.contains(user['userId']))
              .toList();
          
          if (kDebugMode && usersWithPendingCases.isNotEmpty) {
            print('Filtered out ${usersWithPendingCases.length} users with pending cases');
          }
        }
        
        // STEP 2: Filter out users in active matches
        if (newUniqueUsers.isNotEmpty) {
          final userIds = newUniqueUsers.map((u) => u['userId'] as String).toList();
          final usersInActiveMatches = <String>{};
          
          // Query for active matches where either user is in our list
          final matchesAsRequester = await FirebaseFirestore.instance
              .collection('matches')
              .where('status', isEqualTo: 'active')
              .where('requesterUserId', whereIn: userIds)
              .get();
          
          final matchesAsRequested = await FirebaseFirestore.instance
              .collection('matches')
              .where('status', isEqualTo: 'active')
              .where('requestedUserId', whereIn: userIds)
              .get();
          
          // Add users found in active matches
          for (var doc in matchesAsRequester.docs) {
            final data = doc.data();
            usersInActiveMatches.add(data['requesterUserId'] as String);
          }
          
          for (var doc in matchesAsRequested.docs) {
            final data = doc.data();
            usersInActiveMatches.add(data['requestedUserId'] as String);
          }
          
          // Filter them out
          newUniqueUsers = newUniqueUsers
              .where((user) => !usersInActiveMatches.contains(user['userId']))
              .toList();
          
          if (kDebugMode && usersInActiveMatches.isNotEmpty) {
            print('Filtered out ${usersInActiveMatches.length} users in active matches');
          }
        }
        
        // Add the fully filtered users to collected
        collectedUsers.addAll(newUniqueUsers);
        
        if (kDebugMode) {
          print('🔍 Attempt ${attempt + 1}: Found ${newUniqueUsers.length} new users after all filters');
        }
        
      } catch (e) {
        if (kDebugMode) {
          print('Query error in attempt ${attempt + 1}: $e');
        }
      }
      
      if (collectedUsers.length >= targetCount) {
        break;
      }
    }
    
    return collectedUsers.take(targetCount).toList();
  }

  // Step 4: Update Local User Storage
  Future<void> _updateLocalUserStorage(
    List<Map<String, dynamic>> newUsers,
    List<String> removedUserIds,
    BuildContext context,
  ) async {
    if (_currentUserId == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing users
    final existingUsersList = prefs.getStringList('users_$_currentUserId') ?? [];
    final existingUsers = existingUsersList
        .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
        .toList();

    // Get pending match user IDs (both sent and received)
    final matchProvider = Provider.of<MatchSyncProvider>(context, listen: false);
    final pendingUserIds = <String>{};
    
    // Add users from sent requests (where current user is requester)
    for (var match in matchProvider.sentRequests) {
      if (match['status'] == 'pending') {
        pendingUserIds.add(match['requestedUserId'] as String);
      }
    }
    
    // Add users from received requests (where current user is requested)
    for (var match in matchProvider.receivedRequests) {
      if (match['status'] == 'pending') {
        pendingUserIds.add(match['requesterUserId'] as String);
      }
    }
    
    // Keep only pending match users from existing users
    final pendingUsers = existingUsers
        .where((user) => pendingUserIds.contains(user['userId']))
        .toList();
    
    // Start with pending users and add new users
    final updatedUsers = [...pendingUsers, ...newUsers];
    
    // Save back
    final usersJson = updatedUsers.map((user) => jsonEncode(user)).toList();
    await prefs.setStringList('users_$_currentUserId', usersJson);
    
    if (kDebugMode) {
      print('💾 Updated user storage: ${pendingUsers.length} pending + ${newUsers.length} new = ${updatedUsers.length} total');
    }
  }

  // Step 5: Update Current Session List
  Future<void> _updateCurrentSessionList(
    InputState inputState,
    List<Map<String, dynamic>> newUsers,
  ) async {
    final newUserIds = newUsers.map((user) => user['userId'] as String).toList();
  
    // Save ONLY the new user IDs
    await inputState.saveNeedLocally({
      'currentSessionList': newUserIds,
    });
    
    // Sync everything to Firebase
    await inputState.syncInputs(fromId: _currentUserId, toId: _currentUserId);
    
    if (kDebugMode) {
      print('📝 Updated session list: ${newUserIds.length} users');
    }
  }

  /* = = = = = = = = = 
  Fetch First Batch of Users During Registration
  = = = = = = = = = */
  
  Future<void> fetchInitialUsers(InputState inputState) async {
    try {
      final currentSessionId = inputState.userId;
      
      if (currentSessionId.isEmpty) {
        print('User Provider: No session ID for fetching initial users');
        return;
      }
      
      // Step 2: Get user inputs and build filters
      final userInputs = await inputState.getAllInputs();
      final filterInputs = _buildFilterInputs(userInputs);
      
      // Step 4: Query for users with retry logic (no ignoreList for initial fetch)
      final collectedUsers = await _fetchInitialUsersWithFilters(filterInputs);
      
      if (collectedUsers.isEmpty) {
        print('User Provider: No users found during initial fetch');
        return;
      }
      
      // Step 5: Store users in local storage
      final prefs = await SharedPreferences.getInstance();
      final usersJson = collectedUsers.map((user) => jsonEncode(user)).toList();
      await prefs.setStringList('users_$currentSessionId', usersJson);
      
      // Step 6: Update currentSessionList with user IDs
      final userIds = collectedUsers.map((user) => user['userId'] as String).toList();
      await inputState.saveNeedLocally({
        'currentSessionList': userIds,
      });
      
      // Sync to Firebase
      await inputState.syncInputs(fromId: currentSessionId, toId: currentSessionId);
      
      print('User Provider: Fetched ${collectedUsers.length} initial users');
      print('User Provider: Saved to users_$currentSessionId');
      
    } catch (e) {
      print('User Provider Error: Failed to fetch initial users - $e');
    }
  }

  // Helper function specifically for initial fetch
  Future<List<Map<String, dynamic>>> _fetchInitialUsersWithFilters(
    Map<String, dynamic> filterInputs,
  ) async {
    final List<Map<String, dynamic>> collectedUsers = [];
    const int targetCount = 7;
    const int maxAttempts = 4;
    
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      if (collectedUsers.length >= targetCount) break;
      
      try {
        final randomOffset = attempt * 10;
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .limit(7 + randomOffset)
            .get();
        
        var potentialUsers = snapshot.docs
            .skip(randomOffset) // Skip already seen users
            .take(10)
            .map((doc) {
              final data = doc.data();
              final cleanedData = _convertTimestampsToStrings(data);
              return {
                'userId': doc.id,
                ...cleanedData,
              };
            })
            .toList();
        
        // Filter out already collected users
        final existingIds = collectedUsers.map((u) => u['userId'] as String).toSet();
        potentialUsers = potentialUsers
            .where((user) => !existingIds.contains(user['userId']))
            .toList();
        
        // STEP 1: Filter out users with pending cases
        if (potentialUsers.isNotEmpty) {
          final userIds = potentialUsers.map((u) => u['userId'] as String).toList();
          
          // Handle whereIn limit of 10 items
          final userIdsToCheck = userIds.take(10).toList();
          
          final casesSnapshot = await FirebaseFirestore.instance
              .collection('cases')
              .where('status', isEqualTo: 'pending')
              .where('userId', whereIn: userIdsToCheck)
              .get();
          
          final usersWithPendingCases = casesSnapshot.docs
              .map((doc) => doc.data()['userId'] as String)
              .toSet();
          
          potentialUsers = potentialUsers
              .where((user) => !usersWithPendingCases.contains(user['userId']))
              .toList();
          
          if (kDebugMode && usersWithPendingCases.isNotEmpty) {
            print('Initial fetch: Filtered out ${usersWithPendingCases.length} users with pending cases');
          }
        }
        
        // STEP 2: Filter out users in active matches
        if (potentialUsers.isNotEmpty) {
          final userIds = potentialUsers.map((u) => u['userId'] as String).toList();
          final usersInActiveMatches = <String>{};
          
          // Query for active matches where either user is in our list
          final matchesAsRequester = await FirebaseFirestore.instance
              .collection('matches')
              .where('status', isEqualTo: 'active')
              .where('requesterUserId', whereIn: userIds)
              .get();
          
          final matchesAsRequested = await FirebaseFirestore.instance
              .collection('matches')
              .where('status', isEqualTo: 'active')
              .where('requestedUserId', whereIn: userIds)
              .get();
          
          // Add users found in active matches
          for (var doc in matchesAsRequester.docs) {
            final data = doc.data();
            usersInActiveMatches.add(data['requesterUserId'] as String);
          }
          
          for (var doc in matchesAsRequested.docs) {
            final data = doc.data();
            usersInActiveMatches.add(data['requestedUserId'] as String);
          }
          
          // Filter them out
          potentialUsers = potentialUsers
              .where((user) => !usersInActiveMatches.contains(user['userId']))
              .toList();
          
          if (kDebugMode && usersInActiveMatches.isNotEmpty) {
            print('Initial fetch: Filtered out ${usersInActiveMatches.length} users in active matches');
          }
        }
        
        collectedUsers.addAll(potentialUsers);
        
        if (kDebugMode) {
          print('🔍 Initial fetch attempt ${attempt + 1}: Found ${potentialUsers.length} valid users');
        }
        
      } catch (e) {
        if (kDebugMode) {
          print('Initial fetch error in attempt ${attempt + 1}: $e');
        }
      }
      
      if (collectedUsers.length >= targetCount) {
        break;
      }
    }
    
    return collectedUsers.take(targetCount).toList();
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

  Map<String, dynamic> _convertTimestampsToStrings(Map<String, dynamic> data) {
    final Map<String, dynamic> result = {};
    
    data.forEach((key, value) {
      if (value is Timestamp) {
        result[key] = value.toDate().toIso8601String();
      } else if (value is GeoPoint) {
        result[key] = {
          'latitude': value.latitude,
          'longitude': value.longitude,
        };
      } else if (value is Map) {
        result[key] = _convertTimestampsToStrings(value as Map<String, dynamic>);
      } else if (value is List) {
        result[key] = value.map((item) {
          if (item is Map) {
            return _convertTimestampsToStrings(item as Map<String, dynamic>);
          }
          return item;
        }).toList();
      } else {
        result[key] = value;
      }
    });
    
    return result;
  }

}