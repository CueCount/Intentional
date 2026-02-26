import 'package:flutter/material.dart';
import 'package:intentional_demo_01/styles.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  int _previousMatchCount = 0;
  bool _hasNewProfiles = false;

  @override
  void initState() {
    super.initState();
    // Capture the initial count after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final matchSync = Provider.of<MatchSyncProvider>(context, listen: false);
      _previousMatchCount = matchSync.allMatchInstances.length;
    });
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
          LEFT: Notification / Profile Count
          = = = = = = = = = = */
          Consumer<MatchSyncProvider>(
            builder: (context, matchSync, child) {
              final currentCount = matchSync.allMatchInstances.length;

              // Detect if new profiles were added via the listener
              if (currentCount > _previousMatchCount && _previousMatchCount > 0) {
                // Schedule the state update for after this build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_hasNewProfiles) {
                    setState(() => _hasNewProfiles = true);
                  }
                });
              }

              return GestureDetector(
                onTap: () {
                  // Dismiss the "new" indicator when tapped
                  if (_hasNewProfiles) {
                    setState(() {
                      _hasNewProfiles = false;
                      _previousMatchCount = currentCount;
                    });
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Profile count badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _hasNewProfiles
                                ? ColorPalette.peach.withOpacity(0.15)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 20,
                                color: _hasNewProfiles
                                    ? ColorPalette.peach
                                    : ColorPalette.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '$currentCount',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: _hasNewProfiles
                                      ? ColorPalette.peach
                                      : ColorPalette.grey,
                                  fontWeight: _hasNewProfiles
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // New profile dot indicator
                        if (_hasNewProfiles)
                          Positioned(
                            top: -3,
                            right: -3,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: ColorPalette.peach,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                      ],
                    ),

                    // "New!" label that appears when new profiles are detected
                    if (_hasNewProfiles) ...[
                      const SizedBox(width: 8),
                      Text(
                        'New!',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: ColorPalette.peach,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),

          /* = = = = = = = = = = 
          RIGHT: Menu Button
          = = = = = = = = = = */
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              AppMenuOverlay.show(context);
            },
          ),
        ],
      ),
    );
  }
}