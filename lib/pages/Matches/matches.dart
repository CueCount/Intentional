import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/profileCarousel.dart';
import '../../widgets/navigation.dart';
import '../../providers/userState.dart'; 
import '../../providers/matchState.dart'; 
import '../../functions/uiService.dart'; 

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
      _ensureListenersActive();
      _initialized = true;
    }
  }

  Future<void> _ensureListenersActive() async {
    final userSync = Provider.of<UserSyncProvider>(context, listen: false);
    final matchSync = Provider.of<MatchSyncProvider>(context, listen: false);

    final userId = await UserActions.getCurrentUserId();
    if (userId != null && userId.isNotEmpty) {
      if (!userSync.isListening) {
        await userSync.startListening(userId);
        print('User Provider: Started listening for available users');
      }
      if (!matchSync.isListening) {
        await matchSync.startListening(userId);
        print('Match Provider: Started listening for matches');
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
              child: Consumer2<MatchSyncProvider, UserSyncProvider>(
                builder: (context, matchSync, userSync, child) {
                  if (matchSync.hasActiveMatch) {
                    final allUsers = userSync.getAllUsers();
                    final matchedUser = matchSync.getActiveMatchUserFromUserProvider(allUsers);
                    final availableUsers = matchedUser != null ? [matchedUser] : <Map<String, dynamic>>[];

                    final isLoading = !matchSync.isListening && availableUsers.isEmpty;
                    
                    return ProfileCarousel(
                      userData: availableUsers,
                      isLoading: isLoading,
                    );
                  } else {
                    final availableUsers = userSync.getAllUsers();
                    final isLoading = !userSync.isListening && availableUsers.isEmpty;
                    
                    return ProfileCarousel(
                      userData: availableUsers,
                      isLoading: isLoading,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}