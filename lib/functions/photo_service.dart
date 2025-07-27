import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../data/inputState.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

// Conditional import - will choose the right implementation
import 'photo_service_web.dart' if (dart.library.io) 'photo_service_mobile.dart';

class PhotoService {
  final BuildContext context;
  final Function(bool) onLoadingChanged;
  final Function(List<String>) onPhotosUpdated;
  final List<String> photoUrls;

  PhotoService({
    required this.context,
    required this.onLoadingChanged,
    required this.onPhotosUpdated,
    required this.photoUrls,
  });

  static Future<List<String>> uploadAllPhotos(BuildContext context, String userId) async {
    final inputState = Provider.of<InputState>(context, listen: false);
    final List<String> downloadUrls = [];
    
    for (var photo in inputState.photoInputs) {
      if (kIsWeb && photo.croppedBytes != null) {
        // Use the platform-specific service for creating blob
        final blob = PhotoServicePlatform.createBlob(photo.croppedBytes!);
        final ref = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('user_photos/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
        final task = ref.putBlob(blob);
        final snapshot = await task;
        final url = await snapshot.ref.getDownloadURL();
        downloadUrls.add(url);
      } else if (!kIsWeb && photo.localPath != null) {
        final file = File(photo.localPath!);
        final ref = firebase_storage.FirebaseStorage.instance
            .ref()
            .child('user_photos/$userId/${DateTime.now().millisecondsSinceEpoch}.jpg');
        final task = ref.putFile(file);
        final snapshot = await task;
        final url = await snapshot.ref.getDownloadURL();
        downloadUrls.add(url);
      }
    }
    return downloadUrls;
  }

  static Future<XFile?> pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image == null) return null;
      
      print('Selected image for upload: ${image.path}');
      
      // Validate file type (JPG or PNG)
      final String? mimeType = image.mimeType;

      if (mimeType != null &&
      !mimeType.contains('jpeg') &&
      !mimeType.contains('png')) {
        print('Please select a JPG or PNG image');
        return null;
      }
      
      return image;
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting photo: $e')),
      );
      return null;
    }
  }

  static Future<List<String>> fetchExistingPhotos({
    String? targetUid,
    dynamic selection = "all",
  }) async {
    try {
      // Use the provided UID, or default to the current user's UID
      final userId = targetUid ?? FirebaseAuth.instance.currentUser!.uid;
      print('Fetching photos for user: $userId');

      // Fetch the user's document from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      // Check if photos exist in the user's document
      if (userDoc.exists && userDoc.data()!.containsKey('photos')) {
        final photos = List<String>.from(userDoc.data()!['photos'] ?? []);
        
        // Return based on the selection parameter
        if (selection == "all") {
          return photos; // Return all photos
        } else if (selection == "last_uploaded") {
          return photos.isNotEmpty ? [photos.last] : [];
        } else if (selection is int && selection >= 0 && selection < photos.length) {
          return [photos[selection]]; 
        } else {
          print('Invalid selection parameter: $selection');
          return [];
        }
      } else {
        print('No photos found in document');
        return [];
      }
    } catch (e) {
      print('Error fetching photos: $e');
      throw Exception('Error loading photos: $e');
    }
  }
  
  Future<void> removePhoto(int index) async {
    try {
      if (index < 0 || index >= photoUrls.length) {
        print('Invalid index: $index, photoUrls length: ${photoUrls.length}');
        return;
      }
      final url = photoUrls[index];
      final userId = FirebaseAuth.instance.currentUser!.uid;
      List<String> updatedPhotos = List<String>.from(photoUrls);
      updatedPhotos.removeAt(index);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'photos': updatedPhotos,
      });
      final ref = FirebaseStorage.instance.refFromURL(url);
      await ref.delete();
      print('Photo removed, notifying UI with updated photos');
      onPhotosUpdated(updatedPhotos);
    } catch (e) {
      print('Error removing photo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing photo: $e')),
      );
    }
  }
}