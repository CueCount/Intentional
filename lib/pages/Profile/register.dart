import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../styles.dart';
import '../../providers/authState.dart';
import '../../providers/inputState.dart';
import '../../widgets/navigation.dart';
import '../../widgets/bottomNavigationBar.dart';
import '../../router/router.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;
  bool _registrationInProgress = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onFormChanged);
    _emailController.addListener(_onFormChanged);
    _passwordController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    setState(() {});
  }

  Future<void> _handleRegistration() async {
    // Prevent double-tap
    if (_registrationInProgress) {
      if (kDebugMode) {
        print('⚠️ Registration already in progress, ignoring tap');
      }
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _registrationInProgress = true;
    });

    if (kDebugMode) {
      print('🚀 Starting registration process...');
    }

    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final inputProvider = Provider.of<InputState>(context, listen: false);

      // Validate inputs
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (name.isEmpty || email.isEmpty || password.isEmpty) {
        _showErrorSnackBar('Please fill in all fields');
        setState(() {
          _isLoading = false;
          _registrationInProgress = false;
        });
        return;
      }

      if (!_isValidEmail(email)) {
        _showErrorSnackBar('Please enter a valid email address');
        setState(() {
          _isLoading = false;
          _registrationInProgress = false;
        });
        return;
      }

      if (password.length < 6) {
        _showErrorSnackBar('Password must be at least 6 characters');
        setState(() {
          _isLoading = false;
          _registrationInProgress = false;
        });
        return;
      }

      if (kDebugMode) {
        print('📝 Saving name and email to InputState...');
      }

      // Save nameFirst and email to InputState BEFORE calling signUp
      await inputProvider.inputsSaveOnboarding({
        'nameFirst': name,
        'email': email,
      });

      if (kDebugMode) {
        print('🔐 Calling authProvider.signUp...');
      }
      
      // Call signUp and get result
      final result = await authProvider.signUp(
        email,
        password,
        inputProvider,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _registrationInProgress = false;
      });

      // Handle result
      if (result.success) {
        if (kDebugMode) {
          print('✅ Registration successful! Navigating...');
        }
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Account created successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Wait a moment for the success message to show
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        // Navigate to next screen
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.matches, // Change this to your desired route
          (_) => false,
        );
      } else {
        // Registration failed - show error and STAY on page
        if (kDebugMode) {
          print('❌ Registration failed: ${result.errorMessage}');
          print('❌ Error code: ${result.errorCode}');
        }

        _showErrorSnackBar(result.errorMessage ?? 'Registration failed');
      }

    } catch (e) {
      // This shouldn't happen anymore since signUp returns Result
      // But just in case...
      if (kDebugMode) {
        print('❌ Unexpected error in _handleRegistration: $e');
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _registrationInProgress = false;
        });
        
        _showErrorSnackBar('An unexpected error occurred. Please try again.');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool isFormComplete() {
    bool hasName = _nameController.text.trim().isNotEmpty;
    bool hasEmail = _emailController.text.trim().isNotEmpty;
    bool hasPassword = _passwordController.text.trim().isNotEmpty;
    
    bool isValidEmail = hasEmail && _isValidEmail(_emailController.text.trim());
    
    return hasName && isValidEmail && hasPassword && _passwordController.text.trim().length >= 6;
  }

  @override
  void dispose() {
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
              Container(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Verify Yourself',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: ColorPalette.peach,
                      ),
                    ),
                    
                    const SizedBox(height: 16),

                    TextField(
                      controller: _nameController,
                      enabled: !_isLoading,
                      style: const TextStyle(color: ColorPalette.peach),
                      decoration: InputDecoration(
                        labelText: 'First Name',
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
                            width: 2,
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: ColorPalette.peach.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        suffixIcon: const Icon(Icons.person, color: ColorPalette.peach),
                      ),
                    ),

                    const SizedBox(height: 10),
                    
                    TextField(
                      controller: _emailController,
                      enabled: !_isLoading,
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
                            width: 2,
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: ColorPalette.peach.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        suffixIcon: const Icon(Icons.email, color: ColorPalette.peach),
                      ),
                    ),

                    const SizedBox(height: 10),

                    TextField(
                      controller: _passwordController,
                      enabled: !_isLoading,
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
                            width: 2,
                          ),
                        ),
                        disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(
                            color: ColorPalette.peach.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        suffixIcon: const Icon(Icons.lock, color: ColorPalette.peach),
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (_isLoading)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: ColorPalette.peach.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Column(
                          children: [
                            CircularProgressIndicator(
                              color: ColorPalette.peach,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Creating your account...',
                              style: TextStyle(
                                color: ColorPalette.peach,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'This may take a few seconds',
                              style: TextStyle(
                                color: ColorPalette.peach,
                                fontSize: 12,
                              ),
                            ),
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
      bottomNavigationBar: CustomAppBar(
        buttonText: _isLoading ? 'Creating Account...' : 'Register',
        buttonIcon: Icons.arrow_forward,
        isEnabled: !_isLoading && isComplete,
        onPressed: _isLoading ? null : () => _handleRegistration(),
      ),
    );
  }
}