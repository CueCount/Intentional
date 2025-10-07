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


}