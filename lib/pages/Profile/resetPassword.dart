import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../styles.dart';
import '../../widgets/navigation.dart';
import '../../widgets/bottomNavigationBar.dart';
import '/router/router.dart';

/// ResetPassword Page
/// 
/// This page handles two distinct password reset scenarios:
/// 
/// 1. LOGGED-IN USERS (Direct Password Change):
///    - User must enter current password for security
///    - Uses Firebase's updatePassword() after re-authentication
///    - Immediately changes password without email verification
/// 
/// 2. LOGGED-OUT USERS (Email Reset Flow):
///    - Uses Firebase's built-in sendPasswordResetEmail() method
///    - Firebase automatically:
///      * Sends a branded email with secure reset link
///      * Handles token generation and expiration
///      * Provides a web page for users to enter new password
///      * Completes the password reset securely
///    - User receives email → clicks link → enters new password on Firebase's page
///    - No additional code needed - Firebase handles everything!

class ResetPassword extends StatefulWidget {
  const ResetPassword({Key? key}) : super(key: key);
  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  
  User? _currentUser;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    
    // Add listeners to trigger rebuilds when text changes
    _currentPasswordController.addListener(_onFormChanged);
    _newPasswordController.addListener(_onFormChanged);
    _confirmPasswordController.addListener(_onFormChanged);
    _emailController.addListener(_onFormChanged);
  }

  void _checkAuthState() {
    _currentUser = FirebaseAuth.instance.currentUser;
    _isLoggedIn = _currentUser != null;
    
    // Pre-fill email if user is logged in
    if (_isLoggedIn && _currentUser!.email != null) {
      _emailController.text = _currentUser!.email!;
    }
    
    setState(() {});
  }

  void _onFormChanged() {
    // Clear messages when user starts typing
    if (_errorMessage != null || _successMessage != null) {
      setState(() {
        _errorMessage = null;
        _successMessage = null;
      });
    }
    // Trigger rebuild to update button state
    setState(() {});
  }

  Future<void> _handlePasswordReset() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _isLoading = true;
    });

    try {
      if (_isLoggedIn) {
        // For logged-in users: Change password
        await _changePasswordForLoggedInUser();
      } else {
        // For logged-out users: Send password reset email
        await _sendPasswordResetEmail();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getFirebaseErrorMessage(e.toString());
        });
      }
    }
  }

  Future<void> _changePasswordForLoggedInUser() async {
    try {
      // Validate passwords match
      if (_newPasswordController.text != _confirmPasswordController.text) {
        throw Exception('Passwords do not match');
      }

      // Validate password strength
      if (_newPasswordController.text.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: _currentUser!.email!,
        password: _currentPasswordController.text,
      );

      await _currentUser!.reauthenticateWithCredential(credential);

      // Update password
      await _currentUser!.updatePassword(_newPasswordController.text);

      setState(() {
        _successMessage = 'Password updated successfully!';
        _isLoading = false;
      });

      // Navigate to settings after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.settings,
            (route) => false,
          );
        }
      });

    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseErrorMessage(e.code));
    }
  }

  Future<void> _sendPasswordResetEmail() async {
    try {
      // Validate email
      if (_emailController.text.trim().isEmpty) {
        throw Exception('Please enter your email address');
      }

      // Send password reset email using Firebase's built-in method
      // This automatically:
      // 1. Generates a secure, time-limited reset token
      // 2. Sends a professionally formatted email (customizable in Firebase Console)
      // 3. Provides a secure web page for password reset
      // 4. Handles all security and validation
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
        // Optional: You can customize the email in Firebase Console under
        // Authentication > Templates > Password Reset
      );

      setState(() {
        _successMessage = 'Password reset email sent! Check your inbox and follow the link to reset your password.';
        _isLoading = false;
      });

      // Navigate to login after a short delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false,
          );
        }
      });

    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseErrorMessage(e.code));
    }
  }

  String _getFirebaseErrorMessage(String code) {
    if (code.contains('user-not-found')) {
      return 'No account found with this email address.';
    } else if (code.contains('invalid-email')) {
      return 'The email address is invalid.';
    } else if (code.contains('wrong-password')) {
      return 'Current password is incorrect.';
    } else if (code.contains('weak-password')) {
      return 'The new password is too weak. Use at least 6 characters.';
    } else if (code.contains('requires-recent-login')) {
      return 'Please log out and log in again before changing your password.';
    } else if (code.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    } else if (code.contains('network-request-failed')) {
      return 'Network error. Please check your connection.';
    } else if (code.contains('Passwords do not match')) {
      return 'The passwords you entered do not match.';
    } else if (code.contains('Password must be')) {
      return code;
    }
    return 'An error occurred. Please try again.';
  }

  bool isFormComplete() {
    if (_isLoggedIn) {
      // For logged-in users, need all password fields
      bool hasCurrentPassword = _currentPasswordController.text.isNotEmpty;
      bool hasNewPassword = _newPasswordController.text.isNotEmpty;
      bool hasConfirmPassword = _confirmPasswordController.text.isNotEmpty;
      bool passwordsMatch = _newPasswordController.text == _confirmPasswordController.text;
      
      return hasCurrentPassword && hasNewPassword && hasConfirmPassword && passwordsMatch;
    } else {
      // For logged-out users, only need email
      bool hasEmail = _emailController.text.trim().isNotEmpty;
      bool isValidEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
          .hasMatch(_emailController.text.trim());
      
      return hasEmail && isValidEmail;
    }
  }

  @override
  void dispose() {
    _currentPasswordController.removeListener(_onFormChanged);
    _newPasswordController.removeListener(_onFormChanged);
    _confirmPasswordController.removeListener(_onFormChanged);
    _emailController.removeListener(_onFormChanged);
    
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
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
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      _isLoggedIn ? 'Change Password' : 'Reset Password',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: ColorPalette.peach,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      _isLoggedIn 
                        ? 'Enter your current password and choose a new one'
                        : 'Enter your email to receive a password reset link',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Show different fields based on auth state
                    if (_isLoggedIn) ...[
                      // Current Password Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Password',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: ColorPalette.peach,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _currentPasswordController,
                            obscureText: _obscureCurrentPassword,
                            style: const TextStyle(color: ColorPalette.peach),
                            decoration: InputDecoration(
                              hintText: 'Enter current password',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: ColorPalette.peach,
                                  width: 2,
                                ),
                              ),
                              prefixIcon: const Icon(Icons.lock_outline, color: ColorPalette.peach),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureCurrentPassword = !_obscureCurrentPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // New Password Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New Password',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: ColorPalette.peach,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _newPasswordController,
                            obscureText: _obscureNewPassword,
                            style: const TextStyle(color: ColorPalette.peach),
                            decoration: InputDecoration(
                              hintText: 'Enter new password (min. 6 characters)',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: ColorPalette.peach,
                                  width: 2,
                                ),
                              ),
                              prefixIcon: const Icon(Icons.lock_outline, color: ColorPalette.peach),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureNewPassword = !_obscureNewPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Confirm Password Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Confirm New Password',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: ColorPalette.peach,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            style: const TextStyle(color: ColorPalette.peach),
                            decoration: InputDecoration(
                              hintText: 'Re-enter new password',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: ColorPalette.peach,
                                  width: 2,
                                ),
                              ),
                              prefixIcon: const Icon(Icons.lock_outline, color: ColorPalette.peach),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Password match indicator
                      if (_newPasswordController.text.isNotEmpty && 
                          _confirmPasswordController.text.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Icon(
                                _newPasswordController.text == _confirmPasswordController.text
                                    ? Icons.check_circle
                                    : Icons.error,
                                color: _newPasswordController.text == _confirmPasswordController.text
                                    ? Colors.green
                                    : Colors.red,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _newPasswordController.text == _confirmPasswordController.text
                                    ? 'Passwords match'
                                    : 'Passwords do not match',
                                style: TextStyle(
                                  color: _newPasswordController.text == _confirmPasswordController.text
                                      ? Colors.green
                                      : Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                    ] else ...[
                      // Email Field for password reset
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email Address',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: ColorPalette.peach,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: ColorPalette.peach),
                            decoration: InputDecoration(
                              hintText: 'Enter your email address',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: const BorderSide(
                                  color: ColorPalette.peach,
                                  width: 2,
                                ),
                              ),
                              prefixIcon: const Icon(Icons.email_outlined, color: ColorPalette.peach),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Info box for logged-out users
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'How it works:',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '1. We\'ll send you a secure reset link via email\n'
                                    '2. Click the link in your email\n'
                                    '3. Enter your new password on the secure page\n'
                                    '4. Your password will be instantly updated',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 30),
                    
                    // Error Message
                    if (_errorMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Success Message
                    if (_successMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline, color: Colors.green.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _successMessage!,
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Password requirements info
                    if (_isLoggedIn)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Password Requirements:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  _newPasswordController.text.length >= 6 
                                      ? Icons.check_circle 
                                      : Icons.circle_outlined,
                                  size: 16,
                                  color: _newPasswordController.text.length >= 6 
                                      ? Colors.green 
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'At least 6 characters',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  (_newPasswordController.text.isNotEmpty && 
                                   _confirmPasswordController.text.isNotEmpty &&
                                   _newPasswordController.text == _confirmPasswordController.text)
                                      ? Icons.check_circle 
                                      : Icons.circle_outlined,
                                  size: 16,
                                  color: (_newPasswordController.text.isNotEmpty && 
                                         _confirmPasswordController.text.isNotEmpty &&
                                         _newPasswordController.text == _confirmPasswordController.text)
                                      ? Colors.green 
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Passwords must match',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
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
        buttonText: _isLoading 
            ? 'Processing...' 
            : (_isLoggedIn ? 'Update Password' : 'Send Reset Email'),
        buttonIcon: _isLoggedIn ? Icons.lock_reset : Icons.email,
        isEnabled: !_isLoading && isComplete,
        onPressed: _handlePasswordReset,
      ),
    );
  }
}