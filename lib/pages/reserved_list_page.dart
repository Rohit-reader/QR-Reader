import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/yarn_service.dart';
import './qr_code.dart';

class ReservedListPage extends StatelessWidget {
  const ReservedListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final yarnService = YarnService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reserved Yarn (Move)'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: yarnService.getReservedYarns(),
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
              child: Text('No reserved yarn found.'),
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
              final location = data['location'] ?? 'Unknown Location';

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
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text('Location: $location'),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final success = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScanCodePage(
                          expectedQr: qrCode,
                          title: 'Verify Move - Scan $yarnId',
                        ),
                      ),
                    );

                    if (success == true) {
                      await yarnService.updateYarnStatus(doc.id, 'moved');
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
