import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../styles.dart';
import '../../providers/authState.dart';
import '../../providers/inputState.dart';
import '../../widgets/navigation.dart';
import '../../widgets/bottomNavigationBar.dart';
import '/router/router.dart';

class RegisterInfo extends StatefulWidget {
  const RegisterInfo({Key? key}) : super(key: key);
  @override
  State<RegisterInfo> createState() => _RegisterInfoState();
}

class _RegisterInfoState extends State<RegisterInfo> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isLoading = false;
  bool _isLoadingData = true;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadExistingValues();
    // Add listeners to trigger rebuilds when text changes
    _nameController.addListener(_onFormChanged);
    _emailController.addListener(_onFormChanged);
  }

  Future<void> _loadExistingValues() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final inputState = Provider.of<InputState>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      
      // Get existing values from InputState/SharedPreferences
      final existingName = await inputState.fetchInputFromLocal('nameFirst');
      final existingEmail = await inputState.fetchInputFromLocal('email');
      
      // Set the text controllers with existing values
      if (existingName != null && existingName is String) {
        _nameController.text = existingName;
      }
      
      // Use email from Firebase Auth if available, otherwise from saved data
      if (user != null && user.email != null) {
        _emailController.text = user.email!;
      } else if (existingEmail != null && existingEmail is String) {
        _emailController.text = existingEmail;
      }
      
    } catch (e) {
      print('RegisterInfo: Error loading existing values - $e');
      setState(() {
        _errorMessage = 'Error loading your information';
      });
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
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

  Future<void> _handleSave() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _isLoading = true;
    });

    try {
      final inputState = Provider.of<InputState>(context, listen: false);
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      
      String newEmail = _emailController.text.trim();
      String newName = _nameController.text.trim();
      
      // Save name to InputState
      await inputState.saveInputToRemoteThenLocal({
        'nameFirst': newName,
        'email': newEmail,
      });
      
      // If user is logged in and email has changed, update in Firebase
      if (user != null && user.email != newEmail) {
        try {
          await user.verifyBeforeUpdateEmail(newEmail);
          await user.reload();
        } catch (e) {
          // If email update fails, show specific error
          if (e.toString().contains('requires-recent-login')) {
            setState(() {
              _errorMessage = 'Please log in again to update your email address';
            });
            return;
          }
          throw e;
        }
      }
      
      setState(() {
        _successMessage = 'Your information has been updated successfully';
        _isLoading = false;
      });
      
      // Navigate back after a short delay to show success message
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to update information: ${e.toString()}';
        });
      }
    }
  }

  bool isFormComplete() {
    bool hasName = _nameController.text.trim().isNotEmpty;
    bool hasEmail = _emailController.text.trim().isNotEmpty;
    
    bool isValidEmail = _emailController.text.trim().isNotEmpty && 
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
            .hasMatch(_emailController.text.trim());
    
    return hasName && hasEmail && isValidEmail;
  }

  bool hasChanges() {
    // Check if values have changed from initial load
    // This would require storing initial values, simplified for now
    return true;
  }

  @override
  void dispose() {
    // Remove listeners before disposing
    _nameController.removeListener(_onFormChanged);
    _emailController.removeListener(_onFormChanged);
    
    _emailController.dispose();
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
              
              if (_isLoadingData)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(50),
                    child: CircularProgressIndicator(
                      color: ColorPalette.peach,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Account Information',
                        style: AppTextStyles.headingLarge.copyWith(
                          color: ColorPalette.peach,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        'Update your personal information',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // First Name Field
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'First Name',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: ColorPalette.peach,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(color: ColorPalette.peach),
                            decoration: InputDecoration(
                              hintText: 'Enter your first name',
                              hintStyle: TextStyle(color: Colors.grey[400]),
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
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
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
                              prefixIcon: const Icon(Icons.person_outline, color: ColorPalette.peach),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Email Field
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
                              hintText: 'Enter your email',
                              hintStyle: TextStyle(color: Colors.grey[400]),
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
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
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
                              prefixIcon: const Icon(Icons.email_outlined, color: ColorPalette.peach),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // Password Reset Link
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: ColorPalette.peachLite),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          leading: const Icon(
                            Icons.lock_reset,
                            color: ColorPalette.peach,
                          ),
                          title: Text(
                            'Reset Password',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: ColorPalette.peach,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            'Change your account password',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: ColorPalette.peach,
                            size: 16,
                          ),
                          onTap: () {
                            // Navigate to reset password page
                            Navigator.pushNamed(context, AppRoutes.resetPassword);
                          },
                        ),
                      ),
                      
                      // Error Message
                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
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
                          margin: const EdgeInsets.only(top: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
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
                      
                      const SizedBox(height: 20),
                      
                      // Additional Information
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Changes to your email address may require you to sign in again.',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontSize: 13,
                                ),
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
      
      bottomNavigationBar: _isLoadingData 
        ? null 
        : CustomAppBar(
            buttonText: _isLoading ? 'Saving...' : 'Save Changes',
            buttonIcon: Icons.save,
            isEnabled: !_isLoading && isComplete,
            onPressed: _handleSave,
          ),
    );
  }
}