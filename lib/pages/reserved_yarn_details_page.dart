import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/yarn_service.dart';
import './yarn_full_details_page.dart';

class ReservedYarnDetailsPage extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;

  const ReservedYarnDetailsPage({
    super.key,
    required this.docId,
    required this.data,
  });

  @override
  State<ReservedYarnDetailsPage> createState() =>
      _ReservedYarnDetailsPageState();
}

class _ReservedYarnDetailsPageState
    extends State<ReservedYarnDetailsPage>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.green.shade700;

    final yarnId =
        widget.data['id'] ?? widget.data['yarnId'] ?? widget.docId;
    final supplier = widget.data['supplier_name'] ?? 'N/A';
    final type = widget.data['yarn_type'] ?? 'N/A';
    final count = widget.data['yarn_count'] ?? 'N/A';
    final quality = widget.data['quality_grade'] ?? 'N/A';
    final bin = widget.data['bin'] ?? widget.data['bin_id'] ?? 'N/A';
    final rack = widget.data['rack_id'] ?? 'N/A';
    final weight = widget.data['weight']?.toString() ?? widget.data['net_weight']?.toString() ?? 'N/A';
    final orderId = widget.data['order_id'] ?? widget.data['orderId'] ?? 'N/A';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text("Reserved Yarn Details",
            style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),

      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Column(
            children: [
              const Spacer(),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _row("Yarn ID", yarnId.toString()),
                        _row("Supplier", supplier),
                        _row("Type", type),
                        _row("Count", count),
                        _row("Quality", quality),
                        _row("Bin", bin),
                        _row("Rack", rack),
                        _row("Weight", weight),
                        _row("Order ID", orderId.toString()),

                        const SizedBox(height: 10),
                        Divider(color: Colors.grey.shade200),

                        // 🔹 More Details Navigation
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => YarnFullDetailsPage(
                                    data: widget.data,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),
              // ✅ Dispatch button removed completely
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(title,
                style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(
            flex: 6,
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}