import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import 'userState.dart';
import '../functions/chatService.dart';

class MatchSyncProvider extends ChangeNotifier {
  // Private variables
  StreamSubscription<QuerySnapshot>? _outgoingMatchesListener;
  StreamSubscription<QuerySnapshot>? _incomingMatchesListener;
  String? _currentUserId;
  bool _isListening = false;
  bool _isBatchUpdating = false; // Add flag to batch updates
  
  // Public getters
  bool get isListening => _isListening;
  String? get currentUserId => _currentUserId;
  
  // Cached match data
  List<Map<String, dynamic>> _sentRequests = [];
  List<Map<String, dynamic>> _receivedRequests = [];
  List<Map<String, dynamic>> _allMatches = [];
  
  // Getters for cached data
  List<Map<String, dynamic>> get sentRequests => List.from(_sentRequests);
  List<Map<String, dynamic>> get receivedRequests => List.from(_receivedRequests);
  List<Map<String, dynamic>> get allMatches => List.from(_allMatches);

  // Batch notification helper
  void _notifyIfNotBatching() {
    if (!_isBatchUpdating) {
      notifyListeners();
    }
  }
  
  // Batch update wrapper
  Future<T> _batchUpdate<T>(Future<T> Function() operation) async {
    _isBatchUpdating = true;
    try {
      final result = await operation();
      return result;
    } finally {
      _isBatchUpdating = false;
      notifyListeners(); // Single notification after batch
    }
  }
  
  /* = = = = = = = = = 
  Lister for Sent Requests:
  Listen for acceptance of match requests
  Changes status to "active" for Match Doc
  Notifies Listeners
  = = = = = = = = = */

  Future<void> startListening(String currentSessionId) async {
    if (_isListening && _currentUserId == currentSessionId) {
      if (kDebugMode) {
        print('🎧 Already listening for user: $currentSessionId');
      }
      return;
    }
    
    // Batch all startup operations
    await _batchUpdate(() async {
      await stopListening();
      
      _currentUserId = currentSessionId;
      
      try {
        // Start real-time listeners
        _startSentRequestListener(currentSessionId);
        _startReceivedRequestListener(currentSessionId);
        
        _isListening = true;
        
        if (kDebugMode) {
          print('🎧 Started match listeners for user: $currentSessionId');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error starting listeners: $e');
        }
      }
    });
  }
  
  Future<void> stopListening() async {
    await _outgoingMatchesListener?.cancel();
    await _incomingMatchesListener?.cancel();
    
    _outgoingMatchesListener = null;
    _incomingMatchesListener = null;
    _currentUserId = null;
    _isListening = false;
    
    // Only notify if not part of a batch operation
    _notifyIfNotBatching();
    
    if (kDebugMode) {
      print('🔇 Stopped match listeners');
    }
  }
  
  void _startSentRequestListener(String userId) {
    _outgoingMatchesListener = FirebaseFirestore.instance
        .collection('matches')
        .where('requesterUserId', isEqualTo: userId)
        .snapshots()
        .listen(
          (snapshot) => _handleMatchChanges(snapshot, userId),
          onError: (error) {
            if (kDebugMode) {
              print('❌ Outgoing listener error: $error');
            }
          },
        );
  }
  
  void _startReceivedRequestListener(String userId) {
    _incomingMatchesListener = FirebaseFirestore.instance
        .collection('matches')
        .where('requestedUserId', isEqualTo: userId)
        .snapshots()
        .listen(
          (snapshot) => _handleMatchChanges(snapshot, userId),
          onError: (error) {
            if (kDebugMode) {
              print('❌ Incoming listener error: $error');
            }
          },
        );
  }
  
  /* = = = = = = = = =
  Handle Changes
  = = = = = = = = = */

