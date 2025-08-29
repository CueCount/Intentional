import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MatchesHelper {
  
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

  static String createMatchId(String sessionUserId, String requestedUserId) {
    return '$sessionUserId-$requestedUserId';
  }

  static Future<bool> createMatchDocument(String matchId, String sessionUserId, String requestedUserId) async {
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

}