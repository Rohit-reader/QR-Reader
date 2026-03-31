import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './company_yarn_list_page.dart';

class CompanyListView extends StatefulWidget {
  final List<QueryDocumentSnapshot> docs;
  final String searchQuery;
  final String sortOption;
  final bool showIconBackground;

  const CompanyListView({
    super.key,
    required this.docs,
    required this.searchQuery,
    required this.sortOption,
    this.showIconBackground = false,
  });

  @override
  State<CompanyListView> createState() => _CompanyListViewState();
}

class _CompanyListViewState extends State<CompanyListView> {
  @override
  Widget build(BuildContext context) {
    // 1. Group by Supplier
    Map<String, List<QueryDocumentSnapshot>> companyMap = {};
    for (var doc in widget.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final supplier = data['supplier_name'] ?? 'Unknown';
      if (!companyMap.containsKey(supplier)) {
        companyMap[supplier] = [];
      }
      companyMap[supplier]!.add(doc);
    }

    // 2. Filter by search query
    final query = widget.searchQuery.toLowerCase();
    final companyStats = companyMap.entries.where((entry) {
      return entry.key.toLowerCase().contains(query);
    }).map((entry) {
      final name = entry.key;
      final tempDocs = entry.value;

      int unverifiedCount = 0;
      DateTime maxDate = DateTime(2000);

      for (var d in tempDocs) {
        final data = d.data() as Map<String, dynamic>;
        
        final state = data['state'] ?? 'RESERVED';
        final isVerified = state == 'VERIFIED';
        final isScanned = data['is_scanned'] ?? false;
        
        if (!isVerified && !isScanned) {
          unverifiedCount++;
        }

        final rawDate = data['updatedAt'];
        DateTime dDate = rawDate is Timestamp ? rawDate.toDate() : DateTime(2000);
        if (dDate.isAfter(maxDate)) {
          maxDate = dDate;
        }
      }

      return {
        'name': name,
        'docs': tempDocs,
        'unverifiedCount': unverifiedCount,
        'latestDate': maxDate,
      };
    }).toList();

    // 3. Sort
    companyStats.sort((a, b) {
      String nameA = a['name'] as String;
      String nameB = b['name'] as String;
      int sumA = a['unverifiedCount'] as int;
      int sumB = b['unverifiedCount'] as int;
      DateTime dateA = a['latestDate'] as DateTime;
      DateTime dateB = b['latestDate'] as DateTime;

      switch (widget.sortOption) {
        case 'name_desc':
          return nameB.compareTo(nameA);
        case 'count_asc':
          return sumA.compareTo(sumB);
        case 'count_desc':
          return sumB.compareTo(sumA);
        case 'date_asc':
          return dateA.compareTo(dateB);
        case 'date_desc':
          return dateB.compareTo(dateA);
        case 'name_asc':
        default:
          return nameA.compareTo(nameB);
      }
    });

    if (companyStats.isEmpty) {
      return const Center(child: Text("No Data"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: companyStats.length,
      itemBuilder: (_, index) {
        final comp = companyStats[index];
        final String companyName = comp['name'] as String;
        final int unverifiedCount = comp['unverifiedCount'] as int;
        final List<QueryDocumentSnapshot> compDocs = comp['docs'] as List<QueryDocumentSnapshot>;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompanyYarnListPage(
                    companyName: companyName,
                    docs: compDocs,
                  ),
                ),
              );
            },
            child: Container(
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
                   Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.business, color: Colors.green),
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           companyName,
                           style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                         ),
                         const SizedBox(height: 4),
                         Text(
                           "$unverifiedCount reserved",
                           style: TextStyle(color: Colors.grey[600], fontSize: 13),
                         )
                       ],
                     ),
                   ),
                   const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}