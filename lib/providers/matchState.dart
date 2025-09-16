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
        // Initial sync from Firebase to populate cache
        await _loadFromSharedPrefs(currentSessionId);

        // IF IT'S BEEN MORE THAN 10 DAYS THEN FORCEREFRESH()
        try {
          final prefs = await SharedPreferences.getInstance();
          final lastSyncStr = prefs.getString('last_sync_$currentSessionId');

          // If we've never synced (null) or can't parse the timestamp, force a refresh.
          DateTime? lastSync = lastSyncStr != null ? DateTime.tryParse(lastSyncStr) : null;
          final isStale = lastSync == null
              || DateTime.now().difference(lastSync) > const Duration(days: 10);

          if (isStale) {
            await forceRefresh(currentSessionId);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ Error checking last_sync_$currentSessionId: $e');
          }
          // On error, be safe and refresh.
          await forceRefresh(currentSessionId);
        }
        
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
      // Process each document one by one to handle async properly
      final List<Map<String, dynamic>> matches = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Determine which user's profile data we need
        final targetUserId = data['requesterUserId'] == currentSessionId 
            ? data['requestedUserId']
            : data['requesterUserId'];
        
        // Await the user data lookup
        final userData = await _getUserDataForMatch(currentSessionId, targetUserId);
        
        final match = {
          'matchId': doc.id,
          'requestedUserId': data['requestedUserId'],
          'requesterUserId': data['requesterUserId'],
          'status': data['status'],
          'createdAt': data['createdAt']?.toDate()?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'updatedAt': data['updatedAt']?.toDate()?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'userData': userData,
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
  
  /* = = = = = = = = = 
  Fetching and Saving Data 
  = = = = = = = = = */
  
  Future<void> _loadFromSharedPrefs(String currentSessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load all matches from session-based key (using currentSessionId as sessionId)
      final allMatchesJson = prefs.getStringList('matches_$currentSessionId') ?? [];
      
      // Convert from StringList of JSON strings to List of Maps
      final allMatches = allMatchesJson.map((jsonString) => 
        Map<String, dynamic>.from(jsonDecode(jsonString))
      ).toList();
      
      // Update local arrays by filtering
      _updateLocalArrays(allMatches, currentSessionId);
      
      if (kDebugMode) {
        print('📦 Loaded ${allMatches.length} matches from matches_$currentSessionId');
      }
      
      // Don't notify here - let the batch operation handle it
    } catch (e) {
      if (kDebugMode) {
        print('Error loading from SharedPreferences: $e');
      }
      // Initialize empty arrays on error
      _sentRequests = [];
      _receivedRequests = [];
      _allMatches = [];
    }
  }
  
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
  
  /* = = = = = = = = = 
  Helpers
  = = = = = = = = = */

  Future<void> _updateLocalMatchStatus(String matchId, String newStatus) async {
    if (_currentUserId == null) return;

    await _batchUpdate(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final allMatchesJson = prefs.getStringList('matches_$_currentUserId') ?? [];
        List<Map<String, dynamic>> allMatches = allMatchesJson
            .map((json) => Map<String, dynamic>.from(jsonDecode(json)))
            .toList();

        // Find and update the specific match
        for (var match in allMatches) {
          if (match['matchId'] == matchId) { // FLAT ACCESS
            match['status'] = newStatus; // FLAT ACCESS
            match['updatedAt'] = DateTime.now().toIso8601String(); // FLAT ACCESS
            break;
          }
        }

        // Save and update local arrays
        await _saveToSharedPrefs('matches_$_currentUserId', allMatches);
        _updateLocalArrays(allMatches, _currentUserId!);
      } catch (e) {
        if (kDebugMode) {
          print('Error updating local match status: $e');
        }
      }
    });
  }
  
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

      // Update local data with batching
      await _updateLocalMatchStatus(matchId, newStatus);

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
  
  Future<Map<String, dynamic>> _getUserDataForMatch(String currentSessionId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getStringList('users_$_currentUserId') ?? [];
      
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
  
  Future<List<Map<String, dynamic>>> getActiveMatchUser() async {
    if (_currentUserId == null) return [];
    
    // Find the active match
    Map<String, dynamic>? activeMatch;
    for (var match in _allMatches) {
      if (match['status'] == 'active' && // FLAT ACCESS
          (match['requesterUserId'] == _currentUserId || match['requestedUserId'] == _currentUserId)) {
        activeMatch = match;
        break;
      }
    }
    
    if (activeMatch == null) return [];
    
    // Get the other person's userId
    final matchedUserId = activeMatch['requesterUserId'] == _currentUserId 
        ? activeMatch['requestedUserId'] 
        : activeMatch['requesterUserId'];
    
    // Get the user document from cache first, then Firebase if needed
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('users_$matchedUserId');
      
      if (userJson != null) {
        final userData = Map<String, dynamic>.from(jsonDecode(userJson));
        return [userData];
      }
      
      // Fallback to Firebase if not in cache
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(matchedUserId)
          .get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final userData = {
          'userId': doc.id,
          'nameFirst': data['nameFirst'],
          'birthDate': data['birthDate'],
          'photos': data['photos'],
          'location': data['location'],
        };
        return [userData];
      }
      
    } catch (e) {
      print('Error getting active match user: $e');
    }
    
    return [];
  }
  
  bool hasExceededOutgoingLimit() {
    final pendingRequests = _sentRequests.where((request) => 
      request['status'] == 'pending' 
    ).toList();
    
    return pendingRequests.length >= 3;
  }
  
  int get pendingRequestsCount {
    return _sentRequests.where((request) => 
      request['status'] == 'pending'
    ).length;
  }
  
  Map<String, dynamic>? getActiveMatchUserFromUserProvider(List<Map<String, dynamic>> allUsers) {
    if (_currentUserId == null) return null;

    // Find the active match first
    String? matchedUserId;
    for (var match in _allMatches) {
      if (match['status'] == 'active' && // FLAT ACCESS
          (match['requesterUserId'] == _currentUserId || match['requestedUserId'] == _currentUserId)) {
        
        // Get the other person's userId
        matchedUserId = match['requesterUserId'] == _currentUserId 
            ? match['requestedUserId'] 
            : match['requesterUserId'];
        break;
      }
    }
    
    if (matchedUserId == null) return null;
    
    // Find the full user data from UserProvider
    for (var user in allUsers) {
      if (user['userId'] == matchedUserId) {
        return user;
      }
    }
    
    return null;
  }
  
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
        
        // Update last sync timestamp
        await _updateLastSyncTimestamp(currentSessionId);
        
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

  static Future<void> debugPrintAllStorage() async {
    final prefs = await SharedPreferences.getInstance();
    
    print('\n========== FULL SHARED PREFERENCES DUMP ==========');
    
    final allKeys = prefs.getKeys().toList()..sort();
    
    for (String key in allKeys) {
      print('\n📦 KEY: $key');
      
      try {
        // Try to get as StringList FIRST (since that's what we're using for matches_ and users_)
        final listValue = prefs.getStringList(key);
        if (listValue != null) {
          print('  Type: StringList with ${listValue.length} items');
          for (int i = 0; i < listValue.length && i < 3; i++) {
            try {
              final decoded = jsonDecode(listValue[i]);
              print('  [$i]: ${const JsonEncoder.withIndent('    ').convert(decoded).substring(0, 300)}...');
            } catch (_) {
              print('  [$i]: ${listValue[i].substring(0, 100.clamp(0, listValue[i].length))}...');
            }
          }
          if (listValue.length > 3) {
            print('  ... and ${listValue.length - 3} more items');
          }
          continue;
        }
        
        // Try to get as String if not a StringList
        final stringValue = prefs.getString(key);
        if (stringValue != null) {
          print('  Type: String');
          // Try to decode as JSON to pretty print
          try {
            final decoded = jsonDecode(stringValue);
            print('  Value (decoded): ${const JsonEncoder.withIndent('  ').convert(decoded).substring(0, 500)}...');
          } catch (_) {
            print('  Value (raw): ${stringValue.substring(0, 200.clamp(0, stringValue.length))}...');
          }
          continue;
        }
        
        // Try other types
        final boolValue = prefs.getBool(key);
        if (boolValue != null) {
          print('  Type: bool = $boolValue');
          continue;
        }
        
        final intValue = prefs.getInt(key);
        if (intValue != null) {
          print('  Type: int = $intValue');
          continue;
        }
        
        final doubleValue = prefs.getDouble(key);
        if (doubleValue != null) {
          print('  Type: double = $doubleValue');
          continue;
        }
        
        print('  Type: Unknown or null');
        
      } catch (e) {
        print('  ERROR reading key: $e');
      }
    }
    
    print('\n========== END DUMP ==========\n');
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}