import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/ProfileCarousel.dart';
import '../../widgets/navigation.dart';
import '../../providers/inputState.dart';

class MatchesEvent extends StatefulWidget {
  final String eventId;
  const MatchesEvent({Key? key, required this.eventId}) : super(key: key);

  @override
  State<MatchesEvent> createState() => _MatchesEventState();
}

class _MatchesEventState extends State<MatchesEvent> {
  List<Map<String, dynamic>> _matchEventInstances = [];
  bool _isLoading = true;
  String? _eventName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEventDetails();
      _loadMatchEventInstances();
    });
  }

  /// Fetch the event document to get metadata like the event name.
  Future<void> _loadEventDetails() async {
    try {
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(widget.eventId)
          .get();

      if (eventDoc.exists && mounted) {
        setState(() {
          _eventName = eventDoc.data()?['eventName'] ?? 'Event';
        });
      }
    } catch (e) {
      print('Error loading event details: $e');
    }
  }

  /// Fetch match_event_instances where the current user is a participant
  /// and the instance is associated with the given event ID.
  Future<void> _loadMatchEventInstances() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final inputState = Provider.of<InputState>(context, listen: false);
      final userId = inputState.userId;

      // Query match_event_instances for this event where the current user is involved
      final snapshot = await FirebaseFirestore.instance
          .collection('match_event_instances')
          .where('eventId', isEqualTo: widget.eventId)
          .where('users', arrayContains: userId)
          .get();

      final instances = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      if (mounted) {
        setState(() {
          _matchEventInstances = instances;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading match event instances: $e');
      if (mounted) {
        setState(() {
          _matchEventInstances = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const CustomStatusBar(),
            if (_eventName != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                child: Text(
                  _eventName!,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Expanded(
              child: ProfileCarousel(
                matchInstances: _matchEventInstances,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}