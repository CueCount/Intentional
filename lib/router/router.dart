import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/landingPage.dart';
import '../pages/Qualifiers/location.dart';
import '../pages/Qualifiers/qual.dart';
import '../pages/Match/match.dart';
import '../pages/Expectations/mate_attributes.dart';
import '../pages/Expectations/logistics.dart';
import '../pages/Expectations/labor.dart';
import '../pages/Expectations/emotional.dart';
import '../pages/Expectations/status.dart';
import '../pages/Expectations/time_spent.dart';
import '../pages/Expectations/tone.dart';
import '../pages/Chat/chat.dart';
import '../pages/Profile/profile.dart';
import '../login.dart';
import '../pages/Registration/register.dart';
import '../pages/Registration/basic_info.dart';
import '../pages/Registration/photos.dart';
import '../pages/Registration/prompts.dart';

class AppRoutes {
  static const String home = '/';
  static const String qual = '/qual';
  static const String location = '/location';
  static const String match = '/match';
  static const String mateAttributes = '/mate_attributes';
  static const String logistics = '/logistics';
  static const String labor = '/labor';
  static const String emotional = '/emotional';  
  static const String status = '/status';
  static const String timeSpent = '/time_spent';
  static const String tone = '/tone';
  static const String chat = '/chat';
  static const String verifications= '/verifications';
  static const String profile = '/profile';
  static const String expectationsFlow = '/flow_expectations';
  static const String login = '/login';
  static const String register = '/register';
  static const String basicInfo = '/basic_info';
  static const String photos = '/photos';
  static const String prompts = '/prompts';
  
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
        return const DashboardPage(title: 'Match');
      case photos:
        return const PhotoUploadPage();
      case prompts:
        return const PromptsPage();
      default:
        return const DashboardPage(title: 'Match');
    }
  }

  static Widget _loggedOutRoutes(String? routeName) {
    switch (routeName) {
      case qual:
        return QualifierRelDate(title: 'Qualifiers',);
      case location:
        return QualifierIntCas(title: 'Location',);
      case mateAttributes:
        return MateAttributes(title: 'Mate Attributes',);
      case logistics:
        return Logistics(title: 'Logistics',);
      case labor:
        return Labor(title: 'Labor Dynamic',);
      case emotional:
        return EmotionalDynamic(title: 'Emotional Dynamic',);
      case status:
        return StatusDynamic(title: 'Status Dynamic',);
      case timeSpent:
        return TimeSpent(title: 'Time Spent Together',);
      case tone:
        return Tone(title: 'Relationship Tone',);
      case login:
        return LoginPage();
      case register:
        return RegisterPage();
      case home:
        return MyHomePage(title: 'Landing Page',);
      default:
        return MyHomePage(title: 'Landing Page',);
    }
  }

  static Widget _buildAuthWrapper(RouteSettings settings) {
    print('Current route requested: ${settings.name}');
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
            return DashboardPage(title: 'Match');
          }
        } else {
          return _loggedOutRoutes(settings.name);
        }
      },
    );
  }
}