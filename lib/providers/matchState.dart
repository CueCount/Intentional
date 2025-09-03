import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';

class MatchSyncProvider extends ChangeNotifier {
  // Private variables
  StreamSubscription<QuerySnapshot>? _outgoingMatchesListener;
  StreamSubscription<QuerySnapshot>? _incomingMatchesListener;
  String? _currentUserId;
  bool _isListening = false;
  
  // Public getters
  bool get isListening => _isListening;
  String? get currentUserId => _currentUserId;
  
  // Cached match data
  List<Map<String, dynamic>> _sentRequests = [];
  List<Map<String, dynamic>> _receivedRequests = [];
  List<Map<String, dynamic>> _activeMatch = [];
  
  // Getters for cached data
  List<Map<String, dynamic>> get sentRequests => List.from(_sentRequests);
  List<Map<String, dynamic>> get receivedRequests => List.from(_receivedRequests);
  List<Map<String, dynamic>> get activeMatch => List.from(_activeMatch);
  
  /* = = = = = = = = = 
  Start / Stop Listening
  = = = = = = = = = */

  Future<void> startListening(String userId) async {
    if (_isListening && _currentUserId == userId) {
      if (kDebugMode) {
        print('🎧 Already listening for user: $userId');
      }
      return;
    }
    
    await stopListening(); // Stop any existing listeners
    
    _currentUserId = userId;
    
    try {
      // Initial sync from Firebase to populate cache
      await _initialSync(userId);
      
      // Start real-time listeners
      _startSentRequestListener(userId);
      _startReceivedRequestListener(userId);
      
      _isListening = true;
      notifyListeners();
      
      if (kDebugMode) {
        print('🎧 Started match listeners for user: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting listeners: $e');
      }
    }
  }
  
  Future<void> stopListening() async {
    await _outgoingMatchesListener?.cancel();
    await _incomingMatchesListener?.cancel();
    
    _outgoingMatchesListener = null;
    _incomingMatchesListener = null;
    _currentUserId = null;
    _isListening = false;
    
    notifyListeners();
    
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

  Future<void> _handleMatchChanges(QuerySnapshot snapshot, String userId) async {
    try {
      // Process each document one by one to handle async properly
      final List<Map<String, dynamic>> matches = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Determine which user's profile data we need
        final targetUserId = data['requesterUserId'] == userId 
            ? data['requestedUserId']
            : data['requesterUserId'];
        
        // Await the user data lookup
        final userData = await _getUserDataForMatch(targetUserId);
        
        final match = {
          'requestedUserId': data['requestedUserId'],
          'requesterUserId': data['requesterUserId'],
          'matchData': {
            'matchId': doc.id,
            'status': data['status'],
            'createdAt': data['createdAt']?.toDate()?.toIso8601String() ?? DateTime.now().toIso8601String(),
            'updatedAt': data['updatedAt']?.toDate()?.toIso8601String() ?? DateTime.now().toIso8601String(),
          },
          'userData': userData, // Now this is resolved data, not a Future
        };
        
        matches.add(match);
      }
      
      await _mergeMatchesToSharedPrefs(matches, userId);
      notifyListeners();
      
      print('Match Provider: Updated ${matches.length} matches');
    } catch (e) {
      print('Match Provider Error: Failed to handle match changes - $e');
    }
  }
  
  /* = = = = = = = = = 
  Fetching and Saving Data 
  = = = = = = = = = */

