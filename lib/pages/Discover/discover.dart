import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/ProfileCarousel.dart';
import 'package:provider/provider.dart';
import '../../styles.dart';
import '../../state/discoverState.dart';
import '../../widgets/navigation.dart';
import '../../widgets/updateNeeds.dart';

class Matches extends StatefulWidget {
  const Matches({super.key});
  @override
  State<Matches> createState() => _Matches();
}

class _Matches extends State<Matches> {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;        
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DiscoverState>(context, listen: false).fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final discoverState = Provider.of<DiscoverState>(context);
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(20), 
        decoration: const BoxDecoration(
          gradient: ColorPalette.brandGradient,
        ),
        child: Column(
          children: [
              
            const CustomStatusBar(messagesCount: 2,likesCount: 5,),

            const NotificationCTA(),

            const SizedBox(height: 20),
            
            Expanded(
              child: ProfileCarousel(
                key: UniqueKey(),
                userData: discoverState.users,
                isLoading: discoverState.isLoading,
              ),
            ),

            const SizedBox(height: 20),

          ],
        ),
      ),
    );
  }
}