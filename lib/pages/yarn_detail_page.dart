import 'package:flutter/material.dart';
import '../services/yarn_service.dart';

class YarnDetailPage extends StatelessWidget {
  final String qr;
  final Map<String, dynamic> data;

  const YarnDetailPage({super.key, required this.qr, required this.data});

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Pickup'),
        content: const Text('Are you sure you want to remove this yarn from inventory? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteYarn(context);
            },
            child: const Text('Confirm & Remove'),
          ),
        ],
      ),
    );
  }

  void _deleteYarn(BuildContext context) async {
    final yarnService = YarnService();
    try {
      await yarnService.deleteYarn(qr);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yarn removed from inventory')),
      );
      Navigator.pop(context); // Go back to scanner
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Yarn Details'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildQRInfoCard(),
            const SizedBox(height: 24),
            _buildDetailCard(
              title: 'Yarn Information',
              items: [
                _DetailItem(Icons.inventory_2, 'Material', data['material'] ?? 'N/A'),
                _DetailItem(Icons.category, 'Type', data['type'] ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailCard(
              title: 'Location',
              items: [
                _DetailItem(Icons.grid_view, 'Bin', data['bin'] ?? 'N/A'),
                _DetailItem(Icons.layers, 'Rack', data['rack'] ?? 'N/A'),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Inventory Pickup (Remove)'),
              onPressed: () => _confirmDelete(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: const EdgeInsets.symmetric(vertical: 20),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildQRInfoCard() {
    return Card(
      elevation: 0,
      color: Colors.deepPurple.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.qr_code_2, size: 40, color: Colors.deepPurple),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'QR Code Reference',
                    style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    qr,
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({required String title, required List<_DetailItem> items}) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 32),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      Icon(item.icon, size: 24, color: Colors.grey[600]),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          Text(
                            item.value,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _DetailItem {
  final IconData icon;
  final String label;
  final String value;
  _DetailItem(this.icon, this.label, this.value);
}
