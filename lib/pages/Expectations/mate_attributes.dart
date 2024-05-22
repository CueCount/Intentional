import 'package:flutter/material.dart';
import '/router/router.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/input_gallery.dart';  // Ensure you import the CheckboxFormPage

class MateAttributes extends StatefulWidget {
  const MateAttributes({super.key, required this.title});

  final String title;

  @override
  State<MateAttributes> createState() => _MateAttributes();
}

class _MateAttributes extends State<MateAttributes> {

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
          CustomCheckbox(
            title: 'Physically Strong and Bruiting',
            initialValue: true,
            onChanged: (value) {
              // Handle change
              print("Physically Strong and Bruiting: $value");
            },
          ),
          CustomCheckbox(
            title: 'Mature and Thoughtful',
            initialValue: false,
            onChanged: (value) {
              // Handle change
              print("Mature and Thoughtful: $value");
            },
          ),
          CustomCheckbox(
            title: 'Assertive and Leading',
            initialValue: false,
            onChanged: (value) {
              // Handle change
              print("Assertive and Leading: $value");
            },
          ),
          CustomCheckbox(
            title: 'Intelligent and Nerdy',
            initialValue: false,
            onChanged: (value) {
              // Handle change
              print("Intelligent and Nerdy: $value");
            },
          ),
          CustomCheckbox(
            title: 'Spontaneous and Romantic',
            initialValue: false,
            onChanged: (value) {
              // Handle change
              print("Spontaneous and Romantic: $value");
            },
          ),
          CustomCheckbox(
            title: 'High Earning High Status',
            initialValue: false,
            onChanged: (value) {
              // Handle change
              print("High Earning High Status: $value");
            },
          ),
          MaterialButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.logistics);
            },
            child: const Text('Begin'),
            color: const Color.fromARGB(255, 226, 33, 243),
          ),
        ],
      ),

    );

  }
}
