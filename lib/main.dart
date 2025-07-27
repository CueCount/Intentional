import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'router/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'data/inputState.dart'; // Import the updated input state

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => InputState()),
        // Add more providers here as needed
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: AppRoutes.generateRoute,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Color.fromRGBO(255, 255, 255, 1),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}