import 'package:flutter/material.dart';
import '/router/router.dart';
import '../styles.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/matchState.dart';

class AppMenuOverlay extends StatelessWidget {
  const AppMenuOverlay({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => const AppMenuOverlay(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 24,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Menu items
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    children: [
                      _buildLargeMenuItem(
                        context,
                        'Matches',
                        'Your potential matches are waiting here',
                        () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, AppRoutes.matches);
                        },
                        isPrimary: true,
                      ),
                      const SizedBox(height: 16),
                      
                      // Two-column row - disabled if active match exists
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: Provider.of<MatchSyncProvider>(context, listen: false).getActiveMatchUser(),
                        builder: (context, snapshot) {
                          final hasActiveMatch = snapshot.hasData && snapshot.data!.isNotEmpty;
                          
                          return Row(
                            children: [
                              Expanded(
                                child: _buildSmallMenuItem(
                                  context,
                                  'Requests\nReceived',
                                  'Check if you received any match requests',
                                  hasActiveMatch 
                                    ? () {} // No-op when disabled
                                    : () {
                                        Navigator.of(context).pop();
                                        Navigator.pushNamed(context, AppRoutes.requestsReceived);
                                      },
                                  isDisabled: hasActiveMatch,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSmallMenuItem(
                                  context,
                                  'Requests\nSent',
                                  'Check the status of your sent match requests',
                                  hasActiveMatch 
                                    ? () {} // No-op when disabled
                                    : () {
                                        Navigator.of(context).pop();
                                        Navigator.pushNamed(context, AppRoutes.requestsSent);
                                      },
                                  isDisabled: hasActiveMatch,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      _buildLargeMenuItem(
                        context,
                        'Your Needs',
                        'Edit your stated needs',
                        () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, AppRoutes.editNeeds);
                        },
                        isPrimary: true,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildLargeMenuItem(
                        context,
                        'Your Account',
                        'Edit your info, photos, subscription or logout',
                        () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, AppRoutes.settings);
                        },
                        isPrimary: false,
                      ),
                      const SizedBox(height: 16),
                      
                      _buildDebugMenuItem(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLargeMenuItem(
    BuildContext context,
    String title,
    String subtitle,
    VoidCallback onTap, {
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: isPrimary 
            ? ColorPalette.peach 
            : ColorPalette.peach.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: AppTextStyles.headingMedium.copyWith(
                color: isPrimary 
                  ? Colors.white 
                  : ColorPalette.peach,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: isPrimary 
                  ? Colors.white.withOpacity(0.9) 
                  : ColorPalette.peach.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallMenuItem(
    BuildContext context,
    String title,
    String subtitle,
    VoidCallback onTap, {
    bool isDisabled = false,
  }) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        height: 180,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isDisabled 
            ? Colors.grey.shade300 
            : ColorPalette.peach.withOpacity(0.2),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: AppTextStyles.headingMedium.copyWith(
                color: isDisabled 
                  ? Colors.grey.shade500 
                  : ColorPalette.peach,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDisabled 
                  ? Colors.grey.shade400 
                  : ColorPalette.peach.withOpacity(0.8),
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugMenuItem(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        Navigator.of(context).pop();
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys();
        print('\n========== SHARED PREFERENCES ==========');
        for (String key in keys) {
          final value = prefs.get(key);
          print('$key: $value');
        }
        print('========== END ==========\n');
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Debug Prefs',
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}