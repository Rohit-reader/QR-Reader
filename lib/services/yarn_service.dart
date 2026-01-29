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

  Future<void> addYarn(String qr, Map<String, dynamic> data) async {
    // Generate a unique sequential ID if not already providing a system ID
    String systemId = await _generateUniqueYarnId();
    
    // Use the parsed 'id' as 'originalId' for reference, and systemId as the primary tracking ID
    final docId = systemId; 
    
    // Filter out fields with "unknown" values (case-insensitive)
    final filteredData = Map<String, dynamic>.from(data);
    filteredData.removeWhere((key, value) => 
      value.toString().toLowerCase() == 'unknown'
    );
    
    // We also store the raw QR inside the document for reference
    final fullData = {
      ...filteredData,
      'rawQr': qr.trim(),
      'id': systemId, 
      'originalQrId': data['id'],
      'createdAt': FieldValue.serverTimestamp(),
    };
    return _db.collection('yarnRolls').doc(docId).set(fullData);
  }

  Future<String> _generateUniqueYarnId() async {
    try {
      // Query the collection for the latest YR-XXXXX ID
      final snapshot = await _db.collection('yarnRolls')
          .where('id', isGreaterThanOrEqualTo: 'YR-00000')
          .where('id', isLessThanOrEqualTo: 'YR-99999')
          .orderBy('id', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return 'YR-00001';
      }

      final lastId = snapshot.docs.first.get('id') as String;
      final numericPart = int.parse(lastId.replaceFirst('YR-', ''));
      final nextNumber = numericPart + 1;
      
      return 'YR-${nextNumber.toString().padLeft(5, '0')}';
    } catch (e) {
      print('Error generating unique ID: $e');
      // Fallback to timestamp based ID if query fails to avoid blocking
      return 'YR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    }
  }

  Map<String, dynamic> parseYarnData(String qr) {
    final raw = qr.trim();
    Map<String, dynamic> data = {};
    
    // Try parsing as JSON first
    try {
      final decoded = json.decode(raw);
      if (decoded is Map<String, dynamic>) {
        // Iterate over all keys to normalize and capture everything
        decoded.forEach((key, value) {
          final kLower = key.toString().trim().toLowerCase();
          if (kLower.isEmpty) return; // Skip empty keys
          
          // Add original pair
          data[key] = value;
          
          // Normalized mapping
          if (key.contains('Material') || kLower == 'material') data['material'] = value;
          if (key.contains('Type') || kLower == 'type' || kLower == 'yarntype') data['type'] = value; 
          if (key.contains('Bin') || kLower == 'bin') data['bin'] = value;
          if (key.contains('Rack') || kLower == 'rack') data['rack'] = value;
          
          // Specific requested fields
          if (kLower.contains('rack') && kLower.contains('id')) data['rack_id'] = value;
          if (kLower.contains('yarn') && kLower.contains('count')) data['yarn_count'] = value;
          if (kLower.contains('yarn') && kLower.contains('type')) data['yarn_type'] = value;
          if (kLower == 'id' || kLower == 'yarnid') data['id'] = value;
        });
        
        return data;
      }
    } catch (_) {}

    // Fallback: Try Key-Value pairs with common delimiters
    final pairs = raw.split(RegExp(r'[,|;\n]'));
    bool foundAnyKv = false;
    for (var pair in pairs) {
      final kv = pair.split(RegExp(r'[:=]'));
      if (kv.length == 2) {
        final key = kv[0].trim().toLowerCase();
        if (key.isEmpty) continue; // Skip empty keys
        
        final value = kv[1].trim();
        data[key] = value;
        foundAnyKv = true;

        if (key.contains('id') && !key.contains('rack')) data['id'] = value;
        if (key.contains('mat') || key.contains('material')) data['material'] = value;
        if (key.contains('type') && !key.contains('yarn')) data['type'] = value;
        if (key.contains('bin')) data['bin'] = value;
        if (key.contains('rack') && !key.contains('id')) data['rack'] = value;
        
        // Specific requested fields
        if (key.contains('rack') && key.contains('id')) data['rack_id'] = value;
        if (key.contains('yarn') && key.contains('count')) data['yarn_count'] = value;
        if (key.contains('yarn') && key.contains('type')) data['yarn_type'] = value;
      }
    }

    if (data['id'] == null && !foundAnyKv && raw.length > 2) {
      data['id'] = raw;
    }

    return data;
  }

  Future<void> deleteYarn(String qr) {
    return _db.collection('yarns').doc(_getSafeId(qr)).delete();
  }
}
