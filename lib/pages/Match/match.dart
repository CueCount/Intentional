import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '/router/router.dart';
import '../../widgets/appBar.dart';

class Match extends StatefulWidget {
  const Match({super.key, required this.title});

  final String title;

  @override
  State<Match> createState() => _Match();
}

class _Match extends State<Match> {

  @override
  Widget build(BuildContext context) { 

    return Scaffold( 
      appBar: CustomAppBar(
        route: AppRoutes.home,
      ),
      body: ListView(
        children: <Widget>[
          Column(
            children: [
              Text('THIS IS THE MATCH PAGE'), // Correctly using the Text widget
            ],
          ),
          MaterialButton(
            onPressed: () {
              //Navigator.pushNamed(context, AppRoutes.dashBoard);
            },
            child: const Text('Begin'),
            color: const Color.fromARGB(255, 226, 33, 243),
          ),
        ],
      ),

    );

  }
}
