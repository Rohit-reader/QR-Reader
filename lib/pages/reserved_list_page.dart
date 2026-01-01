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

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return StreamBuilder<QuerySnapshot>(
              stream: yarnService.getAnyReserved(),
              builder: (ctx, anySnapshot) {
                final anyDocs = anySnapshot.data?.docs ?? [];
                
                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        const Text(
                          'No Reserved Yarn Found',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Checking "reserved_collection" for "reserved" or "RESERVED" state.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 32),
                        if (anyDocs.isNotEmpty) ...[
                          const Divider(),
                          const SizedBox(height: 16),
                          Text(
                            'Found ${anyDocs.length} document(s) in collection.',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          const Text('Actual data in Firestore:', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ...anyDocs.take(5).map((d) {
                            final data = d.data() as Map<String, dynamic>;
                            // Try to find state in any casing
                            final stateKey = data.keys.firstWhere((k) => k.toLowerCase() == 'state', orElse: () => '');
                            final s = stateKey.isNotEmpty ? data[stateKey] : 'null (Field "state" not found!)';
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.withOpacity(0.2)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ID: ${d.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  Text('STATE FIELD: "$stateKey"', style: const TextStyle(color: Colors.blue, fontSize: 11)),
                                  Text('STATE VALUE: "$s"', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                                  Text('ALL KEYS: ${data.keys.join(", ")}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            'TIP: The app is looking for "RESERVED" in the "state" field.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              }
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
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code, size: 32, color: Theme.of(context).primaryColor),
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
                                      title: 'Verify Move - $yarnId',
                                    ),
                                  ),
                                );

                                if (scanSuccess == true) {
                                  if (!context.mounted) return;
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Confirm Move'),
                                      content: Text('Move Yarn $yarnId to Floor?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                                        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('CONFIRM')),
                                      ],
                                    ),
                                  );

                                  if (confirmed == true) {
                                    await yarnService.updateYarnStatus(doc.id, 'moved');
                                  }
                                }
                              },
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('SCAN & VERIFY MOVE'),
                              style: ElevatedButton.styleFrom(
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
