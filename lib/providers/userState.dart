import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'inputState.dart';
import 'matchState.dart';
import '../functions/compatibilityConfigService.dart';

class UserSyncProvider extends ChangeNotifier {
  // Private variables
  String? _currentUserId;
  bool _isListening = false;
  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;
  
  // Public getters
  bool get isListening => _isListening;
  String? get currentUserId => _currentUserId;

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }

  /* = = = = = = = = =
  Load Current Users
  = = = = = = = = = */

  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersList = prefs.getStringList('users') ?? [];

      // 1. Check SharedPreferences
      for (String userJson in usersList) {
        final userData = jsonDecode(userJson);
        if (userData['userId'] == userId) {
          if (kDebugMode) print('👤 Loaded $userId from cache');
          return Map<String, dynamic>.from(userData);
        }
      }

      // 2. Not cached — fetch from Firebase
      if (kDebugMode) print('👤 Fetching $userId from Firebase...');
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists) return null;

      final userData = _convertTimestampsToStrings(doc.data() as Map<String, dynamic>);
      userData['userId'] = doc.id;

      // 3. Save to SharedPreferences
      bool found = false;
      for (int i = 0; i < usersList.length; i++) {
        final existing = jsonDecode(usersList[i]);
        if (existing['userId'] == userId) {
          usersList[i] = jsonEncode(userData);
          found = true;
          break;
        }
      }
      if (!found) {
        usersList.add(jsonEncode(userData));
      }
      await prefs.setStringList('users', usersList);

      if (kDebugMode) print('👤 Cached $userId (${usersList.length} users total)');

      // 4. Return
      return userData;

    } catch (e) {
      if (kDebugMode) print('❌ Error getting user $userId: $e');
      return null;
    }
  }

  /* = = = = = = = = = 
  Fetching New Users for Match
  = = = = = = = = = */ 

  Future<void> fetchUsersForMatch(BuildContext context, {String? eventId}) async {
    if (kDebugMode) {print("🔄 Refresh Triggered${eventId != null ? ' (Event: $eventId)' : ''}");}
    final inputState = Provider.of<InputState>(context, listen: false);
    final matchProvider = Provider.of<MatchSyncProvider>(context, listen: false);

    try {
      if (_currentUserId == null) return;

      // Navigate to loading page
      Navigator.pushNamed(context, '/loading');
      await Future.delayed(const Duration(milliseconds: 100));

      // === Setup ===
      final List<Map<String, dynamic>> collectedUsers = [];
      const int targetCount = 7;
      const int maxAttempts = 4;

      final seeking = await inputState.fetchInputFromLocal('Seeking');
      final myGender = await inputState.fetchInputFromLocal('Gender');
      final ageRange = await inputState.fetchInputFromLocal('ageRange');
      final myBasics = await inputState.fetchInputFromLocal('basics');
      final myRelationshipType = await inputState.fetchInputFromLocal('relationshipType');

      final now = DateTime.now();
      final maxBirthDate = DateTime(now.year - ageRange[0] as int, now.month, now.day).millisecondsSinceEpoch;
      final minBirthDate = DateTime(now.year - ageRange[1] as int, now.month, now.day).millisecondsSinceEpoch;

      final randomStart = Random().nextDouble();

      // === Query Loop ===
      for (int attempt = 0; attempt < maxAttempts; attempt++) {
        if (collectedUsers.length >= targetCount) break;

        try {
          List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];

          // Build base query with optional event filter
          Query<Map<String, dynamic>> baseQuery = FirebaseFirestore.instance
              .collection('users')
              .where('Gender', isEqualTo: seeking)
              .where('Seeking', isEqualTo: myGender)
              .where('birthDate', isGreaterThanOrEqualTo: minBirthDate)
              .where('birthDate', isLessThanOrEqualTo: maxBirthDate)
              .where('basics', isEqualTo: myBasics)
              .where('relationshipType', isEqualTo: myRelationshipType);

          if (eventId != null) {
            baseQuery = baseQuery.where('eventIds', arrayContains: eventId);
          }

          // QUERY 1: From randomStart to 1.0
          final snapshot1 = await baseQuery
              .orderBy('birthDate')
              .orderBy('randomSeed')
              .where('randomSeed', isGreaterThanOrEqualTo: randomStart)
              .limit(12)
              .get();
          docs.addAll(snapshot1.docs);

          // QUERY 2: Wrap around (0 to randomStart) if needed
          if (docs.length < 12) {
            final snapshot2 = await baseQuery
                .orderBy('birthDate')
                .orderBy('randomSeed')
                .where('randomSeed', isLessThan: randomStart)
                .limit(12 - docs.length)
                .get();
            docs.addAll(snapshot2.docs);
          }

          final queryResults = docs
              .where((doc) => doc.id != _currentUserId)
              .map((doc) {
                final data = doc.data();
                final cleanedData = _convertTimestampsToStrings(data);
                return {'userId': doc.id, ...cleanedData};
              })
              .toList();

          // STEP 0: Filter out already collected users
          final existingIds = collectedUsers.map((u) => u['userId'] as String).toSet();
          var newUniqueUsers = queryResults.where((user) => !existingIds.contains(user['userId'])).toList();

          // STEP 1: Filter out users below compatibility threshold
          if (newUniqueUsers.isNotEmpty) {
            final usersWithCompatibility = <Map<String, dynamic>>[];
            for (var user in newUniqueUsers) {
              final result = await inputState.generateCompatibility(user);
              if (result != null &&
                  result['compatibility']?['percentage'] != null &&
                  result['compatibility']['percentage'] >=
                      MatchingConfig.scoringThresholds['minimum_match_percentage']!) {
                usersWithCompatibility.add(result);
                if (kDebugMode) {
                  print('${user['userId']} passed compatibility: ${result['compatibility']['percentage']}%');
                }
              } else {
                if (kDebugMode) {
                  print('Filtered out ${user['userId']} — below threshold');
                }
              }
            }
            newUniqueUsers = usersWithCompatibility;
          }

          // STEP 2: Filter out users already in match instances with status "matched" or "reported"
          if (newUniqueUsers.isNotEmpty) {
            final userIds = newUniqueUsers.map((u) => u['userId'] as String).toList();
            final disqualifiedIds = <String>{};
            final matchCollection = eventId != null ? 'match_event_instances' : 'match_instances';

            for (var i = 0; i < userIds.length; i += 10) {
              final batch = userIds.skip(i).take(10).toList();

              var query = FirebaseFirestore.instance
                  .collection(matchCollection)
                  .where('userIds', arrayContainsAny: batch)
                  .where('status', whereIn: ['matched', 'reported']);

              if (eventId != null) {
                query = query.where('eventId', isEqualTo: eventId);
              }

              final snapshot = await query.get();
              for (var doc in snapshot.docs) {
                final docUserIds = List<String>.from(doc.data()['userIds'] ?? []);
                if (docUserIds.contains(_currentUserId)) {
                  final otherUserId = docUserIds.firstWhere((id) => id != _currentUserId);
                  disqualifiedIds.add(otherUserId);
                }
              }
            }

            newUniqueUsers = newUniqueUsers
                .where((user) => !disqualifiedIds.contains(user['userId']))
                .toList();

            if (kDebugMode && disqualifiedIds.isNotEmpty) {
              print('Filtered out ${disqualifiedIds.length} users from $matchCollection (matched/reported)');
            }
          }

          collectedUsers.addAll(newUniqueUsers);

          if (kDebugMode) {
            print('🔍 Attempt ${attempt + 1}: Found ${newUniqueUsers.length} new users after all filters');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Query error in attempt ${attempt + 1}: $e');
          }
        }

        if (collectedUsers.length >= targetCount) break;
      }

      // === Create match instances ===
      final newUsers = collectedUsers.take(targetCount).toList();
      if (newUsers.isNotEmpty) {
        for (var user in newUsers) {
          if (eventId != null) {
            await matchProvider.createMatchEventInstance(_currentUserId!, user, eventId);
          } else {
            await matchProvider.createMatchInstance(_currentUserId!, user);
          }
        }
      }

      // Navigate to matches page
      Navigator.pushNamed(context, '/guideAvailableMatches');

      if (kDebugMode) {print('✅ Refresh complete: Created ${newUsers.length} match instances');}
    } catch (e) {
      if (kDebugMode) {print('User Provider Error: Refresh failed - $e');}
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