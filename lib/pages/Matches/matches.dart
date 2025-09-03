import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/profileCarousel.dart';
import '../../widgets/navigation.dart';
import '../../providers/userState.dart'; // Add this import
import '../../functions/uiService.dart'; // For getCurrentUserId()

class Matches extends StatefulWidget {
  final bool shouldUpdate;
  const Matches({Key? key, this.shouldUpdate = false}) : super(key: key);
  
  @override
  State<Matches> createState() => _Matches();
}

class _Matches extends State<Matches> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _ensureUserListenersActive();
      _initialized = true;
    }
  }

  Future<void> _ensureUserListenersActive() async {
    final userSync = Provider.of<UserSyncProvider>(context, listen: false);

    if (!userSync.isListening) {
      final userId = await UserActions.getCurrentUserId();
      if (userId != null && userId.isNotEmpty) {
        await userSync.startListening(userId);
        print('User Provider: Started listening for available users');
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
              child: Consumer<UserSyncProvider>(
                builder: (context, userSync, child) {
                  // Get users with photos only (for matching)
                  final availableUsers = userSync.getUsersWithPhotos();
                  final isLoading = !userSync.isListening && availableUsers.isEmpty;
                  
                  return ProfileCarousel(
                    userData: availableUsers,
                    isLoading: isLoading,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}