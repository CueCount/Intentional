import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/Chat/chat.dart';
import '../pages/Educational/landingPage.dart';
import '../pages/Matches/matches.dart';
import '../pages/Matches/match.dart';
import '../pages/Needs/qual.dart';
import '../pages/Needs/age.dart';
import '../pages/Needs/basic_info.dart';
import '../pages/Needs/photos.dart';
import '../pages/Needs/photoCrop.dart';
import '../pages/Needs/chemistry.dart';
import '../pages/Needs/physical.dart';
import '../pages/Needs/relationship.dart';
import '../pages/Needs/interests.dart';
import '../pages/Needs/goals.dart';
import '../pages/Needs/subscription.dart';
import '../pages/Profile/login.dart';
import '../pages/Profile/register.dart';
import '../pages/Profile/settings.dart';
import '../pages/Profile/editneeds.dart';
import '../pages/Profile/user.dart';

class AppRoutes {
  static const String home = '/';
  static const String qual = '/qual';
  static const String age = '/age';
  static const String match = '/match';
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
  static const String relationship = '/relationship';
  static const String physical = '/physical';
  static const String chemistry = '/chemistry';
  static const String interests = '/interests';
  static const String goals = '/lifeGoalNeeds';
  static const String subscription = '/subscription';
  static const String user = '/user';
  static const String editNeeds = '/editNeeds';
  static const String settings = '/settings';

  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final arguments = settings.arguments;
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => _buildAuthWrapper(settings, arguments),
    );
  }

  static Widget _loggedInRoutes(String? routeName, [dynamic arguments]) {
    if (routeName == register) {
      return const BasicProfilePage();
    }

    switch (routeName) {
      case qual:
        return const QualifierRelDate();
      case age:
        return const Age();
      case chemistry:
        return const Chemistry();
      case physical:
        return const Physical();
      case relationship:
        return const Relationship();
      case interests:
        return const Interests();
      case goals:
        return const Goals();
      case basicInfo:    
        return const BasicProfilePage();
      case chat:
        return const MatchChat();
      case matches:
        return const Matches();
      case match:
        return const Match();
      case photos:
        return const PhotoUploadPage();
      case photoCrop:
        return PhotoCropPage(imageFile: arguments['imageFile'],);
      case subscription:
        return const SubscriptionPage();
      case user:
        return const UserProfile();
      case editNeeds:
        return const EditNeeds();
      case settings:
        return const Settings();
      default:
        return const Matches();
    }
  }

  static Widget _loggedOutRoutes(String? routeName) {
    switch (routeName) {
      case qual:
        return const QualifierRelDate();
      case age:
        return const Age();
      case chemistry:
        return const Chemistry();
      case physical:
        return const Physical();
      case relationship:
        return const Relationship();
      case interests:
        return const Interests();
      case goals:
        return const Goals();
      case matches:
        return const Matches();
      case match:
        return const Match();
      case login:
        return const LoginPage();
      case register:
        return const RegisterPage();
      case subscription:
        return SubscriptionPage();
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
        final user = FirebaseAuth.instance.currentUser;
        print('Auth state: ${user != null ? 'Logged in as ${user.uid}' : 'Logged out'}');
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