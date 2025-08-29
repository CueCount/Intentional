import 'package:flutter/material.dart';
import '/router/router.dart';
import '../styles.dart';

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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      _buildMenuItem(
                        context,
                        'Matches',
                        () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, AppRoutes.matches);
                        },
                      ),
                      const Spacer(),
                      _buildMenuItem(
                        context,
                        'Requests Received',
                        () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, AppRoutes.requestsReceived);
                        },
                      ),
                      const Spacer(),
                      _buildMenuItem(
                        context,
                        'Requests Sent',
                        () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, AppRoutes.requestsSent);
                        },
                      ),
                      const Spacer(),
                      _buildMenuItem(
                        context,
                        'Your Needs',
                        () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, AppRoutes.editNeeds);
                        },
                      ),
                      const Spacer(),
                      _buildMenuItem(
                        context,
                        'Settings',
                        () {
                          Navigator.of(context).pop();
                          Navigator.pushNamed(context, AppRoutes.settings);
                        },
                      ),
                      const Spacer(),
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

  Widget _buildMenuItem(BuildContext context, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(
          title,
          style: AppTextStyles.headingMedium.copyWith(
            color: ColorPalette.peach,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}