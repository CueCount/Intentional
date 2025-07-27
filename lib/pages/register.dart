import 'package:flutter/material.dart';
import '../router/router.dart';
import '../widgets/input_text.dart';
import '../styles.dart';
import '../functions/airTrafficControler_service.dart';
import '../widgets/navigation.dart';
import 'Needs/photos.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AirTrafficController _airTrafficController = AirTrafficController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
            child: Column(
              children: [
                const CustomStatusBar(messagesCount: 2,likesCount: 5,),
                Container (
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Verify Yourself',
                        style: AppTextStyles.headingLarge.copyWith(
                          color: ColorPalette.peach,
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity, child:
                        TextButton(
                          onPressed: () async {},
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: const BorderSide(
                                color: ColorPalette.peach,
                                width: 1,
                              ),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Verify Through Facebook',
                                style: TextStyle(
                                  color: ColorPalette.peach,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward, color: ColorPalette.peach, size: 20),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: ColorPalette.peach),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: const TextStyle(color: ColorPalette.peach),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: ColorPalette.peach,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: ColorPalette.peach,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: ColorPalette.peach,
                              width: 1,
                            ),
                          ),
                          suffixIcon: const Icon(Icons.email, color: ColorPalette.peach),
                        ),
                      ),

                      const SizedBox(height: 10),

                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        style: const TextStyle(color: ColorPalette.peach),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(color: ColorPalette.peach),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: ColorPalette.peach,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: ColorPalette.peach,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: const BorderSide(
                              color: ColorPalette.peach,
                              width: 1,
                            ),
                          ),
                          suffixIcon: const Icon(Icons.lock, color: ColorPalette.peach),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextButton(
                        onPressed: () async {                          
                          try {
                            await _airTrafficController.registerUser(
                              context,
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );
                            
                          } catch (e) {
                            if (context.mounted) {
                              print('Error in onPressed: $e');
                            }
                          }

                        },

                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: const BorderSide(
                              color: ColorPalette.peach,
                              width: 1,
                            ),
                          ),
                        ),

                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Register',
                              style: TextStyle(
                                color: ColorPalette.peach,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ),
      ),
    );
  }
}
