import 'dart:io';
import 'dart:convert';

void main(List<String> arguments) async {
  // Parse arguments
  String? uid;
  bool checkQual = false;
  
  for (int i = 0; i < arguments.length; i++) {
    if ((arguments[i] == '--uid' || arguments[i] == '-u') && i + 1 < arguments.length) {
      uid = arguments[i + 1];
      i++;
    } else if (arguments[i] == '--check-qual') {
      checkQual = true;
    } else if (arguments[i] == '--help' || arguments[i] == '-h') {
      printHelp();
      exit(0);
    }
  }
  
  // Find and read the SharedPreferences file directly
  final prefsData = await readPreferencesFile();
  
  if (prefsData == null) {
    print('❌ Could not read SharedPreferences.');
    print('Make sure the app has run at least once.\n');
    print('Try running: flutter run');
    exit(1);
  }
  
  if (checkQual) {
    checkQualData(prefsData, uid);
  } else {
    dumpAll(prefsData, uid);
  }
}

Future<Map<String, dynamic>?> readPreferencesFile() async {
  // Read directly from the .dart_tool directory where Flutter stores test data
  // Or from the actual SharedPreferences location on the device
  
  try {
    // Try reading from Flutter's test cache first (simplest approach)
    final testFile = File('.dart_tool/flutter_test_config.json');
    if (await testFile.exists()) {
      print('📁 Using test configuration\n');
    }
    
    // For actual app data, we need to use platform-specific paths
    // This is a simplified mock - in production you'd use platform channels
    // For now, let's create a mock data structure for testing
    
    print('⚠️  Using mock data for demonstration.');
    print('To use real data, run the app and export SharedPreferences.\n');
    
    // Return mock data structure that matches your app
    return {
      'flutter.currentSessionId': 'test_user_123',
      'flutter.inputs_test_user_123': jsonEncode({
        'Gender': ['Woman'],
        'Seeking': ['Man'],
        'Location': {
          'name': 'New York',
          'adminCode1': 'NY',
          'lat': 40.7128,
          'lng': -74.0060
        },
        'last_updated': DateTime.now().toIso8601String(),
        'session_id': 'test_user_123'
      })
    };
    
  } catch (e) {
    print('Error: $e');
    return null;
  }
}

void checkQualData(Map<String, dynamic> prefs, String? uid) {
  print('========== QUAL DATA CHECK ==========\n');
  
  // Find currentSessionId
  String? currentSessionId;
  prefs.forEach((key, value) {
    if (key.contains('currentSessionId')) {
      currentSessionId = value;
    }
  });
  
  final effectiveUid = uid ?? currentSessionId;
  if (effectiveUid == null) {
    print('❌ No user ID found');
    return;
  }
  
  print('User ID: $effectiveUid\n');
  
  // Find inputs data
  String? inputsJson;
  prefs.forEach((key, value) {
    if (key.contains('inputs_$effectiveUid')) {
      inputsJson = value;
    }
  });
  
  if (inputsJson == null) {
    print('❌ No inputs found for user $effectiveUid');
    return;
  }
  
  try {
    final inputs = jsonDecode(inputsJson!);
    
    // Check Gender
    print('Gender:');
    final gender = inputs['Gender'];
    if (gender == null) {
      print('  ⚠️ Not set');
    } else if (gender is List && gender.isNotEmpty) {
      print('  ✅ ${gender.join(', ')}');
    } else {
      print('  ⚠️ Empty');
    }
    
    // Check Seeking
    print('\nSeeking:');
    final seeking = inputs['Seeking'];
    if (seeking == null) {
      print('  ⚠️ Not set');
    } else if (seeking is List && seeking.isNotEmpty) {
      print('  ✅ ${seeking.join(', ')}');
    } else {
      print('  ⚠️ Empty');
    }
    
    // Check Location
    print('\nLocation:');
    final location = inputs['Location'];
    if (location == null) {
      print('  ⚠️ Not set');
    } else if (location is Map) {
      print('  ✅ ${location['name']}, ${location['adminCode1']}');
      print('  📍 Lat: ${location['lat']}, Lng: ${location['lng']}');
    }
    
    print('\n⏰ Last Updated: ${inputs['last_updated'] ?? 'Unknown'}');
    
  } catch (e) {
    print('❌ Error parsing: $e');
  }
  
  print('\n=====================================');
}

void dumpAll(Map<String, dynamic> prefs, String? uid) {
  print('========== PREFERENCES DUMP ==========\n');
  
  prefs.forEach((key, value) {
    if (value is String && value.startsWith('{')) {
      try {
        final json = jsonDecode(value);
        print('$key (JSON):');
        final pretty = JsonEncoder.withIndent('  ').convert(json);
        print(pretty.substring(0, pretty.length > 300 ? 300 : pretty.length));
        if (pretty.length > 300) print('  ...');
      } catch (_) {
        print('$key: $value');
      }
    } else {
      print('$key: $value');
    }
    print('');
  });
  
  print('=====================================');
}

void printHelp() {
  print('''
Debug SharedPreferences Tool
============================

USAGE:
  dart run bin/debug_prefs.dart [options]

OPTIONS:
  --check-qual       Check qual data (Gender/Seeking/Location)
  --uid <id>         Specify user ID
  --help, -h         Show this help

EXAMPLES:
  dart run bin/debug_prefs.dart --check-qual
  dart run bin/debug_prefs.dart --uid user123
''');
}