import 'package:flutter/material.dart';
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
  
  // Getters for cached data
  List<Map<String, dynamic>> get sentRequests => List.from(_sentRequests);
  List<Map<String, dynamic>> get receivedRequests => List.from(_receivedRequests);
  
  // Initialize listeners for a user
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
      _startOutgoingListener(userId);
      _startIncomingListener(userId);
      
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
  
  // Stop all listeners
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
  
  // Start outgoing matches listener
  void _startOutgoingListener(String userId) {
    _outgoingMatchesListener = FirebaseFirestore.instance
        .collection('matches')
        .where('requesterUserId', isEqualTo: userId)
        .snapshots()
        .listen(
          (snapshot) => _handleOutgoingChanges(snapshot, userId),
          onError: (error) {
            if (kDebugMode) {
              print('❌ Outgoing listener error: $error');
            }
          },
        );
  }
  
  // Start incoming matches listener
  void _startIncomingListener(String userId) {
    _incomingMatchesListener = FirebaseFirestore.instance
        .collection('matches')
        .where('requestedUserId', isEqualTo: userId)
        .snapshots()
        .listen(
          (snapshot) => _handleIncomingChanges(snapshot, userId),
          onError: (error) {
            if (kDebugMode) {
              print('❌ Incoming listener error: $error');
            }
          },
        );
  }
  
  // Handle outgoing match changes
  Future<void> _handleOutgoingChanges(QuerySnapshot snapshot, String userId) async {
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
      
      // Update local cache
      _sentRequests = matches;
      
      // Update SharedPreferences
      await _saveToSharedPrefs('sent_requests_$userId', matches);
      
      // Notify listeners (UI will update)
      notifyListeners();
      
      if (kDebugMode) {
        print('🔄 Updated ${matches.length} sent requests');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling outgoing changes: $e');
      }
    }
  }
  
  // Handle incoming match changes
  Future<void> _handleIncomingChanges(QuerySnapshot snapshot, String userId) async {
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
      
      // Update local cache
      _receivedRequests = matches;
      
      // Update SharedPreferences
      await _saveToSharedPrefs('received_requests_$userId', matches);
      
      // Notify listeners (UI will update)
      notifyListeners();
      
      if (kDebugMode) {
        print('🔄 Updated ${matches.length} received requests');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling incoming changes: $e');
      }
    }
  }
  
  // Initial sync from Firebase
  Future<void> _initialSync(String userId) async {
    try {
      // Load cached data first (fast)
      await _loadFromSharedPrefs(userId);
      
      // Then sync from Firebase (accurate)
      final outgoingSnapshot = await FirebaseFirestore.instance
          .collection('matches')
          .where('requesterUserId', isEqualTo: userId)
          .get();
      
      final incomingSnapshot = await FirebaseFirestore.instance
          .collection('matches')
          .where('requestedUserId', isEqualTo: userId)
          .get();
      
      await _handleOutgoingChanges(outgoingSnapshot, userId);
      await _handleIncomingChanges(incomingSnapshot, userId);
      
      if (kDebugMode) {
        print('✅ Initial sync completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error during initial sync: $e');
      }
    }
  }
  
  // Load from SharedPreferences
  Future<void> _loadFromSharedPrefs(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load sent requests
      final sentJson = prefs.getStringList('sent_requests_$userId') ?? [];
      _sentRequests = sentJson.map((jsonString) => 
        Map<String, dynamic>.from(jsonDecode(jsonString))
      ).toList();
      
      // Load received requests
      final receivedJson = prefs.getStringList('received_requests_$userId') ?? [];
      _receivedRequests = receivedJson.map((jsonString) => 
        Map<String, dynamic>.from(jsonDecode(jsonString))
      ).toList();
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading from SharedPreferences: $e');
      }
    }
  }
  
  // Save to SharedPreferences
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
  
  // Check if user has exceeded outgoing limit
  bool hasExceededOutgoingLimit() {
    final pendingRequests = _sentRequests.where((request) => 
      request['status'] == 'pending'
    ).toList();
    
    return pendingRequests.length >= 3;
  }
  
  // Get pending requests count
  int get pendingRequestsCount {
    return _sentRequests.where((request) => request['status'] == 'pending').length;
  }
  
  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}