import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/navigation.dart';
import '../../widgets/link.dart';
import '../../widgets/errorDialog.dart';
import '/router/router.dart';
import '../../providers/authState.dart';
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
              const CustomStatusBar(),
              Container(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Your Account',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: ColorPalette.peach,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Column(
                      children: [
                        LinkWidget(
                          title: 'Your Information',
                          description: 'Edit your First Name, Email, and Password',
                          onTap: () {
                            // Navigate to account page
                            Navigator.pushNamed(context, AppRoutes.registerInfo);
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
                          title: 'Your Subscription',
                          description: '[Not available for this demo] Manage your subscription and billing',
                          onTap: () {
                            // Navigate to subscription page
                            Navigator.pushNamed(context, AppRoutes.subscription);
                          },
                        ),
                        /*LinkWidget(
                          title: 'Reset Local Data',
                          description: 'Manage your subscription and billing',
                          onTap: () {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => RefreshDataWidget(
                                errorContext: 'Missing data detected',
                                onComplete: () => setState(() {}),
                              ),
                            );
                          },
                        ),*/
                        LinkWidget(
                          title: 'Logout',
                          description: 'Sign out of your account',
                          onTap: () {
                            // Handle logout
                            // You might want to show a confirmation dialog here
                            final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
                            authProvider.signOut();
                          },
                        ),
                        /*LinkWidget(
                          title: 'Delete Your Account',
                          description: 'Permanently delete your account',
                          onTap: () {
                            // Navigate to delete account page
                            // You might want to show a confirmation dialog here
                            Navigator.pushNamed(context, AppRoutes.home);
                          },
                        ),*/
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