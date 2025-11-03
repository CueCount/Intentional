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
// Add this import for image compression
import 'package:image/image.dart' as img;

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

  // NEW: Image compression method
  static Future<Uint8List> compressImageForWeb(
    Uint8List imageBytes, {
    int maxWidth = 800,
    int maxHeight = 800,
    int quality = 75,
  }) async {
    try {
      // Only compress on web where storage is limited
      if (!kIsWeb) {
        return imageBytes;
      }

      // Decode the image
      img.Image? image = img.decodeImage(imageBytes);
      
      if (image == null) {
        print('⚠️ Could not decode image, using original');
        return imageBytes;
      }
      
      // Calculate new dimensions while maintaining aspect ratio
      int width = image.width;
      int height = image.height;
      
      if (width > maxWidth || height > maxHeight) {
        double widthRatio = maxWidth / width;
        double heightRatio = maxHeight / height;
        double ratio = widthRatio < heightRatio ? widthRatio : heightRatio;
        
        width = (width * ratio).round();
        height = (height * ratio).round();
        
        // Resize the image
        image = img.copyResize(image, width: width, height: height);
      }
      
      // Encode as JPEG with quality setting
      List<int> compressed = img.encodeJpg(image, quality: quality);
      
      Uint8List result = Uint8List.fromList(compressed);
      
      // Log compression results
      double originalSizeMB = imageBytes.length / (1024 * 1024);
      double compressedSizeMB = result.length / (1024 * 1024);
      double reduction = ((originalSizeMB - compressedSizeMB) / originalSizeMB) * 100;
      
      print('🗜️ Image compressed: ${originalSizeMB.toStringAsFixed(2)}MB → ${compressedSizeMB.toStringAsFixed(2)}MB (${reduction.toStringAsFixed(0)}% reduction)');
      
      // If compression didn't help much, try more aggressive settings
      if (compressedSizeMB > 0.5 && quality > 50) {
        print('📉 Still too large, trying more aggressive compression...');
        return compressImageForWeb(
          imageBytes,
          maxWidth: 600,
          maxHeight: 600,
          quality: 50,
        );
      }
      
      return result;
    } catch (e) {
      print('❌ Error compressing image: $e');
      return imageBytes;
    }
  }

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
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoEditorPage(
            existingPhoto: photo,
            existingPhotoIndex: index,
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
      // COMPRESS FOR WEB BEFORE SAVING
      Uint8List processedBytes = editedBytes;
      if (kIsWeb) {
        print('🔄 Compressing image for web storage...');
        processedBytes = await compressImageForWeb(editedBytes);
      }
      
      String? localPath;

      if (kIsWeb) {
        // Web: Create blob URL from compressed bytes
        localPath = PhotoServicePlatform.createObjectUrl(processedBytes);
      } else {
        // Mobile: Save to app directory (original bytes)
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final file = File('${appDir.path}/$fileName');
        await file.writeAsBytes(processedBytes);
        localPath = file.path;
      }

      return InputPhoto(
        croppedBytes: processedBytes,  // Use compressed bytes
        localPath: localPath,
      );
    } catch (e) {
      print('Error saving edited image: $e');
      return null;
    }
  }

}