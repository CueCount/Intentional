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
            title: 'Check Option 1',
            initialValue: true,
            onChanged: (value) {
              // Handle change
              print("Option 1: $value");
            },
          ),
          CustomCheckbox(
            title: 'Check Option 2',
            initialValue: false,
            onChanged: (value) {
              // Handle change
              print("Option 2: $value");
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
