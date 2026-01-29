import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/yarn_service.dart';

class YarnDetailPage extends StatelessWidget {
  final String qr;
  final Map<String, dynamic> data;

  const YarnDetailPage({super.key, required this.qr, required this.data});

  @override
  Widget build(BuildContext context) {
    final yarnId = data['id'] ?? data['yarnId'] ?? data['ID'] ?? 'N/A';
    
    return SafeArea(child: Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Inventory Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF673AB7),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with Gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple.shade300, const Color(0xFF673AB7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.inventory_2, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    yarnId.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'VERIFIED ITEM',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            
            // QR Code Image Section
            if (data['qrImage'] != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Builder(
                  builder: (context) {
                    try {
                      final dynamic imgData = data['qrImage'];
                      Uint8List? bytes;
                      
                      if (imgData is Blob) {
                        bytes = imgData.bytes;
                      } else if (imgData is Uint8List) {
                        bytes = imgData;
                      } else if (imgData is List<int>) {
                        bytes = Uint8List.fromList(imgData);
                      }

                      if (bytes != null) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            bytes,
                            width: 150,
                            height: 150,
                            fit: BoxFit.cover,
                          ),
                        );
                      }
                      return const SizedBox();
                    } catch (e) {
                      return const Icon(Icons.broken_image, size: 50, color: Colors.grey);
                    }
                  },
                ),
              ),
            ],


            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Specifications'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildInfoCard('Material', data['material']?.toString() ?? 'N/A', Icons.texture)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildInfoCard('Type', data['type']?.toString() ?? 'N/A', Icons.category)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Warehouse Location'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildLocationItem('Bin', data['bin']?.toString() ?? '-', Icons.grid_view_rounded),
                        Container(height: 40, width: 1, color: Colors.deepPurple.shade50),
                        _buildLocationItem('Rack', data['rack']?.toString() ?? '-', Icons.layers_outlined),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('BACK TO SCANNER', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                        side: BorderSide(color: Colors.deepPurple.shade200),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.deepPurple.shade300,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurple, size: 28),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(color: Colors.deepPurple.shade300, fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Colors.deepPurple.shade900,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurple.shade400, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: Colors.deepPurple.shade300, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: Colors.deepPurple.shade900, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
