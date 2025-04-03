import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/landingPage.dart';
import '../pages/Needs/qual.dart';
import '../pages/Discover/discover.dart';
import '../pages/Chat/chat.dart';
import '../pages/Profile/profile.dart';
import '../pages/login.dart';
import '../pages/register.dart';
import '../pages/Needs/basic_info.dart';
import '../pages/Needs/photos.dart';
import '../pages/Needs/photoCrop.dart';
import '../pages/Needs/emotionalNeeds.dart';
import '../pages/Needs/physicalNeeds.dart';
import '../pages/Needs/chemistryNeeds.dart';
import '../pages/Needs/logisticNeeds.dart';
import '../pages/Needs/lifeGoalNeeds.dart';

class AppRoutes {
  static const String home = '/';
  static const String qual = '/qual';
  static const String profile = '/profile';
  static const String tone = '/tone';
  static const String chat = '/chat';
  static const String verifications= '/verifications';
  static const String matches = '/discover';
  static const String login = '/login';
  static const String register = '/register';
  static const String basicInfo = '/basic_info';
  static const String photos = '/photos';
  static const String photoCrop = '/photoCrop';
  static const String prompts = '/prompts';
  static const String emotionalNeeds = '/emotionalNeeds';
  static const String physicalNeeds = '/physicalNeeds';
  static const String chemistryNeeds = '/chemistryNeeds';
  static const String logisticNeeds = '/logisticNeeds';
  static const String lifeGoalNeeds = '/lifeGoalNeeds';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final arguments = settings.arguments;
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => _buildAuthWrapper(settings, arguments),
    );
  }

  static Widget _loggedInRoutes(String? routeName, [dynamic arguments]) {
    switch (routeName) {
      case basicInfo:    
        return const BasicProfilePage();
      case chat:
        return const MatchChat();
      case matches:
        return const Matches();
      case profile:
        return const Match();
      case photos:
        return const PhotoUploadPage();
      case photoCrop:
        return PhotoCropPage(imageFile: arguments['imageFile'],);
      default:
        return const Matches();
    }
  }

  static Widget _loggedOutRoutes(String? routeName) {
    switch (routeName) {
      case qual:
        return const QualifierRelDate();
      case emotionalNeeds:
        return const EmotionalNeeds(title: 'EmotionalNeeds',);
      case physicalNeeds:
        return const PhysicalNeeds(title: 'PhysicalNeeds',);
      case chemistryNeeds:
        return const ChemistryNeeds(title: 'ChemistryNeeds',);
      case logisticNeeds:
        return const LogisticNeeds(title: 'LogisticNeeds',);
      case lifeGoalNeeds:
        return const LifeGoalNeeds(title: 'LogisticNeeds',);
      case matches:
        return const Matches();
      case profile:
        return const Match();
      case login:
        return const LoginPage();
      case register:
        return const RegisterPage();
      case home:
        return const MyHomePage(title: 'Landing Page',);
      default:
        return const MyHomePage(title: 'Landing Page',);
    }
  }

  static Widget _buildAuthWrapper(RouteSettings settings, [dynamic arguments]) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('Auth state: ${snapshot.hasData ? 'Logged in' : 'Logged out'}');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasData) {
          try {
            return _loggedInRoutes(settings.name, arguments);
          } catch (e) {
            return const Matches();
          }
        } else {
          return _loggedOutRoutes(settings.name);
        }
      },
    );
  }
}