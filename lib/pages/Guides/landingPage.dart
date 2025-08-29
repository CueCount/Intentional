import 'package:flutter/material.dart';
import '/router/router.dart';
import '../../styles.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
                'Everything\nChanges When\nIt\'s Just You\nand Them',
                style: AppTextStyles.headingLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'One match at a time.\n One chat at a time.\n & the space to explore something real. ',
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
              Column(
                children: [
                  TextButton.icon(
                    onPressed: () {Navigator.pushNamed(context, AppRoutes.qual);},
                    icon: Text(
                      'Get Started',
                      style: AppTextStyles.headingMedium,
                    ),
                    label: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () {Navigator.pushNamed(context, AppRoutes.login);},
                    icon: Text(
                      'Login',
                      style: AppTextStyles.headingMedium,
                    ),
                    label: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ],
              )
            ],
          ),
        ),
        ),
      ),
    );
  }
}