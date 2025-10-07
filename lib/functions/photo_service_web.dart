import 'dart:html' as html;
import 'dart:typed_data';

class PhotoServicePlatform {
  /// Creates a blob URL for web platform
  static String createObjectUrl(Uint8List bytes) {
    final blob = html.Blob([bytes]);
    return html.Url.createObjectUrlFromBlob(blob);
  }

  /// Creates a local file path synchronously (for compatibility) - not used on web
  static String createObjectUrlSync(Uint8List bytes, String tempDirPath) {
    // On web, we don't use temp directories, just create blob URL
    return createObjectUrl(bytes);
  }

  /// Creates a blob for Firebase upload (web-specific)
  static html.Blob createBlob(Uint8List bytes) {
    return html.Blob([bytes]);
  }

  /// Revokes a blob URL to free memory (web-specific)
  static void revokeObjectUrl(String url) {
    html.Url.revokeObjectUrl(url);
  }

  /// Gets platform name for debugging
  static String get platformName => 'web';

  /// Checks if platform supports blob URLs
  static bool get supportsBlobUrls => true;
}