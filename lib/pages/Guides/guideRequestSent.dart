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
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: ColorPalette.peach,
            image: DecorationImage(
              image: AssetImage('assets/compressed_sentRequest.jpg'),
              fit: BoxFit.cover,
              opacity: 0.5,
            ),
          ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.message,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
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