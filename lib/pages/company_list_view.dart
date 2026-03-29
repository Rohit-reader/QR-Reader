import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/group_by_company.dart';
import './company_yarn_list_page.dart';
import '../model/company_model.dart';

class CompanyListView extends StatefulWidget {
  final List<QueryDocumentSnapshot> docs;
  final String searchQuery;
  final bool showIconBackground;

  const CompanyListView({
    super.key,
    required this.docs,
    required this.searchQuery,
    this.showIconBackground = true,
  });

  @override
  State<CompanyListView> createState() => _CompanyListViewState();
}

class _CompanyListViewState extends State<CompanyListView> {

  String _sortOption = 'name_asc';

  // ✅ SORT FUNCTION (FIX: USE COPY TO TRIGGER UI UPDATE)
  List<CompanyModel> _sortCompanies(List<CompanyModel> companies) {

    List<CompanyModel> sortedList = List.from(companies); // 🔥 IMPORTANT FIX

    sortedList.sort((a, b) {

      DateTime getLatestDate(CompanyModel c) {
        DateTime latest = DateTime(2000);

        for (var doc in c.yarnDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final raw = data['created_at'] ?? data['timestamp'];

          if (raw is Timestamp) {
            final date = raw.toDate();
            if (date.isAfter(latest)) {
              latest = date;
            }
          }
        }
        return latest;
      }

      switch (_sortOption) {
        case 'date_desc':
          return getLatestDate(b).compareTo(getLatestDate(a));

        case 'date_asc':
          return getLatestDate(a).compareTo(getLatestDate(b));

        case 'name_desc':
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());

        case 'count_asc':
          return a.count.compareTo(b.count);

        case 'count_desc':
          return b.count.compareTo(a.count);

        case 'name_asc':
        default:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });

    return sortedList; // ✅ RETURN NEW LIST
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.green.shade700;

    var companies = groupByCompany(widget.docs)
        .where((c) =>
        c.name.toLowerCase().contains(widget.searchQuery.toLowerCase()))
        .toList();

    // ✅ APPLY SORT (WORKS CORRECTLY NOW)
    companies = _sortCompanies(companies);

    if (companies.isEmpty) {
      return const Center(child: Text("No Companies Found"));
    }

    return Column(
      children: [

        // ✅ SORT BUTTON (UNCHANGED UI)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          alignment: Alignment.centerRight,
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.black),
            onSelected: (val) {
              setState(() {
                _sortOption = val; // ✅ triggers rebuild
              });
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'name_asc', child: Text("Name ↑")),
              PopupMenuItem(value: 'name_desc', child: Text("Name ↓")),
              PopupMenuItem(value: 'count_asc', child: Text("Count ↑")),
              PopupMenuItem(value: 'count_desc', child: Text("Count ↓")),
              PopupMenuItem(value: 'date_desc', child: Text("Date ↓")),
              PopupMenuItem(value: 'date_asc', child: Text("Date ↑")),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: companies.length,
            itemBuilder: (_, index) {
              final company = companies[index];

              return InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CompanyYarnListPage(
                        companyName: company.name,
                        docs: company.yarnDocs,
                      ),
                    ),
                  );
                },

                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),

                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFFFFFF),
                        Color(0xFFF1F8E9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Row(
                    children: [

                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.business, color: primaryColor),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              company.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Yarn Supplier",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          "${company.count}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.blueAccent,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}