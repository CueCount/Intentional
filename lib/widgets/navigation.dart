import 'package:flutter/material.dart';
import '../functions/helpers/matchesCountService.dart';
import '../styles.dart';
import 'menu.dart';
import '../router/router.dart';
import '../functions/userActionsService.dart';
import '../functions/matchesService.dart';

class CustomStatusBar extends StatefulWidget {
  const CustomStatusBar({
    Key? key,
  }) : super(key: key);

  @override
  State<CustomStatusBar> createState() => _CustomStatusBarState();
}

class _CustomStatusBarState extends State<CustomStatusBar> {
  bool infoIncomplete = false;
  bool needsUpdated = false;
  int refinedMatchesCount = 12000;
  bool _isLoading = true;
  bool _isDisposed = false; // Add disposal tracking

  @override
  void initState() {
    super.initState();
    // Add small delay to prevent immediate rebuild conflicts
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_isDisposed) {
        _checkNotificationStatus();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _checkNotificationStatus() async {
    // Early exit if widget is disposed
    if (_isDisposed || !mounted) return;
    
    try {
      // Use centralized ID management
      String? userId = await UserActions.getCurrentUserId();
      
      // Check again after async operation
      if (_isDisposed || !mounted) return;
      
      if (userId == null) {
        print('⚠️ No user ID found in UserIdManager');
        if (!_isDisposed && mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Batch all async operations
      final results = await Future.wait([
        UserActions.isInfoIncomplete(userId),
        MatchCountService.getRefinedMatchesCount(),
        UserActions().isNeedsUpdated(userId),
      ]);
      
      // Final check before setState
      if (!_isDisposed && mounted) {
        setState(() {
          infoIncomplete = results[0] as bool;
          refinedMatchesCount = results[1] as int;
          needsUpdated = results[2] as bool;
          _isLoading = false;
        });
        
        print('✅ Status updated - Info: $infoIncomplete, Matches: $refinedMatchesCount, Needs: $needsUpdated');
      }
      
    } catch (e) {
      print('❌ Error checking notification status: $e');
      if (!_isDisposed && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () { 
              AppMenuOverlay.show(context); 
            },
          ), 
          _buildNotificationText(context),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.editNeeds);
            },
          )
        ],
      ),
    );
  }

  Widget _buildNotificationText(BuildContext context) {
    if (infoIncomplete && needsUpdated) {
      return Text(
        '$refinedMatchesCount Matches',
        style: AppTextStyles.bodySmall.copyWith(color: ColorPalette.grey,),
      );
    } 
    else if (needsUpdated) {
      return GestureDetector(
        onTap: () async {
          await MatchesService().refreshMatches(context);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.refresh,
              size: 18,
              color: ColorPalette.grey,
            ),
            const SizedBox(width: 4),
            Text(
              'Refresh Matches',
              style: AppTextStyles.bodySmall.copyWith(color: ColorPalette.grey,),
            ),
          ],
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}