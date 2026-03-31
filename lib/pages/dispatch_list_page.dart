import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DispatchListPage extends StatefulWidget {
  const DispatchListPage({super.key});

  @override
  State<DispatchListPage> createState() => _DispatchListPageState();
}

class _DispatchListPageState extends State<DispatchListPage>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;

  String _searchQuery = '';

  // ✅ SORT OPTION
  String _sortOption = 'date_desc';

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> getDispatchedYarns() {
    return FirebaseFirestore.instance
        .collection('reserved_collection')
        .snapshots();
  }

  // ✅ SORT FUNCTION
  List<QueryDocumentSnapshot> _sortDocs(List<QueryDocumentSnapshot> docs) {
    docs.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;

      final idA = (dataA['id'] ?? dataA['yarnId'] ?? a.id).toString();
      final idB = (dataB['id'] ?? dataB['yarnId'] ?? b.id).toString();

      final supplierA = (dataA['supplier_name'] ?? '').toString();
      final supplierB = (dataB['supplier_name'] ?? '').toString();

      final rawA = dataA['created_at'] ?? dataA['timestamp'];
      final rawB = dataB['created_at'] ?? dataB['timestamp'];

      DateTime dateA = rawA is Timestamp ? rawA.toDate() : DateTime(2000);
      DateTime dateB = rawB is Timestamp ? rawB.toDate() : DateTime(2000);

      switch (_sortOption) {

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
    final primaryColor = Colors.orange.shade600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Dispatched Yarns',
          style: TextStyle(color: Colors.black),
        ),

        // ✅ SORT BUTTON (ONLY ADDITION)
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort, color: Colors.black),
            color: Colors.white,
            onSelected: (value) {
              setState(() {
                _sortOption = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'date_desc', child: Text('Date ↓ (Newest)')),
              const PopupMenuItem(
                  value: 'date_asc', child: Text('Date ↑ (Oldest)')),
              const PopupMenuItem(
                  value: 'id_asc', child: Text('ID ↑')),
              const PopupMenuItem(
                  value: 'id_desc', child: Text('ID ↓')),
              const PopupMenuItem(
                  value: 'supplier_asc', child: Text('Supplier ↑')),
              const PopupMenuItem(
                  value: 'supplier_desc', child: Text('Supplier ↓')),
            ],
          )
        ],
      ),

      body: Column(
        children: [

          // 🔍 SEARCH BAR (UNCHANGED)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search Yarn ID...',
                  prefixIcon: Icon(Icons.search, color: primaryColor),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() => _searchQuery = '');
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim();
                  });
                },
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getDispatchedYarns(),
              builder: (context, snapshot) {

                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (!snapshot.hasData) {
                  return const Center(
                      child: Text("No data found"));
                }

                var docs = snapshot.data!.docs;

                // ✅ FILTER
                docs = docs.where((doc) {
                  final data =
                  doc.data() as Map<String, dynamic>;

                  final state = (data['state'] ??
                      data['status'] ??
                      data['yarn_status'] ??
                      '')
                      .toString()
                      .toLowerCase();

                  return state == 'dispatched';
                }).toList();

                // 🔍 SEARCH
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data =
                    doc.data() as Map<String, dynamic>;

                    final yarnId =
                    (data['id'] ??
                        data['yarnId'] ??
                        doc.id)
                        .toString()
                        .toLowerCase();

                    return yarnId.contains(
                        _searchQuery.toLowerCase());
                  }).toList();
                }

                // ✅ APPLY SORT
                docs = _sortDocs(docs);

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.local_shipping_outlined,
                          size: 70,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 10),
                        const Text("No Dispatched Yarn"),
                      ],
                    ),
                  );
                }

                if (!_controller.isAnimating) {
                  _controller.forward(from: 0);
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {

                    final doc = docs[index];
                    final data =
                    doc.data() as Map<String, dynamic>;

                    final yarnId =
                        data['id'] ?? data['yarnId'] ?? doc.id;

                    final supplier =
                        data['supplier_name'] ?? 'Unknown';

                    final animation =
                    Tween<double>(begin: 0, end: 1)
                        .animate(
                      CurvedAnimation(
                        parent: _controller,
                        curve: Interval(
                          (index / docs.length) * 0.7,
                          1,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    );

                    return FadeTransition(
                      opacity: animation,
                      child: Transform.translate(
                        offset:
                        Offset(0, 20 * (1 - animation.value)),
                        child: Transform.scale(
                          scale:
                          0.95 + (0.05 * animation.value),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Colors.white,
                                  Color(0xFFF9FAFB)
                                ],
                              ),
                              borderRadius:
                              BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.04),
                                  blurRadius: 10,
                                  offset:
                                  const Offset(0, 6),
                                )
                              ],
                            ),
                            child: Row(
                              children: [

                                Container(
                                  padding:
                                  const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: primaryColor
                                        .withOpacity(0.1),
                                    borderRadius:
                                    BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.local_shipping,
                                    color: primaryColor,
                                  ),
                                ),

                                const SizedBox(width: 16),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        yarnId.toString(),
                                        style:
                                        const TextStyle(
                                          fontWeight:
                                          FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        supplier,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                          Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.orange
                                        .withOpacity(0.15),
                                    borderRadius:
                                    BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    "DISPATCHED",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight:
                                      FontWeight.w600,
                                      color: Colors.orange,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}