  Future<void> _initialSync(String userId) async {
    try {
      // Always load cached data first (instant)
      await _loadFromSharedPrefs(userId);
      
      // Check if we need to sync from Firebase
      final shouldSync = await _shouldSyncFromFirebase(userId);
      
      if (shouldSync) {
        if (kDebugMode) {
          print('🔄 Syncing from Firebase (cache is stale or missing)');
        }
        
        // Sync from Firebase
        final outgoingSnapshot = await FirebaseFirestore.instance
            .collection('matches')
            .where('requesterUserId', isEqualTo: userId)
            .get();
        
        final incomingSnapshot = await FirebaseFirestore.instance
            .collection('matches')
            .where('requestedUserId', isEqualTo: userId)
            .get();
        
        await _handleMatchChanges(outgoingSnapshot, userId);
        await _handleMatchChanges(incomingSnapshot, userId);
        
        // Update last sync timestamp
        await _updateLastSyncTimestamp(userId);
        
        if (kDebugMode) {
          print('✅ Firebase sync completed');
        }
      } else {
        if (kDebugMode) {
          print('💾 Using cached data (still fresh)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error during initial sync: $e');
      }
    }
  }
  
  Future<void> _loadFromSharedPrefs(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load all matches from single key
      final allMatchesJson = prefs.getStringList('matches_$userId') ?? [];
      final allMatches = allMatchesJson.map((jsonString) => 
        Map<String, dynamic>.from(jsonDecode(jsonString))
      ).toList();
      
      // Filter into sent/received arrays
      _updateLocalArrays(allMatches, userId);
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading from SharedPreferences: $e');
      }
    }
  }
  
  Future<void> _saveToSharedPrefs(String key, List<Map<String, dynamic>> matches) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final matchesJson = matches.map((match) => jsonEncode(match)).toList();
      await prefs.setStringList(key, matchesJson);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving to SharedPreferences: $e');
      }
    }
  }

  Future<void> _mergeMatchesToSharedPrefs(List<Map<String, dynamic>> newMatches, String userId) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Get existing matches
    final existingJson = prefs.getStringList('matches_$userId') ?? [];
    List<Map<String, dynamic>> allMatches = existingJson
        .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
        .toList();
    
    // Update or add new matches
    for (var newMatch in newMatches) {
      final matchId = newMatch['matchData']['matchId'];
      final existingIndex = allMatches.indexWhere((m) => m['matchData']['matchId'] == matchId);
      
      if (existingIndex >= 0) {
        allMatches[existingIndex] = newMatch; // Update existing
      } else {
        allMatches.add(newMatch); // Add new
      }
    }
    
    // Save back to SharedPreferences
    await _saveToSharedPrefs('matches_$userId', allMatches);
    
    // Update local arrays by filtering
    _updateLocalArrays(allMatches, userId);
  } catch (e) {
    print('Error merging matches to cache: $e');
  }
}

  void _updateLocalArrays(List<Map<String, dynamic>> allMatches, String userId) {
    _sentRequests = allMatches.where((match) => 
      match['requesterUserId'] == userId
    ).toList();
    
    _receivedRequests = allMatches.where((match) => 
      match['requestedUserId'] == userId
    ).toList();
  }
  
  /* = = = = = = = = = 
  Helpers
  = = = = = = = = = */

  bool hasExceededOutgoingLimit() {
    final pendingRequests = _sentRequests.where((request) => 
      request['matchData']['status'] == 'pending'
    ).toList();
    
    return pendingRequests.length >= 3;
  }

  int get pendingRequestsCount {
    return _sentRequests.where((request) => 
      request['matchData']['status'] == 'pending'
    ).length;
  }
  
  Future<bool> _shouldSyncFromFirebase(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we have any cached data
      final sentCached = prefs.getStringList('matches_$userId');
      final receivedCached = prefs.getStringList('matches_$userId');
      
      // If no cached data exists, definitely sync
      if ((sentCached?.isEmpty ?? true) && (receivedCached?.isEmpty ?? true)) {
        return true;
      }
      
      // Check last sync timestamp
      final lastSyncString = prefs.getString('last_sync_$userId');
      if (lastSyncString == null) {
        return true; // No sync timestamp, sync needed
      }
      
      final lastSync = DateTime.parse(lastSyncString);
      final now = DateTime.now();
      final timeDifference = now.difference(lastSync);
      
      // Sync if last sync was more than 5 minutes ago
      const syncThreshold = Duration(minutes: 5);
      return timeDifference > syncThreshold;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error checking sync status: $e');
      }
      return true; // On error, sync to be safe
    }
  }
  
  Future<void> _updateLastSyncTimestamp(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_$userId', DateTime.now().toIso8601String());
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating sync timestamp: $e');
      }
    }
  }

  Future<Map<String, dynamic>> _getUserDataForMatch(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList('users_${_currentUserId}') ?? [];
      
      for (String userJson in usersJson) {
        final user = jsonDecode(userJson);
        if (user['userId'] == userId) {
          return {
            'userId': userId,
            'nameFirst': user['nameFirst'],
            'birthDate': user['birthDate'],
            'photos': user['photos'],
          };
        }
      }
      
      // Fallback if user not found
      return {
        'userId': userId,
        'nameFirst': 'Not Found',
        'photos': null,
      };
    } catch (e) {
      return {
        'userId': userId,
        'nameFirst': 'Unknown',
        'photos': null,
      };
    }
  }

  /* = = = = = = = = = 
  Override
  = = = = = = = = = */

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

}