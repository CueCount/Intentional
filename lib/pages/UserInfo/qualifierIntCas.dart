import 'package:flutter/material.dart';
import 'verifyIdentity.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';

class QualifierIntCas extends StatefulWidget {
  final String title;
  const QualifierIntCas({super.key, required this.title});

  @override
  State<QualifierIntCas> createState() => _QualifierIntCas();
}

class _QualifierIntCas extends State<QualifierIntCas> {

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
              'What kind of dating are you looking to do?'
            ),
            MaterialButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VerifyIdentity(title: 'Verify Identity',)),
                );
              },
              child: const Text('Intentionally'),
              color: Colors.blue,
            ),
            MaterialButton(
              onPressed: noOperation,
              child: const Text('Casually'),
              color: Colors.blue,
            ),
          ],
          
        ),
      ),
      
    );
  }
}