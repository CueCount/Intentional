import 'package:flutter/material.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '/router/router.dart';

class QualifierIntCas extends StatefulWidget {
  final String title;
  const QualifierIntCas({super.key, required this.title});
  @override
  State<QualifierIntCas> createState() => _QualifierIntCas();
}

class _QualifierIntCas extends State<QualifierIntCas> {

  @override
  Widget build(BuildContext context) {
    void noOperation() {}
    
    return Scaffold(
      appBar: CustomAppBar(route: AppRoutes.mateAttributes),
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
                Navigator.pushNamed(context, AppRoutes.mateAttributes);
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