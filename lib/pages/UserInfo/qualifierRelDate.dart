import 'package:flutter/material.dart';
import 'qualifierIntCas.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';

class QualifierRelDate extends StatefulWidget {
  const QualifierRelDate({super.key, required this.title});

  final String title;

  @override
  State<QualifierRelDate> createState() => _QualifierRelDate();
}

class _QualifierRelDate extends State<QualifierRelDate> {

  @override
  Widget build(BuildContext context) {
    
    void noOperation() {
      // This is an intentionally empty function that does nothing.
    }
    
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title,
        isLoggedIn: true,
        hasSubmittedForm: true,
      ),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QualifierIntCas(title: 'Dating',)),
                );
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