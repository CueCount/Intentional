import 'package:flutter/material.dart';
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
  
  static Route<dynamic>? generateRoute(RouteSettings settings,) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => UserProvider.instance.isLoggedIn ? DashboardPage(title: 'dash',) : MyHomePage(title: 'Intentional',));
      case qualRelDate:
        return MaterialPageRoute(builder: (_) => QualifierRelDate(title: 'Love Status',));
      case qualIntCas:
        return MaterialPageRoute(builder: (_) => QualifierIntCas(title: 'Dating',));
      case verID:
        return MaterialPageRoute(builder: (_) => VerifyIdentity(title: 'Verify Identity',));
      case mateAttributes:
        return MaterialPageRoute(builder: (_) => MateAttributes(title: 'Mate Attributes',));
      case logistics:
        return MaterialPageRoute(builder: (_) => Logistics(title: 'Logistics',));
      case labor:
        return MaterialPageRoute(builder: (_) => Labor(title: 'Labor Dynamic',));
      case emotional:
        return MaterialPageRoute(builder: (_) => EmotionalDynamic(title: 'Emotional Dynamic',));
      case status:
        return MaterialPageRoute(builder: (_) => StatusDynamic(title: 'Status Dynamic',));
      case timeSpent:
        return MaterialPageRoute(builder: (_) => TimeSpent(title: 'Time Spent Together',));
      case tone:
        return MaterialPageRoute(builder: (_) => Tone(title: 'Relationship Tone',));

    }

    if (UserProvider.instance.isLoggedIn) {
      switch (settings.name) {
        case matchChat:
          return MaterialPageRoute(builder: (_) => MatchChat(title: 'Match Chat',));
        case verifications:
          return MaterialPageRoute(builder: (_) => Verifications(title: 'Verifications',));
        case history:
          return MaterialPageRoute(builder: (_) => History(title: 'History',));
        default:
          throw FormatException("Route not found while logged in");
      }
    } else {
      switch (settings.name) {
        default:
          throw FormatException("Route not found while logged out");
      }
    }
  }
}