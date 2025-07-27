import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/navigation.dart';
import '../../widgets/link.dart';
import '../../data/inputState.dart';
import '/router/router.dart';

class EditNeeds extends StatefulWidget {
  const EditNeeds({super.key});
  
  @override
  State<EditNeeds> createState() => _EditNeedsState();
}

class _EditNeedsState extends State<EditNeeds> {
  @override
  Widget build(BuildContext context) {
    final inputState = Provider.of<InputState>(context);
    
    return Scaffold(
      body: Column(
        children: [
          const CustomStatusBar(messagesCount: 2,likesCount: 5,),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Needs',
                    style: TextStyle(
                      color: Color(0xFFFF6B6B), // Brand peach color
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Expanded(
                    child: ListView(
                      children: [
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
                          title: 'Physical',
                          description: 'Physical preferences and attributes',
                          onTap: () {
                            // Navigate to physical page
                            Navigator.pushNamed(context, AppRoutes.physical);
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
                        LinkWidget(
                          title: 'Age',
                          description: 'Age preferences and range',
                          onTap: () {
                            // Navigate to age page
                            Navigator.pushNamed(context, AppRoutes.age);
                          },
                        ),
                        LinkWidget(
                          title: 'Basic Info',
                          description: 'Personal information and details',
                          onTap: () {
                            // Navigate to basic info page
                            Navigator.pushNamed(context, AppRoutes.basicInfo);
                          },
                        ),
                        LinkWidget(
                          title: 'Photos',
                          description: 'Manage your profile photos',
                          onTap: () {
                            // Navigate to photos page
                            Navigator.pushNamed(context, AppRoutes.photos);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}