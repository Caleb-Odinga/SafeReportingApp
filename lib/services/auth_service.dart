import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:safe_reporting/utils/encryption_util.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final EncryptionUtil _encryptionUtil = EncryptionUtil();
  
  User? get currentUser => _auth.currentUser;
  bool get isAnonymous => currentUser?.isAnonymous ?? true;
  
  String? _anonymousId;
  String? get anonymousId => _anonymousId;
  
  AuthService() {
    _initializeAnonymousId();
  }
  
  Future<void> _initializeAnonymousId() async {
    _anonymousId = await _secureStorage.read(key: 'anonymousId');
    if (_anonymousId == null) {
      _anonymousId = const Uuid().v4();
      await _secureStorage.write(key: 'anonymousId', value: _anonymousId);
    }
    notifyListeners();
  }
  
  Future<UserCredential> signInAnonymously() async {
    try {
      final result = await _auth.signInAnonymously();
      
      // Store user reference in Firestore with encrypted anonymous ID
      final encryptedId = await _encryptionUtil.encrypt(_anonymousId!);
      await _firestore.collection('users').doc(result.user!.uid).set({
        'encryptedAnonymousId': encryptedId,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
      return result;
    } catch (e) {
      print('Error signing in anonymously: $e');
      rethrow;
    }
  }
  
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
  
  Future<void> updateLastActive() async {
    if (currentUser != null) {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    }
  }
  
  Future<String> getEncryptionKey() async {
    String? key = await _secureStorage.read(key: 'encryptionKey');
    if (key == null) {
      key = _encryptionUtil.generateKey();
      await _secureStorage.write(key: 'encryptionKey', value: key);
    }
    return key;
  }
}
