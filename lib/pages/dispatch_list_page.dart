import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/yarn_service.dart';
import './qr_code.dart';

class DispatchListPage extends StatelessWidget {
  const DispatchListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final yarnService = YarnService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Move Yarn (Dispatch)'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: yarnService.getMovedYarns(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text('No yarn ready for dispatch.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final yarnId = data['id'] ?? 'Unknown ID';
              final qrCode = data['qrCode'] ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  title: Text(
                    'Yarn ID: $yarnId',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: const Padding(
                    padding: EdgeInsets.only(top: 4.0),
                    child: Text('Ready for Dispatch'),
                  ),
                  trailing: const Icon(Icons.check_circle_outline, color: Colors.green),
                  onTap: () async {
                    final success = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScanCodePage(
                          expectedQr: qrCode,
                          title: 'Verify Dispatch - Scan $yarnId',
                        ),
                      ),
                    );

                    if (success == true) {
                      await yarnService.updateYarnStatus(doc.id, 'dispatched');
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
