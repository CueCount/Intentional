import 'package:flutter/material.dart';
import '/router/router.dart';
import '../../styles.dart';

class GuideAvailableMatches extends StatefulWidget {
  const GuideAvailableMatches({super.key});
  @override
  State<GuideAvailableMatches> createState() => _GuideAvailableMatches();
}

class _GuideAvailableMatches extends State<GuideAvailableMatches> {
  @override
  Widget build(BuildContext context) {
    void noOperation() {}
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: ColorPalette.peach,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'Look at All These Potential Matches!',
                style: AppTextStyles.headingLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Lorium ipsum x1000',
                style: AppTextStyles.headingSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                width: 180,
                height: 180,
                decoration: const BoxDecoration(
                  color: Colors.grey,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {Navigator.pushNamed(context, AppRoutes.photos);},
                icon: Text(
                  'Verify Yourself to Start Sending Requests',
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