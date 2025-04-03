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
      body: Container(
        width: double.infinity, // Ensures full width
        height: double.infinity,
        padding: const EdgeInsets.all(20), // 20px padding on all sides
        decoration: const BoxDecoration(
          gradient: ColorPalette.brandGradient,
        ),
    
      child: SafeArea(
        child: SingleChildScrollView(
            
            child: Column(
              children: [
                const CustomStatusBar(
                  messagesCount: 2,
                  likesCount: 5,
                ),
        
                
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Verify Yourself',
                        style: AppTextStyles.headingMedium.copyWith(
                          color: ColorPalette.white,
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity, child:
                        ElevatedButton(
                          onPressed: () async {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorPalette.white,  // Coral pink
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
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
                              Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(
                        width: double.infinity, 
                        child:

                        ElevatedButton(
                          onPressed: () async {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorPalette.white,  // Coral pink
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),

                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Verify Through Google',
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
                      ),
                      
                      const SizedBox(height: 10),
                      
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

                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5D5D),  // Coral pink
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),

                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Register',
                              style: TextStyle(
                                color: Colors.white,
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
                
              ],
            ),
        ),
      ),
      ),
      
    );
  }
}
