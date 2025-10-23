import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../providers/inputState.dart';
import '../pages/Needs/photoEditor.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'photo_service_web.dart' if (dart.library.io) 'photo_service_mobile.dart';

class PhotoService {
  final BuildContext context;
  final Function(bool) onLoadingChanged;
  final Function(List<String>) onPhotosUpdated;
  final List<String> photoUrls;
  static final ImagePicker _picker = ImagePicker();

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

  static Future<void> pickAndEditPhoto(BuildContext context) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
      );
      
      if (image == null) return;
      
      // Navigate to editor page with the picked image
      /*final result = await Navigator.push<InputPhoto>(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoEditorPage(imageFile: image),
        ),
      );
      
      if (result != null && context.mounted) {
        final inputState = Provider.of<InputState>(context, listen: false);
        inputState.photoInputs.add(result);
        await inputState.savePhotosLocally();
      }*/

      Navigator.push<InputPhoto>(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoEditorPage(imageFile: image),
        ),
      );

    } catch (e) {
      print('Error picking image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
      }
    }
  }

  static Future<void> editExistingPhoto(BuildContext context, int index) async {
    try {
      final inputState = Provider.of<InputState>(context, listen: false);
      
      if (index < 0 || index >= inputState.photoInputs.length) {
        print('Invalid photo index: $index');
        return;
      }
      
      final photo = inputState.photoInputs[index];
      
      // Navigate to editor with existing photo
      /*final result = await Navigator.push<InputPhoto>(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoEditorPage(
            existingPhoto: photo,
          ),
        ),
      );
      
      if (result != null && context.mounted) {
        inputState.photoInputs[index] = result;
        await inputState.savePhotosLocally();
      }*/

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoEditorPage(
            existingPhoto: photo,
            existingPhotoIndex: index, // Pass the index
          ),
        ),
      );
    } catch (e) {
      print('Error editing photo: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error editing photo: ${e.toString()}')),
        );
      }
    }
  }

  static Future<void> removePhoto(BuildContext context, int index) async {
    try {
      final inputState = Provider.of<InputState>(context, listen: false);
      
      if (index < 0 || index >= inputState.photoInputs.length) {
        print('Invalid photo index: $index');
        return;
      }
      
      inputState.photoInputs.removeAt(index);
      await inputState.savePhotosLocally();
      
      // IMPORTANT: Notify listeners to update UI
      inputState.notifyListeners();
    } catch (e) {
      print('Error removing photo: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing photo: ${e.toString()}')),
        );
      }
    }
  }

  static Future<InputPhoto?> saveEditedImage(Uint8List editedBytes) async {
    try {
      String? localPath;

      if (kIsWeb) {
        // Web: Create blob URL
        localPath = PhotoServicePlatform.createObjectUrl(editedBytes);
      } else {
        // Mobile: Save to app directory
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${appDir.path}/$fileName');
        await file.writeAsBytes(editedBytes);
        localPath = file.path;
      }

      return InputPhoto(
        croppedBytes: editedBytes,
        localPath: localPath,
      );
    } catch (e) {
      print('Error saving edited image: $e');
      return null;
    }
  }

}