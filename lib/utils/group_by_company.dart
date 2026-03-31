import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/company_model.dart';

List<CompanyModel> groupByCompany(List<QueryDocumentSnapshot> docs) {
  final Map<String, List<QueryDocumentSnapshot>> grouped = {};

  for (var doc in docs) {
    final data = doc.data() as Map<String, dynamic>;
    final company = (data['supplier_name'] ?? 'Unknown').toString();

    if (!grouped.containsKey(company)) {
      grouped[company] = [];
    }

    grouped[company]!.add(doc);
  }

  return grouped.entries.map((e) {
    return CompanyModel(
      name: e.key,
      yarnDocs: e.value,
    );
  }).toList();
}