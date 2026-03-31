import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/yarn_service.dart';
import './reserved_yarn_details_page.dart';
import './verify_qr_page.dart';

class CompanyYarnListPage extends StatefulWidget {
  final String companyName;
  final List<QueryDocumentSnapshot> docs;

  const CompanyYarnListPage({
    super.key,
    required this.companyName,
    required this.docs,
  });

  @override
  State<CompanyYarnListPage> createState() => _CompanyYarnListPageState();
}

class _CompanyYarnListPageState extends State<CompanyYarnListPage>
    with SingleTickerProviderStateMixin {
  final YarnService yarnService = YarnService();
  late AnimationController _controller;
  String? _ackMessage;

  // ✅ LOCAL CACHE (to track verified scans locally)
  final Map<String, bool> _localScanState = {};

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ✅ CONFIRM DELETE FUNCTION
  Future<bool> _confirmDelete(BuildContext context, String yarnId) async {
    final controller = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Confirm Delete",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text("Yarn ID: $yarnId",
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: "Type Yarn ID to confirm",
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Color(0xFFF5F5F5),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(false),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Colors.orange, Colors.deepOrange]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text("Cancel",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (controller.text.trim() == yarnId) {
                          Navigator.of(context).pop(true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Yarn ID does not match!")),
                          );
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Colors.red, Colors.redAccent]),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text("Delete",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.green;
    _controller.forward(from: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(widget.companyName),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: widget.docs.length,
            itemBuilder: (context, index) {
              final doc = widget.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              final yarnId = data['id'] ?? data['yarnId'] ?? doc.id;
              final supplier = data['supplier_name'] ?? 'Unknown';

              final state = data['state'] ?? 'RESERVED';
              final isVerified = state == 'VERIFIED';
              final isScanned =
              state == 'VERIFIED'
                  ? true // Treat as verified, not scanned locally
                  : _localScanState[doc.id] ?? (data['is_scanned'] ?? false);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Dismissible(
                  key: ValueKey(doc.id),
                  background: _swipeLeft(),
                  secondaryBackground: _swipeRight(),
                  confirmDismiss: (direction) async {
                    // 👉 SCAN / VERIFY (left swipe)
                    if (direction == DismissDirection.startToEnd) {
                      if (isVerified || isScanned) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Already Scanned")),
                        );
                        return false;
                      }

                      final alreadyScanned =
                      await yarnService.isAlreadyScanned(doc.id);

                      if (alreadyScanned) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Already Scanned")),
                        );
                        return false;
                      }

                      final scan = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => VerifyQRPage(
                            expectedQr: yarnId.toString(),
                            yarnId: yarnId.toString(),
                          ),
                        ),
                      );

                      if (scan == true) {
                        await yarnService.markAsVerified(doc.id);
                        setState(() {
                          _localScanState[doc.id] = true;
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Scanned Successfully")),
                        );
                      }

                      return false;
                    }
                    // 👉 DELETE (right swipe)
                    else {
                      // Only allow deletion after confirmation
                      final confirmed = await _confirmDelete(context, yarnId.toString());

                      if (confirmed) {
                        // Delete yarn from Firestore, regardless of verified/reserved
                        await yarnService.deleteReservedYarnById(doc.id);
                        setState(() {
                          _ackMessage = "Deleted $yarnId";
                        });
                      }
                      return false; // return false so Dismissible does NOT remove item locally
                    }
                  },
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReservedYarnDetailsPage(
                            docId: doc.id,
                            data: data,
                          ),
                        ),
                      );
                    },
                    child: Opacity(
                      opacity: isVerified || isScanned ? 0.6 : 1,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isVerified || isScanned
                              ? Border.all(color: Colors.blue)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (isVerified || isScanned)
                                    ? Colors.blue.withOpacity(0.1)
                                    : primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.inventory_2,
                                color: (isVerified || isScanned) ? Colors.blue : primaryColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    yarnId.toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    supplier,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: (isVerified || isScanned)
                                    ? Colors.blue.withOpacity(0.15)
                                    : Colors.grey.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                (isVerified || isScanned) ? "SCANNED" : "RESERVED",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: (isVerified || isScanned) ? Colors.blue : Colors.green,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (_ackMessage != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        _ackMessage!,
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.w600),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          setState(() {
                            _ackMessage = null;
                          });
                        },
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _swipeLeft() => Container(
    alignment: Alignment.centerLeft,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      gradient:
      const LinearGradient(colors: [Colors.green, Colors.greenAccent]),
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Icon(Icons.qr_code, color: Colors.white),
  );

  Widget _swipeRight() => Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    decoration: BoxDecoration(
      color: Colors.redAccent,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Icon(Icons.delete, color: Colors.white),
  );
}