import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/landingPage.dart';
import '../pages/Qualifiers/location.dart';
import '../pages/Qualifiers/qual.dart';
import '../pages/Match/match.dart';
import '../pages/Chat/chat.dart';
import '../pages/Profile/profile.dart';
import '../login.dart';
import '../pages/Registration/register.dart';
import '../pages/Registration/basic_info.dart';
import '../pages/Registration/photos.dart';
import '../pages/Registration/prompts.dart';
import '../pages/Needs/emotionalNeeds.dart';
import '../pages/Needs/physicalNeeds.dart';
import '../pages/Needs/chemistryNeeds.dart';
import '../pages/Needs/logisticNeeds.dart';
import '../pages/Needs/lifeGoalNeeds.dart';

class AppRoutes {
  static const String home = '/';
  static const String qual = '/qual';
  static const String location = '/location';
  static const String match = '/match';
  static const String tone = '/tone';
  static const String chat = '/chat';
  static const String verifications= '/verifications';
  static const String profile = '/profile';
  static const String login = '/login';
  static const String register = '/register';
  static const String basicInfo = '/basic_info';
  static const String photos = '/photos';
  static const String prompts = '/prompts';
  static const String emotionalNeeds = '/emotionalNeeds';
  static const String physicalNeeds = '/physicalNeeds';
  static const String chemistryNeeds = '/chemistryNeeds';
  static const String logisticNeeds = '/logisticNeeds';
  static const String lifeGoalNeeds = '/lifeGoalNeeds';

  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => _buildAuthWrapper(settings),
    );
  }

  static Widget _loggedInRoutes(String? routeName) {
    switch (routeName) {
      case basicInfo:    
        return const BasicProfilePage();
      case chat:
        return const MatchChat(title: 'Chat',);
      case profile:
        return const History(title: 'Profile',);
      case match:
        return const Matches(title: 'Match');
      case photos:
        return const PhotoUploadPage();
      case prompts:
        return const PromptsPage();
      default:
        return const Matches(title: 'Match');
    }
  }

  static Widget _loggedOutRoutes(String? routeName) {
    switch (routeName) {
      case qual:
        return const QualifierRelDate(title: 'Qualifiers',);
      case location:
        return const QualifierIntCas(title: 'Location',);
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

  static Widget _buildAuthWrapper(RouteSettings settings) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('Auth state: ${snapshot.hasData ? 'Logged in' : 'Logged out'}');
        // Handle loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Handle auth state
        if (snapshot.hasData) {
          // Check if this is a new registration
          if (settings.name == AppRoutes.register || settings.name == AppRoutes.basicInfo) {
            return _loggedInRoutes(AppRoutes.basicInfo);
          }
          // Normal logged in navigation
          try {
            return _loggedInRoutes(settings.name);
          } catch (e) {
            // Only default to match if not in registration flow
            return const Matches(title: 'Match');
          }
        } else {
          return _loggedOutRoutes(settings.name);
        }
      },
    );
  }
}