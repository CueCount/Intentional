import 'package:flutter/material.dart';
import 'package:intentional_demo_01/styles.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../router/router.dart';
import '../providers/userState.dart';
import '../providers/matchState.dart';
import 'menu.dart';

class CustomStatusBar extends StatefulWidget {
  const CustomStatusBar({
    Key? key,
  }) : super(key: key);

  @override
  State<CustomStatusBar> createState() => _CustomStatusBarState();
}

class _CustomStatusBarState extends State<CustomStatusBar> {
  Timer? _countdownTimer;
  bool _canRefresh = true;
  String _countdownText = '';

  @override
  void initState() {
    super.initState();
    _checkRefreshStatus();
    // Start a timer to update countdown every minute
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkRefreshStatus();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkRefreshStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final lastRefreshString = prefs.getString('last_refresh');
    
    if (lastRefreshString == null) {
      // Never refreshed before, allow refresh
      setState(() {
        _canRefresh = true;
        _countdownText = '';
      });
      return;
    }
    
    try {
      final lastRefresh = DateTime.parse(lastRefreshString);
      final now = DateTime.now();
      final difference = now.difference(lastRefresh);
      
      // Check if 10 hours have passed
      const cooldownDuration = Duration(hours: 10);
      
      if (difference >= cooldownDuration) {
        setState(() {
          _canRefresh = true;
          _countdownText = '';
        });
      } else {
        // Calculate remaining time
        final remaining = cooldownDuration - difference;
        
        setState(() {
          _canRefresh = false;
          
          if (remaining.inHours > 0) {
            // Show hours remaining
            final hours = remaining.inHours;
            final minutes = remaining.inMinutes % 60;
            if (hours == 1 && minutes == 0) {
              _countdownText = '1 hour';
            } else if (minutes > 0) {
              _countdownText = '${hours}h ${minutes}m';
            } else {
              _countdownText = '$hours hours';
            }
          } else {
            // Less than an hour, show minutes
            final minutes = remaining.inMinutes;
            if (minutes <= 1) {
              _countdownText = '1 minute';
            } else {
              _countdownText = '$minutes minutes';
            }
          }
        });
      }
    } catch (e) {
      // If there's an error parsing, allow refresh
      setState(() {
        _canRefresh = true;
        _countdownText = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Padding(padding: EdgeInsets.all(24)); 
    }

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          /* = = = = = = = = = = 
          Menu Button
          = = = = = = = = = = */
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () { 
              AppMenuOverlay.show(context); 
            },
          ), 

          /* = = = = = = = = = = 
          Refresh/Chat Button
          = = = = = = = = = = */
          FutureBuilder<List<Map<String, dynamic>>>(
            future: Provider.of<MatchSyncProvider>(context, listen: false).getActiveMatchUser(),
            builder: (context, snapshot) {
              // While loading, show nothing or a loading indicator
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(width: 48); 
              }
              
              // If there's an active match, show chat button
              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return IconButton(
                  icon: const Icon(
                    Icons.chat_bubble_outline, color: ColorPalette.peach
                  ),
                  onPressed: () {
                     Navigator.pushNamed(context, AppRoutes.chat, arguments: snapshot.data);
                  },
                );
              }
              
              // Otherwise, show refresh button
              return Row(
                children: [
                  if (_countdownText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Text(
                        _countdownText,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: _canRefresh ? ColorPalette.peach : Colors.grey[400],
                      ),
                      onPressed: _canRefresh 
                      ? () async {
                          final userSync = Provider.of<UserSyncProvider>(context, listen: false);
                          await userSync.refreshDiscoverableUsers(context);
                          _checkRefreshStatus();
                        } 
                      : null,
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  
}