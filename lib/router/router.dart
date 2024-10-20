import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/landingPage.dart';
import '../pages/UserInfo/qualifierIntCas.dart';
import '../pages/UserInfo/qualifierRelDate.dart';
import '../pages/UserInfo/verifyIdentity.dart';
import '../pages/Dashboard/dashboard.dart';
import '../pages/Expectations/mate_attributes.dart';
import '../pages/Expectations/logistics.dart';
import '../pages/Expectations/labor.dart';
import '../pages/Expectations/emotional.dart';
import '../pages/Expectations/status.dart';
import '../pages/Expectations/time_spent.dart';
import '../pages/Expectations/tone.dart';
import '../pages/Match/match_chat.dart';
import '../pages/Verifications/verifications.dart';
import '../pages/History/history.dart';
import '../user.dart';
import '../login.dart';
import '../register.dart';

class AppRoutes {
  static const String home = '/';
  static const String qualRelDate = '/qualifierRelDate';
  static const String qualIntCas = '/qualifierIntCas';
  static const String verID = '/verifyIdentity';
  static const String dashBoard = '/dashboard';
  static const String mateAttributes = '/mate_attributes';
  static const String logistics = '/logistics';
  static const String labor = '/labor';
  static const String emotional = '/emotional';  
  static const String status = '/status';
  static const String timeSpent = '/time_spent';
  static const String tone = '/tone';
  static const String matchChat = '/match_chat';
  static const String verifications= '/verifications';
  static const String history = '/history';
  static const String expectationsFlow = '/flow_expectations';
  static const String login = '/login';
  static const String register = '/register';
  
  static Route<dynamic> generateRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => _buildAuthWrapper(settings),
    );
  }

  static Widget _loggedInRoutes(String? routeName) {
    switch (routeName) {
      case matchChat:
        return MatchChat(title: 'Match Chat',);
      case verifications:
        return Verifications(title: 'Verifications',);
      case history:
        return History(title: 'History',);
      case dashBoard:
        return DashboardPage(title: 'Dashboard');
      default:
        throw FormatException("Route not found while LOGGED IN");
    }
  }

  static Widget _loggedOutRoutes(String? routeName) {
    switch (routeName) {
      case qualRelDate:
        return QualifierRelDate(title: 'Love Status',);
      case qualIntCas:
        return QualifierIntCas(title: 'Dating',);
      case verID:
        return VerifyIdentity(title: 'Verify Identity',);
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
        throw FormatException("Route not found while LOGGED OUT");
    }
  }

  static Widget _buildAuthWrapper(RouteSettings settings) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return _loggedInRoutes(settings.name);
        } else {
          return _loggedOutRoutes(settings.name);
        }
      },
    );
  }
}