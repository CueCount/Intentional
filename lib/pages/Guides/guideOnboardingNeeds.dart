import 'package:flutter/material.dart';
import '/router/router.dart';
import '../../styles.dart';

class GuideOnboardingNeeds extends StatefulWidget {
  const GuideOnboardingNeeds({super.key});
  @override
  State<GuideOnboardingNeeds> createState() => _GuideOnboardingNeeds();
}

class _GuideOnboardingNeeds extends State<GuideOnboardingNeeds> {
  @override
  Widget build(BuildContext context) {
    void noOperation() {}
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: ColorPalette.peach,
            image: DecorationImage(
              image: AssetImage('assets/compressed_funPart.jpg'),
              fit: BoxFit.cover,
              opacity: 0.5,
            ),
          ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.celebration,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                'Here\'s the Fun Part!',
                style: AppTextStyles.headingLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Your needs and preferences are what make your matches',
                style: AppTextStyles.headingSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {Navigator.pushNamed(context, AppRoutes.chemistry);},
                icon: Text(
                  'Define Your Needs',
                  style: AppTextStyles.headingMedium,
                ),
                label: const Icon(Icons.arrow_forward, color: Colors.white),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}