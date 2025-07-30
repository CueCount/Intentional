import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/inputState.dart';
import '../../widgets/navigation.dart';
import '../../widgets/link.dart';
import '/router/router.dart';
import '../../functions/loginService.dart';
import '../../styles.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});
  
  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const CustomStatusBar(messagesCount: 2, likesCount: 5),
              Container(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Settings',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: ColorPalette.peach,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Column(
                      children: [
                        LinkWidget(
                          title: 'Safety Tools',
                          description: 'Block, report, and safety features',
                          onTap: () {
                            // Navigate to safety tools page
                            Navigator.pushNamed(context, AppRoutes.home);
                          },
                        ),
                        LinkWidget(
                          title: 'Your Account',
                          description: 'Account settings and preferences',
                          onTap: () {
                            // Navigate to account page
                            Navigator.pushNamed(context, AppRoutes.home);
                          },
                        ),
                        LinkWidget(
                          title: 'Your Photos',
                          description: 'Manage your profile photos',
                          onTap: () {
                            // Navigate to photos page
                            Navigator.pushNamed(context, AppRoutes.photos);
                          },
                        ),
                        LinkWidget(
                          title: 'View Your Profile',
                          description: 'See how others view your profile',
                          onTap: () {
                            final inputState = Provider.of<InputState>(context, listen: false);
                            // Navigate to view profile page
                            Navigator.pushNamed(context, AppRoutes.userprofile, arguments: {'userId': inputState.userId});
                          },
                        ),
                        LinkWidget(
                          title: 'Your Subscription',
                          description: 'Manage your subscription and billing',
                          onTap: () {
                            // Navigate to subscription page
                            Navigator.pushNamed(context, AppRoutes.subscription);
                          },
                        ),
                        LinkWidget(
                          title: 'Pausing Account',
                          description: 'Temporarily pause your account',
                          onTap: () {
                            // Navigate to pause account page
                            Navigator.pushNamed(context, AppRoutes.home);
                          },
                        ),
                        LinkWidget(
                          title: 'Logout',
                          description: 'Sign out of your account',
                          onTap: () {
                            // Handle logout
                            // You might want to show a confirmation dialog here
                            AccountService.logout(context);
                          },
                        ),
                        LinkWidget(
                          title: 'Delete Your Account',
                          description: 'Permanently delete your account',
                          onTap: () {
                            // Navigate to delete account page
                            // You might want to show a confirmation dialog here
                            Navigator.pushNamed(context, AppRoutes.home);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}