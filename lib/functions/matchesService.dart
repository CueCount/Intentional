import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../router/router.dart';
import 'dart:async';
import 'helpers/fetchData_service.dart';
import 'helpers/saveData_service.dart';
import 'userActionsService.dart';
import 'package:flutter/foundation.dart';
import 'helpers/matchesHelper.dart';

enum DataSource { cache, firebase }

class MatchesService {

  /* = = = = = = = = =
  Send Request, Create Match Document
  = = = = = = = = = */

  static Future<Map<String, dynamic>> sendMatchRequest(String requestedUserId) async {
    try {
      // Get Session ID
      String? sessionUserId = await UserActions.getCurrentUserId();
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

      bool matchDocumentCreated = await MatchesHelper.createMatchDocument(matchId, sessionUserId, requestedUserId);
      if (!matchDocumentCreated) {
        return {
          'success': false,
          'message': 'Failed to create match document'
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

  /* = = = = = = = = =
  Deny Request
  = = = = = = = = = */
  

  /* = = = = = = = = =
  Ignore Request
  = = = = = = = = = */

  // Timer function for ignoring 

  /* = = = = = = = = =
  Accept Request
  = = = = = = = = = */

  // Send Acceptance Here

  // Listener for New Match Here

  /* = = = = = = = = =
  UnMatch
  = = = = = = = = = */

  // Send UnMatch Here

  // Listener for New UnMatch Here

  /* = = = = = = = = =
  Fetch Sent Requests
  = = = = = = = = = */

  Future<List<Map<String, dynamic>>> fetchSentRequests({
    required bool fromFirebase,
    bool forceFresh = false,
  }) async {
    try {
      List<Map<String, dynamic>> requests = [];
      
      // Get current user ID
      String? currentUserId = await UserActions.getCurrentUserId();
      if (currentUserId == null) {
        if (kDebugMode) {
          print('Error: Unable to get current user ID');
        }
        return [];
      }

      if (fromFirebase) {
        // Fetch from Firebase
        if (forceFresh) {
          await _clearRequestsCache();
        }
        requests = await FetchDataService.fetchSentRequestsFromFirebase(currentUserId);
        await SaveDataService().cacheSentRequestsToSharedPrefs(requests, currentUserId);
      } else {
        // Fetch from SharedPreferences (cache)
        requests = await FetchDataService().fetchSentRequestsFromSharedPreferences(currentUserId);
      }

      if (kDebugMode) {
        print('📤 Fetched ${requests.length} sent requests from ${fromFirebase ? 'Firebase' : 'cache'}');
      }
      
      return requests;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching sent requests: $e');
      }
      return [];
    }
  }

  Future<void> _clearRequestsCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get current user ID
      final currentUserId = await UserActions.getCurrentUserId();
      
      if (currentUserId != null) {
        await prefs.remove('sent_requests_$currentUserId');
        print('🧹 Cleared cached sent requests');
      }
    } catch (e) {
      print('❌ Error clearing requests cache: $e');
    }
  }

  /* = = = = = = = = =
  Fetch Received Requests
  = = = = = = = = = */

  Future<List<Map<String, dynamic>>> fetchReceivedRequests({
    required bool fromFirebase,
    bool forceFresh = false,
  }) async {
    try {
      List<Map<String, dynamic>> requests = [];
      
      // Get current user ID
      String? currentUserId = await UserActions.getCurrentUserId();
      if (currentUserId == null) {
        if (kDebugMode) {
          print('Error: Unable to get current user ID');
        }
        return [];
      }

      if (fromFirebase) {
        // Fetch from Firebase
        if (forceFresh) {
          await _clearRequestsCache();
        }
        requests = await FetchDataService.fetchReceivedRequestsFromFirebase(currentUserId);
        await SaveDataService().cacheReceivedRequestsToSharedPrefs(requests, currentUserId);
      } else {
        // Fetch from SharedPreferences (cache)
        requests = await FetchDataService().fetchReceivedRequestsFromSharedPreferences(currentUserId);
      }

      if (kDebugMode) {
        print('📤 Fetched ${requests.length} sent requests from ${fromFirebase ? 'Firebase' : 'cache'}');
      }
      
      return requests;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching sent requests: $e');
      }
      return [];
    }
  }

  // Listener for new Incoming Here

  /* = = = = = = = = =
  Refresh Matches
  = = = = = = = = = */

  Future<void> refreshMatches(BuildContext context) async {
    try {
      final id = await UserActions.getCurrentUserId(context: context);
      if (id != null && id.isNotEmpty) {
        await UserActions.setStatus(id, {
          'needsUpdated': false,
        });
        print('✅ Set needsUpdated flag for refresh');
      }
      
      Navigator.pushNamed(
        context, 
        AppRoutes.matches,
        arguments: {'shouldUpdate': true}
      );
    } catch (e) {
      print('❌ Error in refreshMatches: $e');
    }
  }

  /* = = = = = = = = =
  Fetch Matches
  = = = = = = = = = */

  Future<List<Map<String, dynamic>>> fetchMatches({
    required bool fromFirebase,
    bool onlyWithPhotos = false,
    bool forceFresh = false,
    Map<String, dynamic>? additionalFilters,
  }) async {
    try {
      List<Map<String, dynamic>> profiles = [];
      
      if (fromFirebase) {
        // Fetch from Firebase
        if (forceFresh) {
          await _clearUserCache();
        }
        profiles = await FetchDataService().fetchMatchesFromFirebase(
          onlyWithPhotos: onlyWithPhotos,
          additionalFilters: additionalFilters,
        );
        final cleanedUsers = profiles.map((user) => FetchDataService().cleanUserData(user)).toList();
        await SaveDataService().cacheFetchedProfilesToSharedPrefs(cleanedUsers);
        profiles = cleanedUsers;
      } else {
        // Fetch from SharedPreferences (cache)
        profiles = await FetchDataService().fetchMatchesFromSharedPreferences();
      }
      
      print('📱 Discovered ${profiles.length} profiles from ${fromFirebase ? 'Firebase' : 'cache'}');
      return profiles;
    } catch (e) {
      print('❌ Error discovering profiles: $e');
      return [];
    }
  }

  Future<void> _clearUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get current user ID to preserve their data
      final currentUserId = await UserActions.getCurrentUserId();
      
      final keys = prefs.getKeys().where((key) => 
        key.startsWith('user_data_') && 
        (currentUserId == null || key != 'user_data_$currentUserId') // Don't clear current user's data
      ).toList();
      
      for (var key in keys) {
        await prefs.remove(key);
      }
      print('🧹 Cleared ${keys.length} cached user profiles (preserved current user)');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }

}