  Future<void> _handleMatchChanges(QuerySnapshot snapshot, String currentSessionId) async {
    try {
      final List<Map<String, dynamic>> matches = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        final match = {
          'matchId': doc.id,
          'requestedUserId': data['requestedUserId'],
          'requesterUserId': data['requesterUserId'],
          'status': data['status'],
          'createdAt': data['createdAt']?.toDate()?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'updatedAt': data['updatedAt']?.toDate()?.toIso8601String() ?? DateTime.now().toIso8601String(),
        };
        
        matches.add(match);
      }
      
      await _mergeMatchesToSharedPrefs(matches, currentSessionId);
      
      // Only notify if not part of initial sync
      _notifyIfNotBatching();
      
      print('Match Provider: Updated ${matches.length} matches');
    } catch (e) {
      print('Match Provider Error: Failed to handle match changes - $e');
    }
  }

  // Merge match data, serves _handleMatchChanges
  Future<void> _mergeMatchesToSharedPrefs(List<Map<String, dynamic>> newMatches, String currentSessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing matches
      final existingJson = prefs.getStringList('matches_$currentSessionId') ?? [];
      List<Map<String, dynamic>> allMatches = existingJson
          .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
          .toList();
      
      // Update or add new matches
      for (var newMatch in newMatches) {
        final matchId = newMatch['matchId'];
        final existingIndex = allMatches.indexWhere((m) => m['matchId'] == matchId);
        
        if (existingIndex >= 0) {
          allMatches[existingIndex] = newMatch; // Update existing
        } else {
          allMatches.add(newMatch); // Add new
        }
      }
      
      // Save back to SharedPreferences
      await _saveToSharedPrefs('matches_$currentSessionId', allMatches);

      // Update local arrays by filtering
      _updateLocalArrays(allMatches, currentSessionId);
    } catch (e) {
      print('Error merging matches to cache: $e');
    }
  }
   
  // Fetching Data, serves _mergeMatchesToSharedPrefs
  void _updateLocalArrays(List<Map<String, dynamic>> allMatches, String currentSessionId) {
    _allMatches = List.from(allMatches);

    _sentRequests = allMatches.where((match) => 
      match['requesterUserId'] == currentSessionId &&
      match['status'] == 'pending' 
    ).toList();
    
    _receivedRequests = allMatches.where((match) => 
      match['requestedUserId'] == currentSessionId &&
      match['status'] == 'pending' 
    ).toList();
  }
  
  // Saving Data, serves _mergeMatchesToSharedPrefs 
  Future<void> _saveToSharedPrefs(String key, List<Map<String, dynamic>> matches) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Convert list of match objects to list of JSON strings
      final matchesJson = matches.map((match) => jsonEncode(match)).toList();
      
      // Save as StringList with session-based key
      // Note: key should already be 'matches_$currentSessionId' when passed in
      await prefs.setStringList(key, matchesJson);
      
      if (kDebugMode) {
        print('💾 Saved ${matchesJson.length} matches to $key');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving to SharedPreferences: $e');
      }
    }
  }
  
  /* = = = = = = = = = 
  Accept, Reject. UnMatch Match
  = = = = = = = = = */

  Future<Map<String, dynamic>> acceptMatch(String matchId, String currentUserId, String otherUserId) async {
    try {
      // Update match status to active
      await updateMatchStatus(matchId, 'active');
      
      // Create Stream Chat channel
      final chatService = StreamChatService();
      
      // Connect current user if not connected
      if (!chatService.isUserConnected()) {
        final prefs = await SharedPreferences.getInstance();
        final userJson = prefs.getString('inputs_$currentUserId');
        final userData = userJson != null ? jsonDecode(userJson) : {};
        
        await chatService.connectUser(
          userId: currentUserId,
          userName: userData['nameFirst'] ?? 'User',
          userImage: userData['photos']?[0],
        );
      }
      
      // Create the chat channel
      final channel = await chatService.createMatchChannel(
        matchId: matchId,
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );
      
      // Save channel ID to match document
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .update({
        'channelId': channel.cid,
        'chatCreatedAt': FieldValue.serverTimestamp(),
      });
      
      return {
        'success': true,
        'message': 'Match accepted successfully!',
        'channelId': channel.cid,
      };
    } catch (e) {
      print('Error accepting match: $e');
      return {
        'success': false,
        'message': 'Failed to accept match',
      };
    }
  }

  Future<Map<String, dynamic>> rejectMatch(String matchId, String otherUserId) async {
    try {
      // Update match status
      await updateMatchStatus(matchId, 'rejected');
      
      // Add to ignore list
      final prefs = await SharedPreferences.getInstance();
      final ignoreListJson = prefs.getStringList('ignoreList_$_currentUserId') ?? [];
      
      if (!ignoreListJson.contains(otherUserId)) {
        ignoreListJson.add(otherUserId);
        await prefs.setStringList('ignoreList_$_currentUserId', ignoreListJson);
      }

      return {
        'success': true,
        'message': 'Match rejected',
      };
    } catch (e) {
      print('Error rejecting match: $e');
      return {
        'success': false,
        'message': 'Failed to reject match',
      };
    }
  }

  Future<Map<String, dynamic>> unmatch(String matchId) async {
    try {
      await updateMatchStatus(matchId, 'unmatched');
      
      return {
        'success': true,
        'message': 'Unmatched successfully',
      };
    } catch (e) {
      print('Error unmatching: $e');
      return {
        'success': false,
        'message': 'Failed to unmatch',
      };
    }
  }

  Future<Map<String, dynamic>> ignore(String matchId) async {
    try {
      await updateMatchStatus(matchId, 'ignored');
      
      return {
        'success': true,
        'message': 'Ignore Status Set successfully',
      };
    } catch (e) {
      print('Error unmatching: $e');
      return {
        'success': false,
        'message': 'Failed to Ignore Status Set',
      };
    }
  }

  Future<Map<String, dynamic>> updateMatchStatus(String matchId, String newStatus) async {
    try {
      // Update Firebase
      await FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'message': 'Match status updated successfully!',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error updating match status: $e');
      }
      return {
        'success': false,
        'message': 'Failed to update match status',
      };
    }
  }
    
  /* = = = = = = = = = 
  Get Active User for Match Page
  = = = = = = = = = */

  Future<List<Map<String, dynamic>>> getActiveMatchUser() async {
    if (_currentUserId == null) {
      print('🔍 getActiveMatchUser: No current user ID');
      return [];
    }
    
    // Find the active match
    Map<String, dynamic>? activeMatch;
    for (var match in _allMatches) {
      if (match['status'] == 'active' && 
          (match['requesterUserId'] == _currentUserId || match['requestedUserId'] == _currentUserId)) {
        activeMatch = match;
        print('✅ Found active match: ${match['matchId']}');
        break;
      }
    }
    
    if (activeMatch == null) {
      print('⚠️ getActiveMatchUser: No active match found');
      return [];
    }
    
    // Get the other person's userId
    final matchedUserId = activeMatch['requesterUserId'] == _currentUserId 
        ? activeMatch['requestedUserId'] 
        : activeMatch['requesterUserId'];
        
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // FIX: Get the list properly as List<String>
      final usersJsonList = prefs.getStringList('users_$_currentUserId');
      
      if (usersJsonList != null) {
        // Check in the users list cache
        for (String userJson in usersJsonList) {
          final user = jsonDecode(userJson) as Map<String, dynamic>;
          if (user['userId'] == matchedUserId) {
            print('✅ Found matched user in cache');
            return [user];
          }
        }
      }
      
      print('📱 Matched user not in cache, fetching from Firebase...');
      
      // Fallback to Firebase if not in cache
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(matchedUserId)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final userData = {
          'userId': doc.id,
          ...data, // Include all user data
        };
        print('✅ Retrieved matched user from Firebase');
        return [userData];
      } else {
        print('❌ Matched user document not found in Firebase');
      }
      
    } catch (e) {
      print('❌ Error getting active match user: $e');
    }
    
    return [];
  }
  
  /* = = = = = = = = = 
  Helpers for External Functions
  = = = = = = = = = */

  // used in matchesService for Sending Match request, and in matchCTA for display UI
  bool hasExceededOutgoingLimit() {
    final pendingRequests = _sentRequests.where((request) => 
      request['status'] == 'pending' 
    ).toList();
    
    return pendingRequests.length >= 3;
  }
  
  // for the Requests Sent Page
  int get pendingRequestsCount {
    return _sentRequests.where((request) => 
      request['status'] == 'pending'
    ).length;
  }
  
  // triggered when data on error widget
  Future<void> forceRefresh(currentSessionId) async {
    if (_currentUserId == null) return;
    
    await _batchUpdate(() async {
      try {
        if (kDebugMode) {
          print('🔄 Force refreshing match data...');
        }
        
        // Clear all cached match data
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('matches_$_currentUserId');
        await prefs.remove('last_sync_$_currentUserId');
        
        // Clear local arrays
        _sentRequests = [];
        _receivedRequests = [];
        _allMatches = [];
        
        // Re-fetch everything from Firebase
        // Sync from Firebase - no notifications during sync
        final outgoingSnapshot = await FirebaseFirestore.instance
            .collection('matches')
            .where('requesterUserId', isEqualTo: currentSessionId)
            .get();
        
        final incomingSnapshot = await FirebaseFirestore.instance
            .collection('matches')
            .where('requestedUserId', isEqualTo: currentSessionId)
            .get();
        
        // Process both snapshots without notifications
        await _handleMatchChanges(outgoingSnapshot, currentSessionId);
        await _handleMatchChanges(incomingSnapshot, currentSessionId);
        
        if (kDebugMode) {
          print('✅ Force refresh completed');
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ Error during force refresh: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
  
}