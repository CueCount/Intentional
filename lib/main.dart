import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'widgets/error.dart';
import 'router/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/inputState.dart';
import 'providers/matchState.dart';
import 'providers/userState.dart';
import 'providers/authState.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return GlobalErrorScreen(details: details);
  };

  runApp(const AppRoot()); 
}

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppAuthProvider>(
          create: (_) {
            return AppAuthProvider()..init();
          },
        ),

        ChangeNotifierProxyProvider<AppAuthProvider, InputState>(
          create: (_) {
            return InputState();
          },
          update: (_, auth, input) {
            input ??= InputState();
            final uid = auth.userId;
           
            if (uid != null) {
              try {
                input.setCurrentSessionId(uid);
              } catch (_) {
                input.clearCurrentSessionId();
              }
            }
            return input;
          },
        ),

        ChangeNotifierProxyProvider<AppAuthProvider, UserSyncProvider>(
          create: (_) {
            return UserSyncProvider();
          },
          update: (_, auth, user) {
            user ??= UserSyncProvider();
            final uid = auth.userId;

            try {
              if (uid != null) {
                user.setCurrentUserId(uid);
              } else {
              }
            } catch (_) {}
            return user;
          },
        ),

        ChangeNotifierProxyProvider<AppAuthProvider, MatchSyncProvider>(
          create: (_) => MatchSyncProvider(),
          update: (_, auth, match) {
            match ??= MatchSyncProvider();
            final uid = auth.userId;
            
            try {
              if (uid != null) {
                match.startListening(uid);
              } else {
                match.stopListening();
              }
            } catch (_) {}
            return match;
          },
        ),
      ],

      child: const MyApp(), 
    );
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppAuthProvider>(
      builder: (_, auth, __) {
        if (auth.isLoading || !auth.isInitialized) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        return Consumer<AppAuthProvider>(
          builder: (_, auth, __) {
            return MaterialApp(
              onGenerateRoute: (settings) => AppRoutes.generateRoute(settings, auth.isLoggedIn),
              theme: ThemeData(
                useMaterial3: true,
                scaffoldBackgroundColor: const Color.fromRGBO(255, 255, 255, 1.0),
              ),
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: child,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
