import 'package:flutter/material.dart';
import '../../widgets/ProfileCarousel.dart';
import '../../router/router.dart';
import '../../styles.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/firestore_service.dart';
import '../../widgets/navigation.dart';

class Matches extends StatefulWidget {
  const Matches({super.key, required this.title});
  final String title;

  @override
  State<Matches> createState() => _Matches();
}

class _Matches extends State<Matches> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    FirestoreService firestoreService = FirestoreService();
    List<Map<String, dynamic>> fetchedUsers = await firestoreService.fetchUsers();

    if (mounted) { 
      setState(() {
        users = fetchedUsers;
        isLoading = false;
      });
      print("🚀 profiles type: ${users.runtimeType}, length: ${users.length}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20), 
        decoration: const BoxDecoration(
          gradient: ColorPalette.brandGradient,
        ),
        child: Column(
          children: [
              
            const CustomStatusBar(
              messagesCount: 2,
              likesCount: 5,
            ),

            const SizedBox(height: 20),
            
            isLoading 
              ? const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              : Expanded(
                  child: ProfileCarousel(
                    key: ValueKey(users.length), // Forces a rebuild when users change
                    userData: users,
                  ),
                ),

            const SizedBox(height: 20),

          ],
        ),
      ),
    );
  }
}