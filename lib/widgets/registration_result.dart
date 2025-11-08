// Add this to a new file: lib/models/registration_result.dart
// Or add to an existing models file

class RegistrationResult {
  final bool success;
  final String? errorMessage;
  final String? errorCode;
  
  RegistrationResult({
    required this.success,
    this.errorMessage,
    this.errorCode,
  });
  
  factory RegistrationResult.success() {
    return RegistrationResult(success: true);
  }
  
  factory RegistrationResult.failure({
    required String message,
    String? code,
  }) {
    return RegistrationResult(
      success: false,
      errorMessage: message,
      errorCode: code,
    );
  }
}
