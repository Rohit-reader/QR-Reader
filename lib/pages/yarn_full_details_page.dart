import 'dart:ui';
import 'package:flutter/material.dart';

class YarnFullDetailsPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const YarnFullDetailsPage({
    super.key,
    required this.data,
  });

  @override
  State<YarnFullDetailsPage> createState() =>
      _YarnFullDetailsPageState();
}

class _YarnFullDetailsPageState extends State<YarnFullDetailsPage>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _scale = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
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

    // ✅ FIX: preserve order
    final orderedKeys = widget.data.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      body: SafeArea(
        minimum: const EdgeInsets.symmetric(vertical: 10),
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Column(
              children: [

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ScaleTransition(
                      scale: _scale,
                      child: Stack(
                        children: [

                          // 🔥 BACK LAYER
                          Positioned(
                            top: 12,
                            left: 12,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                          ),

                          // 🧾 MAIN CARD
                          ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.97),
                                  borderRadius: BorderRadius.circular(22),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    )
                                  ],
                                ),

                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [

                                    // 🏷 HEADER
                                    Text(
                                      "YARN DETAILS",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                        letterSpacing: 1,
                                      ),
                                    ),

                                    const SizedBox(height: 4),

                                    Text(
                                      "Details Summary",
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),

                                    const SizedBox(height: 12),
                                    Divider(),

                                    const SizedBox(height: 10),

                                    // 📊 DETAILS
                                    Expanded(
                                      child: ListView.builder(
                                        itemCount: orderedKeys.length,
                                        itemBuilder: (context, index) {
                                          final key = orderedKeys[index];
                                          final value = widget.data[key];

                                          return _invoiceRow(
                                            key.toString(),
                                            value.toString(),
                                          );
                                        },
                                      ),
                                    ),
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

              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🧾 ROW
  Widget _invoiceRow(String title, String value) {
    final isImportant = title.toLowerCase().contains("count") ||
        title.toLowerCase().contains("amount") ||
        title.toLowerCase().contains("total");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 5,
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: isImportant ? 15 : 14,
                    color: isImportant ? Colors.green.shade700 : Colors.black,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }
}