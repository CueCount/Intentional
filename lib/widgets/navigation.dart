import 'package:flutter/material.dart';
import '../functions/helpers/matchesCountService.dart';
import '../styles.dart';
import 'menu.dart';
import '../router/router.dart';
import '../functions/uiService.dart';
import '../functions/matchesService.dart';

class CustomStatusBar extends StatefulWidget {
  const CustomStatusBar({
    Key? key,
  }) : super(key: key);

  @override
  State<CustomStatusBar> createState() => _CustomStatusBarState();
}

class _CustomStatusBarState extends State<CustomStatusBar> {
  int refinedMatchesCount = 12000;
  bool infoIncomplete = true;
  bool needsUpdated = false;
  bool _isLoading = true;
  bool _isDisposed = false;

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
    if (_isDisposed || !mounted) return;
    
    try {
      String? userId = await UserActions.getCurrentUserId();
      
      if (_isDisposed || !mounted) return;
      
      if (userId == null) {
        // Handle no user case
        return;
      }

      // Read status once here
      Map<String, bool> status = await UserActions.readStatus(userId, [
        'infoIncomplete', 
        'needsUpdated', 
        'available'
      ]);
      
      if (!_isDisposed && mounted) {
        setState(() {
          infoIncomplete = status['infoIncomplete'] ?? true;
          needsUpdated = status['needsUpdated'] ?? false;
          _isLoading = false;
        });
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
    if (infoIncomplete) {
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