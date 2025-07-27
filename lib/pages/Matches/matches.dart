import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/ProfileCarousel.dart';
import '../../widgets/navigation.dart';
import '../../functions/airTrafficControler_service.dart';

class Matches extends StatefulWidget {
  final bool shouldUpdate;
  const Matches({Key? key, this.shouldUpdate = true}) : super(key: key);
  
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
      howToFetchUsers(widget.shouldUpdate);
      _initialized = true;
    }
  }

  Future<void> howToFetchUsers(bool shouldUpdate) async {    
    setState(() {
      isLoading = true;
    });

    final fetchedUsers = shouldUpdate
    ? await AirTrafficController().discoverFromFirebase(
        onlyWithPhotos: true,
        forceFresh: true,
      ).then((users) {
        print('🚀 discoverFromFirebase() was called!');
        return users;
      })
    : await AirTrafficController().discoverFromCache().then((users) {
        print('📦 discoverFromCache() was called!');
        return users;
      });
    
    setState(() {
      users = fetchedUsers;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
          children: [
            const CustomStatusBar(messagesCount: 2,likesCount: 5,),
            Expanded(
              child: ProfileCarousel(
                userData: users,
                isLoading: isLoading,
              ),
            ),
          ],
        ),
      );
  }
}