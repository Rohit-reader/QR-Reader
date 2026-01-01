import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class YarnService {
  final _db = FirebaseFirestore.instance;

  String _getSafeId(String qr) {
    if (qr.trim().isEmpty) throw ArgumentError('QR code cannot be empty');
    // Hash the QR string to create a safe, fixed-length document ID
    final bytes = utf8.encode(qr.trim());
    return sha256.convert(bytes).toString();
  }

  Future<DocumentSnapshot> getYarn(String qr) {
    return _db.collection('yarns').doc(_getSafeId(qr)).get();
  }

  Future<void> addYarn(String qr, Map<String, dynamic> data) {
    // We also store the raw QR inside the document for reference
    final fullData = {
      ...data,
      'rawQr': qr.trim(),
    };
    return _db.collection('yarns').doc(_getSafeId(qr)).set(fullData);
  }

  Future<void> deleteYarn(String qr) {
    return _db.collection('yarns').doc(_getSafeId(qr)).delete();
  }
}
