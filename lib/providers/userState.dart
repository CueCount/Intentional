import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';
import 'inputState.dart';
import 'matchState.dart';
import '../functions/compatibilityCalcService.dart';
import '../functions/compatibilityConfigService.dart';

class UserSyncProvider extends ChangeNotifier {
  // Private variables
  String? _currentUserId;
  bool _isListening = false;
  final isLoggedIn = FirebaseAuth.instance.currentUser != null;
  
  // Public getters
  bool get isListening => _isListening;
  String? get currentUserId => _currentUserId;

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  /* = = = = = = = = =
  Load Current Users
  = = = = = = = = = */

  Future<List<Map<String, dynamic>>> loadUsers(InputState inputState) async {
    if (kDebugMode) {print('loadUsers called, currentUserId: $_currentUserId');}

    try {
      final prefs = await SharedPreferences.getInstance();
      final inputsJson = prefs.getString('inputs_$_currentUserId');
      
      List<String>? sessionUserIds;
      if (inputsJson != null) {
        final inputs = Map<String, dynamic>.from(jsonDecode(inputsJson));
        final sessionList = inputs['currentSessionList'];
        if (sessionList != null && sessionList is List) {
          sessionUserIds = List<String>.from(sessionList);
        }
      }

      if (sessionUserIds == null || sessionUserIds.isEmpty) {
        if (kDebugMode) {print('User Provider: No users in currentSessionList');}
        return [];
      }

      final List<Map<String, dynamic>> loadedUsers = [];

      // Process each user ID in the session
      for (String userId in sessionUserIds) {
        try {
          // Try to get user data from SharedPreferences cache
          Map<String, dynamic>? userData = await getUserFromCache(userId, _currentUserId!);
          
          if (userData != null) {
            loadedUsers.add(userData);
            if (kDebugMode) {print('User Provider: Loaded $userId from cache');}
          } else {
            if (kDebugMode) {
              print('User Provider: User $userId missing, fetching from Firebase');
            }
            
            userData = await getUserByID(userId, _currentUserId, inputState);
            
            loadedUsers.add(userData!);
            
            if (kDebugMode) {
              print('User Provider: Fetched and cached $userId from Firebase');
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

      if (loadedUsers.isNotEmpty) {
        final updatedUsers = await inputState.generateCompatibility(loadedUsers);
        
        for (var user in updatedUsers) {
          await storeUserInCache(user, _currentUserId!);
        }
        
        if (kDebugMode) {
          print('User Provider: Returning ${updatedUsers.length} users with compatibility');
        }
        
        return updatedUsers;
      }

      return loadedUsers;

    } catch (e) {
      if (kDebugMode) {
        print('User Provider Error: Failed to load users - $e');
      }
      return [];
    }
  }

  Future<Map<String, dynamic>?> getUserFromCache(String userId, String currentSessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get the StringList of all users for this session
      final usersList = prefs.getStringList('users') ?? [];
      
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

  Future<void> storeUserInCache(Map<String, dynamic> userData, String currentSessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = userData['userId'];
      
      if (userId != null) {
        // Get existing list or create empty
        List<String> usersList = prefs.getStringList('users') ?? [];
        
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
        await prefs.setStringList('users', usersList);
        
        if (kDebugMode) {
          print('User Provider: Stored $userId -> users (${usersList.length} users total)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('User Provider Error: Failed to store user in cache - $e');
      }
    }
  }

  Future<Map<String, dynamic>?> getUserByID(String userId, String? currentSessionId, InputState inputState) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Convert timestamps and build user data
        final userData = _convertTimestampsToStrings(data);
        userData['userId'] = doc.id;
        
        // Store user in cache first
        await storeUserInCache(userData, currentSessionId!);
        
        return userData;
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
  Fetching New Users for Match
  = = = = = = = = = */

  Future<void> fetchUsersForMatch(BuildContext context) async {
    if (kDebugMode) {print("🔄 Refresh Triggered");}
    final inputState = Provider.of<InputState>(context, listen: false);
    final matchProvider = Provider.of<MatchSyncProvider>(context, listen: false);

    try {
      if (_currentUserId == null) return;

      // Navigate to loading page
      Navigator.pushNamed(context, '/loading');
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Get ignore list
      final ignoreIds = await inputState.fetchInputFromLocal('ignoreList') ?? [];
      final ignoreIdsList = List<String>.from(ignoreIds);
      
      // Query for new users with retry logic
      final newUsers = await _queryWithRetryLogic(inputState, ignoreIdsList.toSet());
      
      // Update currentSessionList [I should just combine this with the above function]
      await _updateCurrentSessionList(inputState, newUsers);

      // Save the timestamp at the beginning of refresh
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_refresh', DateTime.now().toIso8601String());
      
      // Navigate to matches page
      Navigator.pushNamed(context, '/guideAvailableMatches');
      
      if (kDebugMode) {print('✅ Refresh complete: Found ${newUsers.length} new users');}
    } catch (e) {
      if (kDebugMode) {print('User Provider Error: Refresh failed - $e');}
    }
  }

  // Query With Retry Logic [combining wiht functon above]
  Future<List<Map<String, dynamic>>> _queryWithRetryLogic(
    InputState inputState,
    Set<String> excludedIds,
  ) async {
    final List<Map<String, dynamic>> collectedUsers = [];
    const int targetCount = 7;
    const int maxAttempts = 4;
    final seeking = await inputState.fetchInputFromLocal('Seeking');
    
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      if (collectedUsers.length >= targetCount) break;
      
      try {
        final randomOffset = 10;
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('Gender', isEqualTo: seeking)
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
        
        // STEP 0: Filter out already collected users
        final existingIds = collectedUsers.map((u) => u['userId'] as String).toSet();
        var newUniqueUsers = queryResults.where((user) => !existingIds.contains(user['userId'])).toList();
        
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

        // STEP 3: Filter out users below compatibility threshold
        if (newUniqueUsers.isNotEmpty) {
          // Get current user's actual data for matching
          final currentUserData = await inputState.fetchInputsFromLocal();

          // Add debug logging here
          if (kDebugMode) {
            print('\n=== MATCH CALCULATION DEBUG ===');
            print('Current user data keys: ${currentUserData.keys.toList()}');
            // Sample first potential match structure
            if (newUniqueUsers.isNotEmpty) {
              print('Potential match keys: ${newUniqueUsers[0].keys.toList()}');
            }
          }
          
          // Filter users based on compatibility
          final usersWithCompatibility = <Map<String, dynamic>>[];
          
          for (var user in newUniqueUsers) {
            final result = MatchCalculationService().calculateMatch(
              currentUser: currentUserData,
              potentialMatch: user,
            );

            // Check against minimum threshold
            if (result.percentage >= MatchingConfig.scoringThresholds['minimum_match_percentage']!) {
              // Add compatibility data to the user object
              user['compatibility'] = {
                'percentage': result.percentage,
                'matchQuality': result.matchQuality,
                'topReasons': result.topReasons,
                'personality': {
                  'score': result.breakdown['personality']?.score ?? 0,
                  'percentage': result.breakdown['personality']?.percentage ?? 0,
                  'matches': result.breakdown['personality']?.matches ?? [],
                  'reason': result.breakdown['personality']?.reason ?? '',
                },
                'relationship': {
                  'score': result.breakdown['relationship']?.score ?? 0,
                  'percentage': result.breakdown['relationship']?.percentage ?? 0,
                  'matches': result.breakdown['relationship']?.matches ?? [],
                  'reason': result.breakdown['relationship']?.reason ?? '',
                },
                'interests': {
                  'score': result.breakdown['interests']?.score ?? 0,
                  'percentage': result.breakdown['interests']?.percentage ?? 0,
                  'matches': result.breakdown['interests']?.matches ?? [],
                  'reason': result.breakdown['interests']?.reason ?? '',
                },
                'goals': {
                  'score': result.breakdown['goals']?.score ?? 0,
                  'percentage': result.breakdown['goals']?.percentage ?? 0,
                  'matches': result.breakdown['goals']?.matches ?? [],
                  'reason': result.breakdown['goals']?.reason ?? '',
                },
                'archetypes': result.archetypeAnalysis != null ? {
                  'personalityType': result.personalityArchetype ?? 'Unique',
                  'relationshipStyle': result.relationshipStyle ?? 'Custom',
                  'title': result.archetypeTitle ?? 'Your Match',
                  'narrative': result.archetypeNarrative ?? '',
                  'idealDate': result.idealDate ?? '',
                  'longTermOutlook': result.longTermOutlook ?? '',
                } : null,
                'calculatedAt': DateTime.now().toIso8601String(),
              };
              usersWithCompatibility.add(user);
              print('${user['userId']} passed the compatibility filter with ${result.percentage}% compatibility');
            } else {
              if (kDebugMode) {
                print('Filtered out ${user['userId']} - compatibility ${result.percentage}% below threshold');
              }
            }
          }
          
          // Replace newUniqueUsers with only those above threshold
          newUniqueUsers = usersWithCompatibility;
          
          if (kDebugMode) {
            print('Compatibility filter: ${usersWithCompatibility.length} of ${newUniqueUsers.length} users passed');
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

  // Update Current Session List [combinging this with function above]
  Future<void> _updateCurrentSessionList(
    InputState inputState,
    List<Map<String, dynamic>> newUsers,
  ) async {
    final newUserIds = newUsers.map((user) => user['userId'] as String).toList();

    // Save user IDs and last_refresh timestamp together
    final dataToSave = {
      'currentSessionList': newUserIds,
      'last_refresh': DateTime.now().toIso8601String(),
    };

    if (isLoggedIn) {
      await inputState.saveInputToRemoteThenLocal(dataToSave);
    } else {
      await inputState.saveInputToRemoteThenLocalInOnboarding(dataToSave);
    }
    
    if (kDebugMode) {
      print('📝 Updated session list: ${newUserIds.length} users');
    }
  }

  /* = = = = = = = = = 
  Helpers
  = = = = = = = = = */

  // probably deleting and using function from inputState
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