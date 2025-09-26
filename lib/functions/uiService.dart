import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'helpers/saveData_service.dart';
import '../providers/inputState.dart';
import 'package:image_picker/image_picker.dart';
import 'helpers/photo_service.dart';
import '../router/router.dart';

class UserActions {
  
  /* = = = = = = = = =
  Save to Local / Firebase 
  = = = = = = = = = */

  // Only used on Photos page, uses the saveToFirestore function, only one to use that. 
  // Want to consolodate into one function and move to Input Provider
  Future<void> savePhotosToFirebase(BuildContext context) async {
    try {
      final inputState = Provider.of<InputState>(context, listen: false);
      final authenticatedUserId = inputState.userId;
      if (authenticatedUserId == null) {
        throw Exception("User not authenticated");
      }
      
      List<InputPhoto> photos = inputState.photoInputs;
      
      if (photos.isEmpty) {
        print('⚠️ No photos to save for user: $authenticatedUserId');
        return;
      }
      
      Map<String, dynamic> photoData = {'photos': photos};
      
      await SaveDataService.saveToFirestore(data: photoData, userId: authenticatedUserId);

      print('✅ ${photos.length} photos saved to Firebase for user: $authenticatedUserId');
      
    } catch (e) {
      print('❌ savePhotosToFirebase: Failed - $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving photos: $e')),
        );
      }
    }
  }

  /* = = = = = = = = =
  Utilities
  = = = = = = = = = */

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

  /*Future<void> sendPhotoToCrop(BuildContext context) async {
    try {
      final XFile? selectedImage = await PhotoService.pickImage(context);
      if (selectedImage != null) {
        Navigator.pushNamed(context, AppRoutes.photoCrop, arguments: {'imageFile': selectedImage,},);
      }

      if (selectedImage == null) { 
        return; 
      }
    } catch (e) {
      print('Error in upload photo process: $e');
    }
  }*/

  Future<void> sendPhotoToCrop(BuildContext context) async {
  try {
    print('📸 1. Starting sendPhotoToCrop');
    
    final XFile? selectedImage = await PhotoService.pickImage();
    
    if (selectedImage == null) {
      print('📸 2. No image selected by user (cancelled)');
      return;
    }
    
    print('📸 3. Image selected successfully');
    print('📸 4. Image path: ${selectedImage.path}');
    print('📸 5. Image name: ${selectedImage.name}');
    
    // Verify the image exists and can be read
    try {
      final bytes = await selectedImage.readAsBytes();
      print('📸 6. Image size: ${bytes.length} bytes');
    } catch (e) {
      print('📸 ERROR: Cannot read image bytes: $e');
    }
    
    print('📸 7. Creating navigation arguments');
    final args = {'imageFile': selectedImage};
    
    print('📸 8. Arguments created, navigating to photoCrop...');
    print('📸 9. Route: ${AppRoutes.photoCrop}');
    print('📸 10. Arguments type: ${args.runtimeType}');
    print('📸 11. ImageFile type: ${selectedImage.runtimeType}');
    
    await Navigator.pushNamed(
      context, 
      AppRoutes.photoCrop, 
      arguments: args,
    );
    
    print('📸 12. Navigation to photoCrop completed');
    
  } catch (e, stackTrace) {
    print('📸 ERROR in sendPhotoToCrop: $e');
    print('📸 Stack trace: $stackTrace');
  }
}

}