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
    return _db.collection('yarnRolls').doc(_getSafeId(qr)).get();
  }

  Future<DocumentSnapshot?> findYarnByContent(String content) async {
    // Strategy 1: Direct Hash Lookup
    try {
      final doc = await getYarn(content);
      if (doc.exists) return doc;
    } catch (_) {}

    // Strategy 2: Search by 'rawQr' field
    final q1 = await _db.collection('yarnRolls')
        .where('rawQr', isEqualTo: content.trim())
        .limit(1)
        .get();
    if (q1.docs.isNotEmpty) return q1.docs.first;

    // Strategy 3: Handle JSON-formatted QRs
    try {
      final decoded = json.decode(content);
      if (decoded is Map<String, dynamic>) {
        final possibleId = decoded['id'] ?? decoded['yarnId'] ?? decoded['ID'];
        if (possibleId != null) {
          // Try lookup by the ID found in JSON
          final qJson = await _db.collection('yarnRolls')
              .where('id', isEqualTo: possibleId.toString())
              .limit(1)
              .get();
          if (qJson.docs.isNotEmpty) return qJson.docs.first;
        }
      }
    } catch (_) {}

    // Strategy 4: Fallback search for ID anywhere in fields
    // (This is a bit broader but helps find items added via different methods)
    final qAny = await _db.collection('yarnRolls')
        .where('id', isEqualTo: content.trim())
        .limit(1)
        .get();
    if (qAny.docs.isNotEmpty) return qAny.docs.first;

    return null;
  }

  // --- Reserved Collection Methods ---

  Stream<QuerySnapshot> getReservedYarns() {
    return _db.collection('reserved_collection')
        .where('state', whereIn: ['reserved', 'RESERVED'])
        .snapshots();
  }

  Stream<QuerySnapshot> getMovedYarns() {
    return _db.collection('reserved_collection')
        .where('state', whereIn: ['moved', 'MOVED'])
        .snapshots();
  }

  Future<void> updateYarnStatus(String docId, String newStatus) {
    return _db.collection('reserved_collection').doc(docId).update({
      'state': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addYarn(String qr, Map<String, dynamic> data) {
    // We also store the raw QR inside the document for reference
    final fullData = {
      ...data,
      'rawQr': qr.trim(),
    };
    return _db.collection('yarnRolls').doc(_getSafeId(qr)).set(fullData);
  }

  Future<void> deleteYarn(String qr) {
    return _db.collection('yarns').doc(_getSafeId(qr)).delete();
  }
}
