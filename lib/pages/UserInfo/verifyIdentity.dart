import 'package:flutter/material.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';

class VerifyIdentity extends StatefulWidget {
  const VerifyIdentity({super.key, required this.title});

  final String title;

  @override
  State<VerifyIdentity> createState() => _VerifyIdentity();
}

class _VerifyIdentity extends State<VerifyIdentity> {

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
              'Please Verify Your Identity'
            ),
            MaterialButton(
              onPressed: noOperation,
              child: const Text('Connect Facebook'),
              color: Colors.blue,
            ),
            MaterialButton(
              onPressed: noOperation,
              child: const Text('Connect Instagram'),
              color: Colors.blue,
            ),
          ],
          
        ),
      ),
      
    );
  }
}