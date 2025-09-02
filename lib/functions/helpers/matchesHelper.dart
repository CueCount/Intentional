import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class MatchesHelper {

  /* = = = = = = = = =
  Creating New Match Document
  = = = = = = = = = */

  static String createMatchId(String sessionUserId, String requestedUserId) {
    return '$sessionUserId-$requestedUserId';
  }
  
  static Future<bool> hasExceededOutgoingLimit(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('matches')
          .where('requesterUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      return querySnapshot.docs.length >= 3;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking outgoing request limit: $e');
      }
      return true; 
    }
  }

  static Future<bool> findOutIfRequestedIsMatched(String userId) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('matches')
          .where('requestedUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking for active matches: $e');
      }
      return false;
    }
  }

  /* = = = = = = = = =
  SAVE Match Document 
  to Shared Preferences / Firebase
  = = = = = = = = = */

  static Future<bool> saveMatchDocumentToFirebase(String matchId, String sessionUserId, String requestedUserId) async {
    try {
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .set({
        'matchId': matchId,
        'requesterUserId': sessionUserId,
        'requestedUserId': requestedUserId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating match document: $e');
      }
      return false;
    }
  }

  static Future<bool> saveMatchDocumentToSharedPrefs(String matchId, String sessionUserId, String requestedUserId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Create the match document
      final matchDocument = {
        'matchId': matchId,
        'requesterUserId': sessionUserId,
        'requestedUserId': requestedUserId,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      };
      
      // Get existing matches for this user
      final existingMatchesJson = prefs.getStringList('matches_$sessionUserId') ?? [];
      
      // Convert existing JSON strings back to Maps
      List<Map<String, dynamic>> existingMatches = existingMatchesJson
          .map((jsonString) => Map<String, dynamic>.from(jsonDecode(jsonString)))
          .toList();
      
      // Add the new match document
      existingMatches.add(matchDocument);
      
      // Convert back to JSON strings and save
      final updatedMatchesJson = existingMatches
          .map((match) => jsonEncode(match))
          .toList();
      
      await prefs.setStringList('matches_$sessionUserId', updatedMatchesJson);
      
      if (kDebugMode) {
        print('💾 Successfully saved match document to SharedPreferences: $matchId');
      }
      
      return true;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving match document to SharedPreferences: $e');
      }
      return false;
    }
  }

  /* = = = = = = = = =
  FETCH Match Document 
  from Shared Preferences / Firebase
  = = = = = = = = = */

  

  /* = = = = = = = = =
  LISTEN for Match Document Changes
  = = = = = = = = = */

  static StreamSubscription<QuerySnapshot>? _outgoingMatchesListener;
  static StreamSubscription<QuerySnapshot>? _incomingMatchesListener;

  static Future<void> startMatchListeners(String userId) async {
    await stopMatchListeners(); // Stop any existing listeners
    
    // Listen to outgoing requests (where user is the requester)
    _outgoingMatchesListener = FirebaseFirestore.instance
        .collection('matches')
        .where('requesterUserId', isEqualTo: userId)
        .snapshots()
        .listen(
          (snapshot) => _handleOutgoingMatchChanges(snapshot, userId),
          onError: (error) {
            if (kDebugMode) {
              print('❌ Error in outgoing matches listener: $error');
            }
          },
        );
    
    // Listen to incoming requests (where user is the requested)
    _incomingMatchesListener = FirebaseFirestore.instance
        .collection('matches')
        .where('requestedUserId', isEqualTo: userId)
        .snapshots()
        .listen(
          (snapshot) => _handleIncomingMatchChanges(snapshot, userId),
          onError: (error) {
            if (kDebugMode) {
              print('❌ Error in incoming matches listener: $error');
            }
          },
        );
    
    if (kDebugMode) {
      print('🎧 Started match listeners for user: $userId');
    }
  }

  static Future<void> stopMatchListeners() async {
    await _outgoingMatchesListener?.cancel();
    await _incomingMatchesListener?.cancel();
    _outgoingMatchesListener = null;
    _incomingMatchesListener = null;
    
    if (kDebugMode) {
      print('🔇 Stopped match listeners');
    }
  }

  static Future<void> _handleOutgoingMatchChanges(QuerySnapshot snapshot, String userId) async {
    try {
      final matches = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'matchId': doc.id,
          'requesterUserId': data['requesterUserId'],
          'requestedUserId': data['requestedUserId'],
          'status': data['status'],
          'createdAt': data['createdAt']?.toDate()?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'updatedAt': data['updatedAt']?.toDate()?.toIso8601String() ?? DateTime.now().toIso8601String(),
        };
      }).toList();
      
      await _updateSharedPrefsMatches('matches_$userId', matches);
      
      if (kDebugMode) {
        print('🔄 Updated ${matches.length} outgoing matches in SharedPreferences');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling outgoing match changes: $e');
      }
    }
  }

  static Future<void> _handleIncomingMatchChanges(QuerySnapshot snapshot, String userId) async {
    try {
      final matches = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'matchId': doc.id,
          'requesterUserId': data['requesterUserId'],
          'requestedUserId': data['requestedUserId'],
          'status': data['status'],
          'createdAt': data['createdAt']?.toDate()?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'updatedAt': data['updatedAt']?.toDate()?.toIso8601String() ?? DateTime.now().toIso8601String(),
        };
      }).toList();
      
      await _updateSharedPrefsMatches('matches_$userId', matches);
      
      if (kDebugMode) {
        print('🔄 Updated ${matches.length} incoming matches in SharedPreferences');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling incoming match changes: $e');
      }
    }
  }

  static Future<void> _updateSharedPrefsMatches(String key, List<Map<String, dynamic>> matches) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final matchesJson = matches.map((match) => jsonEncode(match)).toList();
      await prefs.setStringList(key, matchesJson);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating SharedPreferences: $e');
      }
    }
  }

}