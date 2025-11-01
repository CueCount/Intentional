import 'package:flutter/material.dart';
import '../pages/Chat/chat.dart';
import '../pages/Guides/landingPage.dart';
import '../pages/Matches/matches.dart';
import '../pages/Matches/match.dart';
import '../pages/Needs/qual.dart';
import '../pages/Needs/age.dart';
import '../pages/Needs/basics.dart';
import '../pages/Needs/photos.dart';
import '../pages/Needs/chemistry.dart';
import '../pages/Needs/relationship.dart';
import '../pages/Needs/interests.dart';
import '../pages/Needs/goals.dart';
import '../pages/Needs/subscription.dart';
import '../pages/Profile/login.dart';
import '../pages/Profile/register.dart';
import '../pages/Profile/settings.dart';
import '../pages/Profile/editneeds.dart';
import '../pages/Profile/requestsReceived.dart';
import '../pages/Profile/requestsSent.dart';
import '../pages/Guides/guideRequestSent.dart';
import '../pages/Guides/guideAvailableMatches.dart';
import '../pages/Guides/guideOnboardingNeeds.dart';
import '../pages/Needs/inputPage.dart';
import '../pages/loading.dart';

class AppRoutes {
  static const String home = '/';
  static const String qual = '/qual';
  static const String age = '/age';
  static const String basics = '/basics';
  static const String match = '/match';
  static const String tone = '/tone';
  static const String chat = '/chat';
  static const String verifications= '/verifications';
  static const String matches = '/discover';
  static const String login = '/login';
  static const String register = '/register';
  static const String basicInfo = '/basic_info';
  static const String photos = '/photos';
  static const String prompts = '/prompts';
  static const String relationship = '/relationship';
  static const String physical = '/physical';
  static const String chemistry = '/chemistry';
  static const String interests = '/interests';
  static const String goals = '/lifeGoalNeeds';
  static const String subscription = '/subscription';
  static const String userprofile = '/userprofile';
  static const String editNeeds = '/editNeeds';
  static const String settings = '/settings';
  static const String guideRequestSent = '/guideRequestSent';
  static const String guideOnboardingNeeds = '/guideOnboardingNeeds';
  static const String requestsSent = '/requestsSent';
  static const String requestsReceived = '/requestsReceived';
  static const String guideAvailableMatches = '/guideAvailableMatches';
  static const String input = '/input';
  static const String loading = '/loading';

  static Route<dynamic> generateRoute(RouteSettings settings, bool isLoggedIn) {
    final arguments = settings.arguments;
    
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => _buildRouteWidget(settings.name, arguments, isLoggedIn),
    );
  }

  static Widget _buildRouteWidget(String? routeName, dynamic arguments, bool isLoggedIn) {
    if (isLoggedIn) {
      return _loggedInRoutes(routeName, arguments);
    } else {
      return _loggedOutRoutes(routeName);
    }
  }

  static Widget _loggedInRoutes(String? routeName, [dynamic arguments]) {
    switch (routeName) {
      case qual:
        return const QualifierRelDate();
      case age:
        return const Age();
      case basics:
        return const Basics();
      case chemistry:
        return const Chemistry();
      case relationship:
        return const Relationship();
      case interests:
        return const Interests();
      case goals:
        return const Goals();
      case input:
        return PersonalityQ1(
          inputName: arguments['inputName'] ?? '',
          nextRoute: arguments['nextRoute'] ?? AppRoutes.matches,
        );
      case chat:
        if (arguments != null && arguments is Map<String, dynamic>) {
          return ChatScreen(
            matchId: arguments['matchId'] ?? '',
            otherUserName: arguments['otherUserName'] ?? 'User',
          );
        }
        return const Scaffold(
          body: Center(
            child: Text('Error: Chat information not provided'),
          ),
        );
      case matches:
        return const Matches();
      case match:
        return const Match();
      case requestsReceived:
        return const RequestReceived();
      case requestsSent:
        return const RequestSent();
      case photos:
        return const PhotoUploadPage();
      case subscription:
        return const SubscriptionPage();
      case editNeeds:
        return const EditNeeds();
      case settings:
        return const Settings();
      case guideRequestSent:
        return const GuideRequestSent();
      case loading:
        return const RefreshLoadingScreen();
      default:
        return const Matches();
    }
  }

  static Widget _loggedOutRoutes(String? routeName, [dynamic arguments]) {
    switch (routeName) {
      case qual:
        return const QualifierRelDate();
      case age:
        return const Age();
      case basics:
        return const Basics();
      case chemistry:
        return const Chemistry();
      case relationship:
        return const Relationship();
      case interests:
        return const Interests();
      case goals:
        return const Goals();
      case guideAvailableMatches:
        return const GuideAvailableMatches();
      case guideOnboardingNeeds:
        return GuideOnboardingNeeds();
      case photos:
        return const PhotoUploadPage();
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
      case guideRequestSent:
        return const GuideRequestSent();
      case home:
        return const MyHomePage(title: 'Landing Page',);
      default:
        return const MyHomePage(title: 'Landing Page',);
    }
  }
}