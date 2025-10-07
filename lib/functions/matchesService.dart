import 'dart:async';
import 'package:flutter/foundation.dart';
import 'helpers/matchesHelper.dart';

enum DataSource { cache, firebase }

class MatchesService {

  /* = = = = = = = = =
  Send Match Request
  = = = = = = = = = */

  static Future<Map<String, dynamic>> sendMatchRequest(String currentSessionId, String requestedUserId) async {
    try {
      // Get Session ID
      final sessionUserId = currentSessionId;
      if (sessionUserId == null) {
        return {
          'success': false,
          'message': 'Unable to fetch user session ID'
        };
      }

      // Check if requested ID is valid
      if (requestedUserId.isEmpty) {
        return {
          'success': false,
          'message': 'Invalid user ID provided'
        };
      }

      // Check if requested ID is available
      bool requestedUserHasActiveMatch = await MatchesHelper.findOutIfRequestedIsMatched(requestedUserId);
      if (requestedUserHasActiveMatch) {
        return {
          'success': false,
          'message': 'Requested User is already matched'
        };
      }

      // Check if requester ID has 2 or less requested matches
      bool hasExceededLimit = await MatchesHelper.hasExceededOutgoingLimit(sessionUserId);
      if (hasExceededLimit) {
        return {
          'success': false, 
          'message': 'You have reached the maximum limit of 3 outgoing match requests'
        };
      }

      String matchId = MatchesHelper.createMatchId(sessionUserId, requestedUserId);

      bool matchDocumentCreated = await MatchesHelper.saveMatchDocumentToFirebase(matchId, sessionUserId, requestedUserId);
      if (!matchDocumentCreated) {
        return {
          'success': false,
          'message': 'Failed to create match document'
        };
      }

      bool matchDocumentSavedLocal = await MatchesHelper.saveMatchDocumentToSharedPrefs(matchId, sessionUserId, requestedUserId);
      if (!matchDocumentSavedLocal) {
        return {
          'success': false,
          'message': 'Failed to save match document to local'
        };
      }

      return {
        'success': true,
        'message': 'Match request sent successfully!',
        'matchId': matchId
      };

    } catch (e) {
      if (kDebugMode) {
        print('Error in sendMatchRequest: $e');
      }

      return {
        'success': false,
        'message': 'An unexpected error occurred while sending match request'
      };
    }
  }

}