import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/authState.dart';
import '../../providers/inputState.dart';
import '../../widgets/navigation.dart';
import '../../widgets/bottomNavigationBar.dart';
import '../../../../styles.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false; 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const CustomStatusBar(),
              Container (
                padding: const EdgeInsets.all(16), 
                child: Column(
                  children: [
                    Text(
                      'Login',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: ColorPalette.peach,
                      ),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: () {
        return CustomAppBar(
          buttonText: 'Login',
          buttonIcon: Icons.arrow_forward,
          onPressed: () async {
            final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
            final inputState = Provider.of<InputState>(context, listen: false);
            await authProvider.signIn(_emailController.text, _passwordController.text, inputState);
          },
        );
      }(),

    );
  }

}