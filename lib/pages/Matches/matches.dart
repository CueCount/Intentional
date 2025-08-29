import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/profileCarousel.dart';
import '../../widgets/navigation.dart';
import '../../functions/matchesService.dart';

class Matches extends StatefulWidget {
  final bool shouldUpdate;
  const Matches({Key? key, this.shouldUpdate = false}) : super(key: key);
  
  @override
  State<Matches> createState() => _Matches();
}

class _Matches extends State<Matches> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      print('🧠 shouldUpdate value from constructor: ${widget.shouldUpdate}');
      fetchMatches();
      _initialized = true;
    }
  }

  Future<void> fetchMatches() async {    
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final fetchedUsers = await MatchesService().fetchMatches(
        fromFirebase: widget.shouldUpdate,
        onlyWithPhotos: true,
        forceFresh: widget.shouldUpdate,
      );
      
      if (mounted) {
        setState(() {
          users = fetchedUsers;
          isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error in fetchMatches: $e');
      
      if (mounted) {
        setState(() {
          isLoading = false;
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
            Expanded(
              child: ProfileCarousel(
                userData: users,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }
}