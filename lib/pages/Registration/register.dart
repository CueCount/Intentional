import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../router/router.dart';
import '../../widgets/input_text.dart';
import '../../controllers/firestore_service.dart'; // Add this import

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomTextInput(
              labelText: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              suffixIcon: const Icon(Icons.email),
            ),
            const SizedBox(height: 10),
            CustomTextInput(
              labelText: 'Password',
              controller: _passwordController,
              obscureText: true,
              suffixIcon: const Icon(Icons.lock),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await register();
              },
              child: const Text('Register'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(context); 
              },
              child: const Text('Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> register() async {
  final navigator = Navigator.of(context);
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  try {
    final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    
    if (userCredential.user != null) {
      await _firestoreService.associateWithAuthUser(userCredential.user!.uid);
      print('Associated temp document with auth user: ${userCredential.user!.uid}');
      
      if (mounted) {
        navigator.pushNamed(AppRoutes.basicInfo);
      }
    }
  } catch (e) {
    print('Registration failed: $e');
    if (mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Registration failed: $e')),
      );
    }
  }
}
}
