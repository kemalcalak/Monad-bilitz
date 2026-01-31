import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:convert/convert.dart';

/// Cryptographic utilities for HKAS key derivation and signature operations
class CryptoUtils {
  CryptoUtils._();

  /// Derive a child key using HKAS (Hierarchical Key Assignment Scheme)
  /// 
  /// Key derivation: K_child = HMAC-SHA256(K_parent, "level_N" || user_id)
  static String deriveChildKey({
    required String parentKey,
    required int level,
    required String userId,
  }) {
    final keyData = 'level_$level$userId';
    final hmac = Hmac(sha256, utf8.encode(parentKey));
    final digest = hmac.convert(utf8.encode(keyData));
    return hex.encode(digest.bytes);
  }
  
  /// Hash data using SHA-256
  static String sha256Hash(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return hex.encode(digest.bytes);
  }
  
  /// Hash a contract content for storage
  static String hashContractContent(String content) {
    return sha256Hash(content);
  }
  
  /// Generate a unique identifier
  static String generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    return sha256Hash('$timestamp-$random').substring(0, 32);
  }
  
  /// Encode bytes to hex string
  static String bytesToHex(Uint8List bytes) {
    return hex.encode(bytes);
  }
  
  /// Decode hex string to bytes
  static Uint8List hexToBytes(String hexString) {
    return Uint8List.fromList(hex.decode(hexString));
  }
  
  /// Prepare message for signing (Ethereum signed message format)
  static String prepareMessageForSigning(String message) {
    final prefix = '\x19Ethereum Signed Message:\n${message.length}';
    return sha256Hash('$prefix$message');
  }
  
  /// Verify that a key hash matches expected value
  static bool verifyKeyHash(String key, String expectedHash) {
    final computedHash = sha256Hash(key);
    return computedHash == expectedHash;
  }
  
  /// Create a deterministic key from multiple inputs
  static String createDeterministicKey(List<String> inputs) {
    final combined = inputs.join('|');
    return sha256Hash(combined);
  }
}
