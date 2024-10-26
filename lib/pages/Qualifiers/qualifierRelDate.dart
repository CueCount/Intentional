import 'package:flutter/material.dart';
import 'qualifierIntCas.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '/router/router.dart';

class QualifierRelDate extends StatefulWidget {
  const QualifierRelDate({super.key, required this.title});
  final String title;
  @override
  State<QualifierRelDate> createState() => _QualifierRelDate();
}

class _QualifierRelDate extends State<QualifierRelDate> {

  @override
  Widget build(BuildContext context) {
    void noOperation() {}
    
    return Scaffold(
      appBar: CustomAppBar(route: AppRoutes.qualIntCas),
      endDrawer: CustomDrawer(), 
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'What\'s Your Love Status?'
            ),
            MaterialButton(
              onPressed: () {

              },
              child: const Text('Looking to Date'),
              color: Colors.blue,
            ),
            MaterialButton(
              onPressed: noOperation,
              child: const Text('In a Relationship'),
              color: Colors.blue,
            ),
          ],
          
        ),
      ),
      
    );
  }
}