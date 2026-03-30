import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class YarnService {
  final _db = FirebaseFirestore.instance;

  String _getSafeId(String qr) {
    if (qr.trim().isEmpty) throw ArgumentError('QR code cannot be empty');
    final bytes = utf8.encode(qr.trim());
    return sha256.convert(bytes).toString();
  }

  Future<DocumentSnapshot> getYarn(String qr) {
    return _db.collection('yarnRolls').doc(_getSafeId(qr)).get();
  }

  Future<DocumentSnapshot?> findYarnByContent(String content) async {
    final raw = content.trim();
    if (raw.isEmpty) return null;

    try {
      final doc = await getYarn(raw);
      if (doc.exists) return doc;
    } catch (_) {}

    final qRaw = await _db
        .collection('yarnRolls')
        .where('rawQr', isEqualTo: raw)
        .limit(1)
        .get();
    if (qRaw.docs.isNotEmpty) return qRaw.docs.first;

    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) {
        final possibleId = decoded['id'] ?? decoded['yarnId'] ?? decoded['ID'];
        if (possibleId != null) {
          final qJson = await _db
              .collection('yarnRolls')
              .where('id', isEqualTo: possibleId.toString())
              .limit(1)
              .get();
          if (qJson.docs.isNotEmpty) return qJson.docs.first;
        }
      }
    } catch (_) {}

    return null;
  }

  // ================= RESERVED COLLECTION =================

  Stream<QuerySnapshot> getReservedYarns() {
    return _db
        .collection('reserved_collection')
        .where('state', whereIn: ['reserved', 'RESERVED'])
        .snapshots();
  }

  Stream<QuerySnapshot> getMovedYarns() {
    return _db
        .collection('reserved_collection')
        .where('state', whereIn: ['moved', 'MOVED'])
        .snapshots();
  }

  Future<void> updateYarnStatus(String docId, String newStatus) {
    return _db.collection('reserved_collection').doc(docId).update({
      'state': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteReservedYarnById(String docId) async {
    await _db.collection('reserved_collection').doc(docId).delete();
  }

  // ================= NEW SCAN & VERIFIED FEATURE =================

  /// ✅ Mark yarn as scanned
  Future<void> markAsScanned(String docId) async {
    await _db.collection('reserved_collection').doc(docId).update({
      'is_scanned': true,
      'scanned_at': FieldValue.serverTimestamp(),
    });
  }

  /// ✅ Mark yarn as verified
  Future<void> markAsVerified(String docId) async {
    await _db.collection('reserved_collection').doc(docId).update({
      'state': 'VERIFIED',
      'is_scanned': true,
      'verified_at': FieldValue.serverTimestamp(),
      'last_state_change': FieldValue.serverTimestamp(),
    });
  }

  /// ✅ Check if already scanned or verified (prevents duplicate scans)
  Future<bool> isAlreadyScanned(String docId) async {
    final doc = await _db.collection('reserved_collection').doc(docId).get();
    if (!doc.exists) return false;
    final data = doc.data();
    return (data?['is_scanned'] ?? false) || (data?['state'] == 'VERIFIED');
  }

  /// 🔁 OPTIONAL: Reset scan (undo feature)
  Future<void> resetScan(String docId) async {
    await _db.collection('reserved_collection').doc(docId).update({
      'is_scanned': false,
      'scanned_at': null,
      'state': 'RESERVED',
      'last_state_change': FieldValue.serverTimestamp(),
    });
  }

  // ================= ADD YARN =================

  Future<void> addYarn(String qr, Map<String, dynamic> data) async {
    String systemId = await _generateUniqueYarnId();

    final filteredData = Map<String, dynamic>.from(data);
    filteredData.removeWhere(
            (key, value) => value.toString().toLowerCase() == 'unknown');

    final fullData = {
      ...filteredData,
      'rawQr': qr.trim(),
      'id': systemId,
      'originalQrId': data['id'],
      'createdAt': FieldValue.serverTimestamp(),
    };

    return _db.collection('yarnRolls').doc(systemId).set(fullData);
  }

  Future<String> _generateUniqueYarnId() async {
    try {
      final snapshot = await _db
          .collection('yarnRolls')
          .orderBy('id', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return 'YR-00001';

      final lastId = snapshot.docs.first.get('id') as String;
      final num = int.parse(lastId.replaceAll('YR-', '')) + 1;
      return 'YR-${num.toString().padLeft(5, '0')}';
    } catch (_) {
      return 'YR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
  }

  /// ✅ UPDATED parseYarnData TO RETURN READABLE FIELDS
  Map<String, dynamic> parseYarnData(String qr) {
    final trimmed = qr.trim();
    try {
      final decoded = json.decode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final Map<String, dynamic> humanReadable = {};
        decoded.forEach((key, value) {
          if (value != null &&
              value.toString().toLowerCase() != 'unknown') {
            humanReadable[_capitalizeKey(key)] = value;
          }
        });
        return humanReadable.isEmpty ? {'ID': trimmed} : humanReadable;
      }
    } catch (_) {}

    return {'ID': trimmed};
  }

  String _capitalizeKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) =>
    word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }

  Future<void> deleteYarn(String qr) {
    return _db.collection('yarns').doc(_getSafeId(qr)).delete();
  }
}