class StreamConfig {
  // Store your API key here - in production, use environment variables
  // or encrypted storage. Never commit actual keys to version control.
  static const String apiKey = '7x5k3jfmandk';
  
  // For added security, you can encode/decode the key
  static String getApiKey() {
    // In production, implement proper decryption here
    // Example: return decryptKey(encryptedKey);
    return apiKey;
  }
}