import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '/router/router.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';

class MatchChat extends StatefulWidget {
  const MatchChat({super.key, required this.title});
  final String title;
  @override
  State<MatchChat> createState() => _MatchChat();
}

class _MatchChat extends State<MatchChat> {

  @override
  Widget build(BuildContext context) { 

    return Scaffold( 
      appBar: CustomAppBar(
        route: AppRoutes.home,
      ),
      endDrawer: CustomDrawer(), 
      body: ListView(
        children: <Widget>[
          Column(
            children: [
              Text('THIS IS THE MATCH CHAT PAGE'),
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
