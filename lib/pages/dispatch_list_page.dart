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
        centerTitle: true,
        title: const Text('Move Yarn (Dispatch)'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: yarnService.getMovedYarns(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No Yarn Ready for Dispatch',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    textAlign: TextAlign.center,
                    'All items have been dispatched or none are ready.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final yarnId = data['id'] ?? data['yarnId'] ?? data['ID'] ?? doc.id;
              final qrCode = data['qrCode'] ?? data['qr'] ?? data['QR'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.local_shipping, size: 32, color: Colors.teal),
                              const SizedBox(width: 15),
                              Text(
                                '$yarnId',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 24,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 25),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final scanSuccess = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ScanCodePage(
                                      expectedQr: yarnId.toString(),
                                      title: 'Verify Dispatch - $yarnId',
                                    ),
                                  ),
                                );

                                if (scanSuccess == true) {
                                  if (!context.mounted) return;
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Confirm Dispatch'),
                                      content: Text('Final step: Dispatch Yarn $yarnId?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                          child: const Text('CONFIRM'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true) {
                                    await yarnService.updateYarnStatus(doc.id, 'dispatched');
                                  }
                                }
                              },
                              icon: const Icon(Icons.local_shipping),
                              label: const Text('VERIFY & DISPATCH'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
