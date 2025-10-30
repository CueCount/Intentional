class MiscService {

  int calculateAge(dynamic birthDateValue) {
    if (birthDateValue == null) return 0;
    
    DateTime birthDate;
    
    // Handle different input types
    if (birthDateValue is int) {
      // Convert milliseconds timestamp to DateTime
      birthDate = DateTime.fromMillisecondsSinceEpoch(birthDateValue);
    } else if (birthDateValue is String) {
      // Try to parse string as int first, then as DateTime string
      try {
        int timestamp = int.parse(birthDateValue);
        birthDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } catch (e) {
        try {
          birthDate = DateTime.parse(birthDateValue);
        } catch (e) {
          return 0; // Return 0 if parsing fails
        }
      }
    } else if (birthDateValue is DateTime) {
      birthDate = birthDateValue;
    } else {
      return 0; // Return 0 for unsupported types
    }
    
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    
    // Check if birthday hasn't occurred this year yet
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

}