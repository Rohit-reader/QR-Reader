import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/yarn_service.dart';
import './company_list_view.dart';
import './yarn_id_list_view.dart';

class ReservedListPage extends StatefulWidget {
  const ReservedListPage({super.key});

  @override
  State<ReservedListPage> createState() => _ReservedListPageState();
}

class _ReservedListPageState extends State<ReservedListPage> {
  final YarnService yarnService = YarnService();

  bool _isCompanyView = true;
  String _searchQuery = '';
  String _sortOption = 'id_asc';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          _isCompanyView ? "Companies" : "Reserved Yarns",
          style: const TextStyle(color: Colors.black),
        ),

        actions: !_isCompanyView
            ? [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.black),
            onSelected: (val) => setState(() => _sortOption = val),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'id_asc', child: Text("ID ↑")),
              PopupMenuItem(value: 'id_desc', child: Text("ID ↓")),
              PopupMenuItem(value: 'supplier_asc', child: Text("Supplier ↑")),
              PopupMenuItem(value: 'supplier_desc', child: Text("Supplier ↓")),
              PopupMenuItem(value: 'date_desc', child: Text("Date ↓")),
              PopupMenuItem(value: 'date_asc', child: Text("Date ↑")),
            ],
          )
        ]
            : [],
      ),

      body: Column(
        children: [

          // SEARCH BAR WITHOUT GREEN SHADE
          Padding(
            padding: const EdgeInsets.all(16),
            child: _searchBar(),
          ),

          // TOGGLE BUTTON
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _toggle(),
          ),

          const SizedBox(height: 10),

          // MAIN LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: yarnService.getReservedYarns(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (_isCompanyView) {
                  return CompanyListView(
                    docs: docs,
                    searchQuery: _searchQuery,
                    // Remove green shade in items
                    showIconBackground: false,
                  );
                } else {
                  return YarnIdListView(
                    docs: docs,
                    searchQuery: _searchQuery,
                    sortOption: _sortOption,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // SEARCH BAR WITHOUT GREEN SHADES
  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Removed gradient
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: TextField(
        decoration: const InputDecoration(
          hintText: "Search..",
          prefixIcon: Icon(Icons.search, color: Colors.black54),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  // TOGGLE BUTTON (UNCHANGED)
  Widget _toggle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        return Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.grey.shade200,
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                alignment: _isCompanyView
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  width: width / 2,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 12,
                      )
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _toggleItem("Company", true),
                  _toggleItem("IDs", false),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  Widget _toggleItem(String text, bool isCompany) {
    final selected = _isCompanyView == isCompany;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isCompanyView = isCompany),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(
              color: selected ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: selected ? 16 : 14,
            ),
            child: Text(text),
          ),
        ),
      ),
    );
  }
}