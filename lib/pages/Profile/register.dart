import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../styles.dart';
import '../../providers/authState.dart';
import '../../providers/inputState.dart';
import '../../widgets/navigation.dart';
import '../../widgets/bottomNavigationBar.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  final AppAuthProvider _authProvider = AppAuthProvider();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Add listeners to trigger rebuilds when text changes
    _nameController.addListener(_onFormChanged);
    _emailController.addListener(_onFormChanged);
    _passwordController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    // Trigger rebuild to update button state
    setState(() {});
  }

  Future<void> _handleRegistration() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final inputProvider = Provider.of<InputState>(context, listen: false);

      // Save nameFirst and email to InputState BEFORE calling signUp
      await inputProvider.saveNeedLocally({
        'nameFirst': _nameController.text.trim(),
        'email': _emailController.text.trim(),
      });
      
      await authProvider.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        inputProvider,
      );

      /*if (mounted) {
        inputProvider.clearAllData();
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.subscription,
          (_) => false,
        );
      }*/

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getFirebaseErrorMessage(e.code);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Registration failed: ${e.toString()}';
        });
      }
    }
  }

  String _getFirebaseErrorMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is invalid.';
      default:
        return 'Registration failed. Please try again.';
    }
  }

  bool isFormComplete() {
    bool hasName = _nameController.text.trim().isNotEmpty;
    bool hasEmail = _emailController.text.trim().isNotEmpty;
    bool hasPassword = _passwordController.text.trim().isNotEmpty;
    
    bool isValidEmail = _emailController.text.trim().isNotEmpty && 
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
            .hasMatch(_emailController.text.trim());
    
    return hasName && hasEmail && hasPassword && isValidEmail;
  }

  @override
  void dispose() {
    // Remove listeners before disposing
    _nameController.removeListener(_onFormChanged);
    _emailController.removeListener(_onFormChanged);
    _passwordController.removeListener(_onFormChanged);
    
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isComplete = isFormComplete();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const CustomStatusBar(),
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

                    TextField(
                    controller: _nameController,
                    style: const TextStyle(color: ColorPalette.peach),
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      labelStyle: const TextStyle(color: ColorPalette.peach),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      suffixIcon: const Icon(Icons.mail, color: Colors.grey),
                    ),
                  ),
                    
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

                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    /*SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _isLoading ? null : _handleRegistration,
                        style: TextButton.styleFrom(
                          backgroundColor: ColorPalette.peach,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: _isLoading 
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Row(
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
                    ),*/

                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomAppBar(
        buttonText: _isLoading ? 'Registering...' : 'Register',
        buttonIcon: Icons.arrow_forward,
        isEnabled: !_isLoading && isComplete,
        onPressed: _handleRegistration,
      ),
    );
  }
}
