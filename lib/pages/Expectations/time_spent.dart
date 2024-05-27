import 'package:flutter/material.dart';
import '/router/router.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/input_slider.dart';  // Ensure you import the CheckboxFormPage

class TimeSpent extends StatefulWidget {
  const TimeSpent({super.key, required this.title});

  final String title;

  @override
  State<TimeSpent> createState() => _TimeSpent();
}

class _TimeSpent extends State<TimeSpent> {

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
            label: 'How much time per week should you spend together in the dating phase?',
            initialValue: 50,
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: (value) {
              // Handle the change
              print("How much time per week should you spend together in the dating phase?: $value");
            },
          ),
          CustomSlider(
            label: 'How much time per week should you spend together in a commited relatinoship?',
            initialValue: 50,
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: (value) {
              // Handle the change
              print("How much time per week should you spend together in a commited relatinoship?: $value");
            },
          ),
          MaterialButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.tone);
            },
            child: const Text('Begin'),
            color: const Color.fromARGB(255, 226, 33, 243),
          ),
        ],
      ),

    );

  }
}
