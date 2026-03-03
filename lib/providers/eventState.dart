import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';

class EventSyncProvider extends ChangeNotifier {
  // Private variables
  StreamSubscription<QuerySnapshot>? _eventsListener;
  String? _currentUserId;
  bool _isListening = false;
  List<String> _eventIds = [];

  // Public getters
  bool get isListening => _isListening;
  String? get currentUserId => _currentUserId;

  // Cached event data — fed by the listener
  List<Map<String, dynamic>> _activeEvents = [];
  List<Map<String, dynamic>> get activeEvents => List.from(_activeEvents);

  Completer<void>? _firstSnapshotCompleter;
  Future<void> get firstSnapshotReady => _firstSnapshotCompleter?.future ?? Future.value();

  /* = = = = = = = = = 
  Start Listener
  Listens for events that the user is associated with
  and whose endDate has not passed
  = = = = = = = = = */

  Future<void> startListening(String currentSessionId) async {
    if (_isListening && _currentUserId == currentSessionId) {
      if (kDebugMode) {
        print('🎧 Already listening for events for user: $currentSessionId');
      }
      return;
    }

    await stopListening();
    _currentUserId = currentSessionId;
    _firstSnapshotCompleter = Completer<void>();

    try {
      // Get the user's eventIds from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final inputsJson = prefs.getString('inputs_$currentSessionId');

      if (inputsJson == null) {
        if (kDebugMode) print('⚠️ No inputs found for $currentSessionId');
        _completeFirstSnapshot();
        return;
      }

      final inputsData = jsonDecode(inputsJson);
      _eventIds = List<String>.from(inputsData['events'] ?? []);

      if (_eventIds.isEmpty) {
        if (kDebugMode) print('⚠️ No eventIds for $currentSessionId');
        _completeFirstSnapshot();
        return;
      }

      // Firestore whereIn supports up to 30 values — fine for events per user
      _eventsListener = FirebaseFirestore.instance
          .collection('events')
          .where(FieldPath.documentId, whereIn: _eventIds)
          .snapshots()
          .listen(
            (snapshot) => _handleEventChanges(snapshot),
            onError: (error) {
              if (kDebugMode) {
                print('❌ Events listener error: $error');
              }
            },
          );

      _isListening = true;

      if (kDebugMode) {
        print('🎧 Started events listener for: $currentSessionId (${_eventIds.length} events)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error starting events listener: $e');
      }
      _completeFirstSnapshot();
    }
  }

  Future<void> stopListening() async {
    await _eventsListener?.cancel();
    _eventsListener = null;
    _currentUserId = null;
    _isListening = false;
    _activeEvents = [];
    _eventIds = [];

    if (kDebugMode) {
      print('🔇 Stopped events listener');
    }
  }

  /* = = = = = = = = =
  Handle Incoming Changes from Firebase
  = = = = = = = = = */

  void _handleEventChanges(QuerySnapshot snapshot) {
    try {
      final List<Map<String, dynamic>> events = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        events.add({
          'eventId': doc.id,
          'eventName': data['eventName'] ?? 'Event',
          'urlId': data['urlId'],
          'eventTimestamp': data['eventTimestamp'],
          'endDate': data['endDate'],
          'createdAt': data['createdAt'],
        });
      }

      _activeEvents = events;

      _completeFirstSnapshot();

      notifyListeners();

      if (kDebugMode) {
        print('📡 Active events updated: ${events.length} total');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling event changes: $e');
      }
    }
  }

  /* = = = = = = = = = 
  Helpers
  = = = = = = = = = */

  void _completeFirstSnapshot() {
    if (_firstSnapshotCompleter != null && !_firstSnapshotCompleter!.isCompleted) {
      _firstSnapshotCompleter!.complete();
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