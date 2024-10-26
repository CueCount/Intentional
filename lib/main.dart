import 'package:flutter/material.dart';
import 'router/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: AppRoutes.generateRoute,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Color.fromRGBO(250, 235, 235, 0),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}