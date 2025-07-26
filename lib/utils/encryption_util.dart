import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encryption;

class EncryptionUtil {
  late encryption.Encrypter _encrypter;
  late encryption.IV _iv;
  
  EncryptionUtil() {
    _iv = encryption.IV.fromLength(16);
  }
  
  void initializeEncrypter(String key) {
    final keyBytes = sha256.convert(utf8.encode(key)).bytes;
    final encryptKey = encryption.Key(Uint8List.fromList(keyBytes));
    _encrypter = encryption.Encrypter(encryption.AES(encryptKey));
  }
  
  String generateKey() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }
  
  Future<String> encrypt(String plainText) async {
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      print('Encryption error: $e');
      rethrow;
    }
  }
  
  Future<String> decrypt(String encryptedText) async {
    try {
      final encrypted = encryption.Encrypted.fromBase64(encryptedText);
      return _encrypter.decrypt(encrypted, iv: _iv);
    } catch (e) {
      print('Decryption error: $e');
      rethrow;
    }
  }
}
