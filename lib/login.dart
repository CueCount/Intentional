import 'package:flutter/material.dart';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'controllers/auth0_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late Auth0 auth0;

  @override
  void initState() {
    super.initState();
    auth0 = Auth0(auth0Domain, clientId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await login();
          },
          child: const Text('Login'),
        ),
      ),
    );
  }

  Future<void> login() async {
    try {
      final credentials = await auth0.webAuthentication().login(
        redirectUrl: redirectUrl,
        scopes: {'openid', 'profile', 'email'},
      );
      print('Access Token: ${credentials.accessToken}');
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      print('Login failed: $e');
    }
  }
}