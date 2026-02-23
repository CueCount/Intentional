import 'package:flutter/material.dart';
import 'package:intentional_demo_01/styles.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../providers/userState.dart';
import '../providers/matchState.dart';
import '../providers/inputState.dart';
import '../router/router.dart';
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
    final inputState = Provider.of<InputState>(context, listen: false);
    final lastRefreshString = await inputState.fetchInputFromLocal('last_refresh');
    
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
          Consumer<MatchSyncProvider>(
            builder: (context, matchSync, child) {
              final inputState = Provider.of<InputState>(context, listen: false);
              final currentUserId = inputState.userId;
              
              // Find active match the same way matchCTA does
              final activeMatch = matchSync.allMatches.firstWhere(
                (match) => match['status'] == 'active',
                orElse: () => <String, dynamic>{},
              );

              // If there's an active match, show chat button
              if (activeMatch.isNotEmpty) {
                final matchId = activeMatch['matchId'];
                
                // Determine the other user's ID
                final otherUserId = activeMatch['requesterUserId'] == currentUserId
                    ? activeMatch['requestedUserId']
                    : activeMatch['requesterUserId'];
                
                return TextButton.icon(
                  icon: Text(
                    'Go to Chat',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: ColorPalette.peach,
                    ),
                  ),
                  label: Icon(
                    Icons.chat_bubble_outline,
                    color: ColorPalette.peach,
                    size: 24,
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.only(right: 8.0),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.chat,
                      arguments: {
                        'matchId': matchId,
                        'otherUserName': otherUserId,
                      },
                    );
                  },
                );
              }

              // Otherwise, show refresh button
              return Row(
                children: [
                  if (_canRefresh == false)
                    TextButton.icon(
                      icon: Text(
                        _countdownText,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: ColorPalette.grey,
                        ),
                      ),
                      label: Icon(
                        Icons.refresh,
                        color: ColorPalette.grey,
                        size: 24,
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.only(right: 8.0),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _canRefresh 
                      ? () async {
                          final userSync = Provider.of<UserSyncProvider>(context, listen: false);
                          await userSync.fetchUsersForMatch(context);
                          _checkRefreshStatus();
                        } 
                      : null,
                    ),
                  
                  if (_canRefresh == true)
                    TextButton.icon(
                      icon: Text(
                        'New Profiles',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: ColorPalette.peach,
                        ),
                      ),
                      label: Icon(
                        Icons.refresh,
                        color: ColorPalette.peach,
                        size: 24,
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.only(right: 8.0),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: _canRefresh 
                      ? () async {
                          final userSync = Provider.of<UserSyncProvider>(context, listen: false);
                          await userSync.fetchUsersForMatch(context);
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