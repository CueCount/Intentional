import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '/router/router.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';

class Verifications extends StatefulWidget {
  const Verifications({super.key, required this.title});

  final String title;

  @override
  State<Verifications> createState() => _Verifications();
}

class _Verifications extends State<Verifications> {

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
          Column(
            children: [
              Text('THIS IS THE VERIFICATIONS PAGE'), // Correctly using the Text widget
            ],
          ),
          MaterialButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.dashBoard);
            },
            child: const Text('Begin'),
            color: const Color.fromARGB(255, 226, 33, 243),
          ),
        ],
      ),

    );

  }
}
