import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PhotoServicePlatform {
  /// Creates a local file path for mobile platform (async version)
  static Future<String> createObjectUrlAsync(Uint8List bytes) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      
      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'photo_$timestamp.jpg';
      final filePath = '${tempDir.path}/$filename';
      
      // Write bytes to file
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      
      return filePath;
    } catch (e) {
      throw Exception('Failed to save photo on mobile: $e');
    }
  }

  /// Creates a local file path synchronously (for compatibility with web)
  static String createObjectUrl(Uint8List bytes) {
    throw UnimplementedError('Synchronous createObjectUrl not supported on mobile - use createObjectUrlSync with tempDirPath');
  }

  /// Creates a local file path synchronously (for compatibility)
  static String createObjectUrlSync(Uint8List bytes, String tempDirPath) {
    try {
      // Create unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'photo_$timestamp.jpg';
      final filePath = '$tempDirPath/$filename';
      
      // Write bytes to file synchronously
      final file = File(filePath);
      file.writeAsBytesSync(bytes);
      
      return filePath;
    } catch (e) {
      throw Exception('Failed to save photo on mobile: $e');
    }
  }

  /// Mobile doesn't use blobs, but we need this for compatibility
  static dynamic createBlob(Uint8List bytes) {
    throw UnimplementedError('Blob creation not needed on mobile platform');
  }

  /// Removes a local file (mobile-specific cleanup)
  static Future<void> revokeObjectUrl(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore errors when cleaning up temp files
      print('Warning: Could not delete temp file $filePath: $e');
    }
  }

  /// Gets platform name for debugging
  static String get platformName => 'mobile';

  /// Checks if platform supports blob URLs (false for mobile)
  static bool get supportsBlobUrls => false;
}