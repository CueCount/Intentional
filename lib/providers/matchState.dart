import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import '../functions/chatService.dart';

class MatchSyncProvider extends ChangeNotifier {
  // Private variables
  StreamSubscription<QuerySnapshot>? _matchInstancesListener;
  String? _currentUserId;
  bool _isListening = false;
  // Public getters
  bool get isListening => _isListening;
  String? get currentUserId => _currentUserId;
  // Cached match instance data — fed by the single listener
  List<Map<String, dynamic>> _allMatchInstances = [];
  List<Map<String, dynamic>> get allMatchInstances => List.from(_allMatchInstances);
  Completer<void>? _firstSnapshotCompleter;
  Future<void> get firstSnapshotReady => _firstSnapshotCompleter?.future ?? Future.value();
  
  /* = = = = = = = = = 
  Listener for Sent Requests:
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

    await stopListening();
    _currentUserId = currentSessionId;
    _firstSnapshotCompleter = Completer<void>();

    try {
      _matchInstancesListener = FirebaseFirestore.instance
          .collection('match_instances')
          .where('userIds', arrayContains: currentSessionId)
          .where('status', whereIn: ['active', 'chat_requested', 'matched'])
          .snapshots()
          .listen(
            (snapshot) => _handleMatchInstanceChanges(snapshot),
            onError: (error) {
              if (kDebugMode) {
                print('❌ Match instances listener error: $error');
              }
            },
          );

      _isListening = true;

      if (kDebugMode) {
        print('🎧 Started match_instances listener for: $currentSessionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting listener: $e');
      }
    }
  }

  Future<void> stopListening() async {
    await _matchInstancesListener?.cancel();
    _matchInstancesListener = null;
    _currentUserId = null;
    _isListening = false;
    _allMatchInstances = [];

    if (kDebugMode) {
      print('🔇 Stopped match_instances listener');
    }
  }

  /* = = = = = = = = =
  Handle Incoming Changes from Firebase
  = = = = = = = = = */

  Future<void> _handleMatchInstanceChanges(QuerySnapshot snapshot) async {
    try {
      final List<Map<String, dynamic>> instances = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        instances.add({
          'matchInstanceId': doc.id,
          'userIds': List<String>.from(data['userIds'] ?? []),
          'status': data['status'] ?? 'active',
          'log': List<Map<String, dynamic>>.from(
            (data['log'] ?? []).map((e) => Map<String, dynamic>.from(e)),
          ),
          'channelId': data['channelId'],
        });
      }

      _allMatchInstances = instances;

      if (_firstSnapshotCompleter != null && !_firstSnapshotCompleter!.isCompleted) {
        _firstSnapshotCompleter!.complete();
      }

      notifyListeners();

      if (kDebugMode) {
        print('📡 Match instances updated: ${instances.length} total');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling match instance changes: $e');
      }
    }
  }

  /* = = = = = = = = = 
  Write Match Instance Changes to Firebase
  = = = = = = = = = */

  Future<Map<String, dynamic>> updateMatchStatus(
    String matchInstanceId, 
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('match_instances')
          .doc(matchInstanceId)
          .update({
        'status': newStatus,
        'log': FieldValue.arrayUnion([
          {
            'timestamp': DateTime.now().toIso8601String(),
            'status': newStatus,
            'by': _currentUserId,
          }
        ]),
      });

      return {
        'success': true,
        'message': 'Status updated to $newStatus',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error updating match instance status: $e');
      }
      return {
        'success': false,
        'message': 'Failed to update match status',
      };
    }
  }

  Future<Map<String, dynamic>> chatRequest(String matchId) async {
    try {
      await updateMatchStatus(matchId, 'chat_requested');
      
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

  Future<Map<String, dynamic>> acceptMatch(String matchId, String currentUserId, String otherUserId) async {
    try {
      // Update match status to active
      await updateMatchStatus(matchId, 'matched');
      
      // Create Stream Chat channel
      final chatService = StreamChatService();
      final prefs = await SharedPreferences.getInstance();
      
      // Get current user's data
      final currentUserJson = prefs.getString('inputs_$currentUserId');
      final currentUserData = currentUserJson != null ? jsonDecode(currentUserJson) : {};
      final currentUserName = currentUserData['nameFirst'] ?? 'User';
      final currentUserImage = currentUserData['photos']?[0];
      
      // Get other user's data from users cache
      String otherUserName = 'User';
      String? otherUserImage;
      
      final usersList = prefs.getStringList('users') ?? [];
      for (String userJson in usersList) {
        final user = jsonDecode(userJson);
        if (user['userId'] == otherUserId) {
          otherUserName = user['nameFirst'] ?? 'User';
          otherUserImage = user['photos']?[0];
          break;
        }
      }
      
      // If not found in cache, try fetching from Firebase
      if (otherUserName == 'User') {
        try {
          final doc = await FirebaseFirestore.instance
              .collection('users')
              .doc(otherUserId)
              .get();
          
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            otherUserName = data['nameFirst'] ?? 'User';
            otherUserImage = data['photos']?[0];
          }
        } catch (e) {
          print('Error fetching other user data: $e');
        }
      }
      
      // Connect current user if not connected
      if (!chatService.isUserConnected()) {
        await chatService.connectUser(
          userId: currentUserId,
          userName: currentUserName,
          userImage: currentUserImage,
        );
      }
      
      // Create the chat channel with both users' names
      final channel = await chatService.createMatchChannel(
        matchId: matchId,
        currentUserId: currentUserId,
        otherUserId: otherUserId,
        currentUserName: currentUserName,
        otherUserName: otherUserName,
        currentUserImage: currentUserImage,
        otherUserImage: otherUserImage,
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
      await updateMatchStatus(matchId, 'blocked');

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

  /* = = = = = = = = = 
  Write NEW Match Instance to Firebase
  = = = = = = = = = */

  Future<void> createMatchInstance(
    String currentSessionId,
    Map<String, dynamic> user,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('match_instances').doc().set({
        'userIds': [currentSessionId, user['userId']],
        'status': 'active',
        'compatibility': user['compatibility'],
        'log': [
          {
            'timestamp': DateTime.now().toIso8601String(),
            'status': 'active',
            'by': currentSessionId,
          }
        ],
      });

      if (kDebugMode) {
        print('✅ Created match_instance for ${user['userId']}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error creating match instance: $e');
    }
  }

  Future<void> createMatchEventInstance(
    String currentSessionId,
    Map<String, dynamic> user,
    String eventId,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('match_event_instances').doc().set({
        'userIds': [currentSessionId, user['userId']],
        'eventId': eventId,
        'status': 'active',
        'log': [
          {
            'timestamp': DateTime.now().toIso8601String(),
            'status': 'active',
            'by': currentSessionId,
          }
        ],
      });

      if (kDebugMode) {
        print('✅ Created match_event_instance for ${user['userId']} (Event: $eventId)');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Error creating match event instance: $e');
    }
  }

  /* = = = = = = = = = 
  Dispose 
  = = = = = = = = = */

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
  
}