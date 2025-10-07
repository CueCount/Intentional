import 'package:flutter/material.dart';
import '/router/router.dart';
import '../../styles.dart';

class GuideRequestSent extends StatefulWidget {
  const GuideRequestSent({super.key});
  @override
  State<GuideRequestSent> createState() => _GuideRequestSent();
}

class _GuideRequestSent extends State<GuideRequestSent> {
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
                'Your Match Request Has Been Sent',
                style: AppTextStyles.headingLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'You will be automatically matched with her if she is the first request to be responded to.',
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
                onPressed: () {Navigator.pushNamed(context, AppRoutes.matches);},
                icon: Text(
                  'Keep Exploring Matches',
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