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
    final raw = content.trim();
    if (raw.isEmpty) return null;

    // Strategy 1: Direct Hash Lookup (Original method)
    try {
      final doc = await getYarn(raw);
      if (doc.exists) return doc;
    } catch (_) {}

    // Strategy 2: Search by 'rawQr' field (Exact match)
    final qRaw = await _db.collection('yarnRolls')
        .where('rawQr', isEqualTo: raw)
        .limit(1)
        .get();
    if (qRaw.docs.isNotEmpty) return qRaw.docs.first;

    // Strategy 3: Handle JSON-formatted QRs
    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) {
        final possibleId = decoded['id'] ?? decoded['yarnId'] ?? decoded['ID'];
        if (possibleId != null) {
          final idStr = possibleId.toString().trim();
          final qJson = await _db.collection('yarnRolls')
              .where('id', isEqualTo: idStr)
              .limit(1)
              .get();
          if (qJson.docs.isNotEmpty) return qJson.docs.first;
        }
      }
    } catch (_) {}

    // Strategy 4: Clean alphanumeric search against 'id'
    // This helps if the QR is like "ID: YR12345" or "YR12345 (SILK)"
    final cleanPattern = RegExp(r'[a-zA-Z0-9]{4,}'); // Look for alphanumeric strings of at least 4 chars
    final matches = cleanPattern.allMatches(raw).map((m) => m.group(0)!).toList();
    
    for (final match in matches) {
      final qMatch = await _db.collection('yarnRolls')
          .where('id', isEqualTo: match)
          .limit(1)
          .get();
      if (qMatch.docs.isNotEmpty) return qMatch.docs.first;
    }

    // Strategy 5: Part-based search
    // Split by common delimiters and try each part
    final parts = raw.split(RegExp(r'[:\s\-_/|,]')).where((p) => p.length >= 3).toList();
    for (final part in parts) {
      final pTrim = part.trim();
      final qPart = await _db.collection('yarnRolls')
          .where('id', isEqualTo: pTrim)
          .limit(1)
          .get();
      if (qPart.docs.isNotEmpty) return qPart.docs.first;
      
      final qPartRaw = await _db.collection('yarnRolls')
          .where('rawQr', isEqualTo: pTrim)
          .limit(1)
          .get();
      if (qPartRaw.docs.isNotEmpty) return qPartRaw.docs.first;
    }

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
