import 'package:flutter/material.dart';
import '/router/router.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/input_slider.dart';  // Ensure you import the CheckboxFormPage

class EmotionalDynamic extends StatefulWidget {
  const EmotionalDynamic({super.key, required this.title});

  final String title;

  @override
  State<EmotionalDynamic> createState() => _EmotionalDynamic();
}

class _EmotionalDynamic extends State<EmotionalDynamic> {

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
            label: 'Adjust Value',
            initialValue: 50,
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: (value) {
              // Handle the change
              print("Slider Value: $value");
            },
          ),
          MaterialButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.status);
            },
            child: const Text('Begin'),
            color: const Color.fromARGB(255, 226, 33, 243),
          ),
        ],
      ),

    );

  }
}
