import 'package:flutter/material.dart';
import '../../widgets/navigation.dart';
import '../../widgets/link.dart';
import '/router/router.dart';
import '../../styles.dart';
class EditNeeds extends StatefulWidget {
  const EditNeeds({super.key});
  
  @override
  State<EditNeeds> createState() => _EditNeedsState();
}

class _EditNeedsState extends State<EditNeeds> {
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
                      'Your Needs',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: ColorPalette.peach,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Column(
                      children: [
                        LinkWidget(
                          title: 'Relationship Type',
                          description: 'What type of relationship you need',
                          onTap: () {
                            // Navigate to chemistry page
                            Navigator.pushNamed(context, AppRoutes.basics);
                          },
                        ),
                        LinkWidget(
                          title: 'Chemistry',
                          description: 'Define your relationship chemistry preferences',
                          onTap: () {
                            // Navigate to chemistry page
                            Navigator.pushNamed(context, AppRoutes.chemistry);
                          },
                        ),
                        LinkWidget(
                          title: 'Interests',
                          description: 'Share your hobbies and activities',
                          onTap: () {
                            // Navigate to interests page
                            Navigator.pushNamed(context, AppRoutes.interests);
                          },
                        ),
                        LinkWidget(
                          title: 'Relationship',
                          description: 'Set your relationship goals and expectations',
                          onTap: () {
                            // Navigate to relationship page
                            Navigator.pushNamed(context, AppRoutes.relationship);
                          },
                        ),
                        LinkWidget(
                          title: 'Goals',
                          description: 'Life goals and aspirations',
                          onTap: () {
                            // Navigate to goals page
                            Navigator.pushNamed(context, AppRoutes.goals);
                          },
                        ),
                        LinkWidget(
                          title: 'Qualifiers',
                          description: 'Basic qualifying preferences',
                          onTap: () {
                            // Navigate to qualifiers page
                            Navigator.pushNamed(context, AppRoutes.qual);
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