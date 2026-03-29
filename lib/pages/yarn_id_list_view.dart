import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/yarn_service.dart';

class YarnIdListView extends StatefulWidget {
  final List<QueryDocumentSnapshot> docs;
  final String searchQuery;
  final String sortOption;

  const YarnIdListView({
    super.key,
    required this.docs,
    required this.searchQuery,
    required this.sortOption,
  });

  @override
  State<YarnIdListView> createState() => _YarnIdListViewState();
}

class _YarnIdListViewState extends State<YarnIdListView> {

  // ✅ SORT FUNCTION WITH DATE
  List<QueryDocumentSnapshot> _sortDocs(List<QueryDocumentSnapshot> docs) {
    docs.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      final idA = (dataA['id'] ?? a.id).toString();
      final idB = (dataB['id'] ?? b.id).toString();

      final supplierA = (dataA['supplier_name'] ?? '').toString();
      final supplierB = (dataB['supplier_name'] ?? '').toString();

      final rawA = dataA['created_at'] ?? dataA['timestamp'];
      final rawB = dataB['created_at'] ?? dataB['timestamp'];

      DateTime dateA =
      rawA is Timestamp ? rawA.toDate() : DateTime(2000);
      DateTime dateB =
      rawB is Timestamp ? rawB.toDate() : DateTime(2000);

      switch (widget.sortOption) {
        case 'date_asc':
          return dateA.compareTo(dateB);
        case 'date_desc':
          return dateB.compareTo(dateA);
        case 'id_desc':
          return idB.compareTo(idA);
        case 'supplier_asc':
          return supplierA.compareTo(supplierB);
        case 'supplier_desc':
          return supplierB.compareTo(supplierA);
        case 'id_asc':
        default:
          return idA.compareTo(idB);
      }
    });
    return docs;
  }

  @override
  Widget build(BuildContext context) {
    final YarnService yarnService = YarnService();

    // ✅ FILTER
    var filteredDocs = widget.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final id = (data['id'] ?? doc.id).toString().toLowerCase();
      return id.contains(widget.searchQuery.toLowerCase());
    }).toList();

    // ✅ SORT
    filteredDocs = _sortDocs(filteredDocs);

    if (filteredDocs.isEmpty) {
      return const Center(child: Text("No Data"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredDocs.length,
      itemBuilder: (_, index) {
        final doc = filteredDocs[index];
        final data = doc.data() as Map<String, dynamic>;

        final yarnId = data['id'] ?? doc.id;
        final supplier = data['supplier_name'] ?? 'Unknown';

        return GestureDetector(
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFF9FAFB)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Row(
              children: [

                // 📦 ICON
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.inventory_2, color: Colors.green),
                ),

                const SizedBox(width: 16),

                // 📄 DETAILS
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        yarnId.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black, // yarn id text color
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        supplier,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // 🟢 STATUS
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "RESERVED",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}