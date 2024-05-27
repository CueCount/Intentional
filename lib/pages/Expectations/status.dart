import 'package:flutter/material.dart';
import '/router/router.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/input_slider.dart';  // Ensure you import the CheckboxFormPage

class StatusDynamic extends StatefulWidget {
  const StatusDynamic({super.key, required this.title});

  final String title;

  @override
  State<StatusDynamic> createState() => _StatusDynamic();
}

class _StatusDynamic extends State<StatusDynamic> {

  @override
  Widget build(BuildContext context) { 

    return Scaffold( 
      appBar: CustomAppBar(
        title: widget.title,
        isLoggedIn: true,
        hasSubmittedForm: true,
      ),
      endDrawer: CustomDrawer(), 
      body: ListView(
        children: <Widget>[
          CustomSlider(
            label: 'Who should be more generous with their time and energy?',
            initialValue: 50,
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: (value) {
              // Handle the change
              print("Who should be more generous with their time and energy?: $value");
            },
          ),
          CustomSlider(
            label: 'Who should have a higher social status and life/career accomplishments?',
            initialValue: 50,
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: (value) {
              // Handle the change
              print("Who should have a higher social status and life/career accomplishments?: $value");
            },
          ),
          MaterialButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.timeSpent);
            },
            child: const Text('Continue'),
            color: const Color.fromARGB(255, 226, 33, 243),
          ),
        ],
      ),

    );

  }
}
