import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'pages/landingPage.dart';
import 'router/router.dart';
import 'user.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // ROOT WIDGET of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: AppRoutes.generateRoute,      
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromRGBO(183, 58, 85, 1)),
        useMaterial3: true,
        scaffoldBackgroundColor: Color(0xFFFEF8E8),
      ),
      debugShowCheckedModeBanner: false,  // Add this line
    );
  }
}


