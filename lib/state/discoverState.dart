import 'package:flutter/material.dart';
import '../functions/airTrafficControler_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DiscoverState extends ChangeNotifier {
  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  String? errorMessage;

  // Get a reference to your AirTrafficControl
  final AirTrafficController _airTrafficControl = AirTrafficController();

  Future<void> fetchUsers() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    
    try {
      // Call the method in AirTrafficControl
      List<Map<String, dynamic>> fetchedUsers = await _airTrafficControl.calculateMatches();
      // Manually convert each user, handling special Firestore types
      users = [];
      for (var user in fetchedUsers) {
        // Create a new map for each user
        Map<String, dynamic> cleanUser = {};
        
        // Process each field
        user.forEach((key, value) {
          // Handle special Firestore types
          if (value is Timestamp) {
            // Convert Timestamp to milliseconds since epoch
            cleanUser[key] = value.millisecondsSinceEpoch;
          } else if (value is DateTime) {
            cleanUser[key] = value.millisecondsSinceEpoch;
          } else if (value is List) {
            // Handle lists (including potential nested Timestamps)
            cleanUser[key] = List.from(value);
          } else if (value is Map) {
            // Handle maps (including potential nested Timestamps)
            cleanUser[key] = Map<String, dynamic>.from(value);
          } else {
            // For regular values, copy as is
            cleanUser[key] = value;
          }
        });
        users.add(cleanUser);
      }
    
      print("After manual conversion, user count: ${users.length}");

      print("DiscoverState: Fetched ${users.length} users");
      if (users.isNotEmpty) {
        print("DiscoverState: First user: ${users[0].toString().substring(0, 100)}...");
      }
      
    } catch (e) {
      errorMessage = "Failed to load users: $e";
      print("DiscoverState: Error fetching users: $e");
    } finally {
      isLoading = false;
      notifyListeners();
      print("DiscoverState: Notified listeners after fetch");
    }
  }
  
}