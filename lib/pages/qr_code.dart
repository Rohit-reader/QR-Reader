import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/yarn_service.dart';
import './yarn_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanCodePage extends StatefulWidget {
  final String? expectedQr;
  final String? title;
  final bool isAddMode;

  const ScanCodePage({
    super.key,
    this.expectedQr,
    this.title,
    this.isAddMode = false,
  });

  @override
  State<ScanCodePage> createState() => _ScanCodePageState();
}

class _ScanCodePageState extends State<ScanCodePage> {
  String? scannedData;
  MobileScannerController? controller;
  bool isScanning = true;
  bool isLoading = false;
  Map<String, dynamic>? pendingData;
  String? pendingQr;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: true, // Enable image capture for QR storage
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _handleScan(BarcodeCapture capture) async {
    if (!isScanning || isLoading || pendingData != null) return;

    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    final value = rawValue.trim();
    final qrImage = capture.image; // Capture QR image

    setState(() {
      isLoading = true;
    });

    try {
      final yarnService = YarnService();
      Map<String, dynamic> data;

      if (widget.isAddMode) {
        data = yarnService.parseYarnData(value);
        // Store QR image as base64 if available
        if (qrImage != null) {
          data['qrImage'] = Blob(qrImage);
        }
      } else {
        final doc = await yarnService.findYarnByContent(value);
        if (doc != null && doc.exists) {
          data = doc.data() as Map<String, dynamic>;
        } else {
          data = yarnService.parseYarnData(value);
          // Flag it as not found if searching
          if (widget.expectedQr != null || !widget.isAddMode) {
             data['notFound'] = true;
          }
        }
      }

      setState(() {
        pendingData = data;
        pendingQr = value;
        isScanning = false;
        isLoading = false;
      });
      controller?.stop();
    } catch (e) {
      debugPrint('Error parsing scan: $e');
      setState(() => isLoading = false);
    }
  }

  void _confirmAction() async {
    if (pendingData == null || pendingQr == null) return;

    setState(() => isLoading = true);

    try {
      final yarnService = YarnService();
      final value = pendingQr!;
      final data = pendingData!;

      // 1. Verification Mode
      if (widget.expectedQr != null) {
        String clean(String? s) => (s ?? '').trim().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
        final String target = clean(widget.expectedQr);
        final String scanned = clean(value);
        
        bool matched = scanned.contains(target);
        if (!matched) {
          final fields = data.values.map((v) => clean(v.toString())).toList();
          final docIdClean = clean(data['id']?.toString() ?? '');
          if (fields.any((f) => f.contains(target)) || docIdClean.contains(target)) {
            matched = true;
          }
        }

        if (matched) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yarn Verified!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true);
          return;
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yarn not same'), backgroundColor: Colors.red),
          );
          _resetScan();
          return;
        }
      }

      // 2. Add Mode
      if (widget.isAddMode) {
        // Prepare data for addition
        final transformedData = Map<String, dynamic>.from(data);
        
        // Set state to "IN STOCK"
        transformedData['state'] = 'IN STOCK';
        
        // Remove isTest key
        transformedData.remove('isTest');
        
        // Change lot number from test lot to date-based lot number
        String? lotKey;
        // Find any key that contains "lot" (case-insensitive)
        for (final key in transformedData.keys) {
          if (key.toLowerCase().contains('lot')) {
            lotKey = key;
            break;
          }
        }

        if (lotKey != null) {
          final currentLot = transformedData[lotKey]?.toString().toLowerCase() ?? '';
          if (currentLot.contains('test')) {
             // Generate new lot number: LOT-YYYYMMDD-XXX format
            final now = DateTime.now();
            final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
            final seqNum = now.millisecondsSinceEpoch.toString().substring(10); // Last 3 digits
            transformedData[lotKey] = 'LOT-$dateStr-$seqNum';
          }
        }
        
        // Set order_id to "ORD-NONE"
        transformedData['order_id'] = 'ORD-NONE';
        
        await yarnService.addYarn(value, transformedData);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yarn ${transformedData['id'] ?? ''} added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        return;
      }

      // 3. Search Mode
      if (data['notFound'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yarn not found in database'), backgroundColor: Colors.red),
        );
        _resetScan();
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => YarnDetailPage(qr: value, data: data),
          ),
        ).then((_) => _resetScan());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _resetScan() {
    setState(() {
      pendingData = null;
      pendingQr = null;
      isScanning = true;
    });
    controller?.start();
  }

  void _scanNext() {
    if (!mounted) return;
    setState(() {
      scannedData = null;
      isScanning = true;
      isLoading = false;
    });
    controller?.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          MobileScanner(
            controller: controller!,
            onDetect: _handleScan,
          ),

          // Custom Glassmorphism-style Overlay
          if (pendingData == null) _buildScannerOverlay(context),

          // Top Header
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black26,
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.title ?? 'Scan Yarn QR',
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => controller?.toggleTorch(),
                  icon: const Icon(Icons.flashlight_on, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black26,
                  ),
                ),
              ],
            ),
          ),

          // Scanned Data Preview Overlay
          if (pendingData != null) _buildDataPreview(context),

          // Loading Indicator
          if (isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Processing...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataPreview(BuildContext context) {
    final data = pendingData!;
    final isNotFound = data['notFound'] == true;
    final yarnId = data['id'] ?? 'Unknown ID';
    
    String confirmMsg = 'Proceed with action?';
    if (widget.isAddMode) confirmMsg = 'Add this yarn to inventory?';
    else if (widget.expectedQr != null) confirmMsg = 'Confirm verification?';
    else confirmMsg = 'View details?';

    return Container(
      color: Colors.black87,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(color: Colors.white.withOpacity(0.1), blurRadius: 20),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      isNotFound ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                      size: 64,
                      color: isNotFound ? Colors.orange : Colors.deepPurple,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      yarnId,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isNotFound ? 'New Yarn detected' : 'Existing Yarn found',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const Divider(height: 32),
                    Table(
                      columnWidths: const {
                        0: IntrinsicColumnWidth(),
                        1: FlexColumnWidth(),
                      },
                      children: data.entries
                          .where((e) => !['notFound', 'status', 'createdAt', 'rawQr', 'id', 'qrimage'].contains(e.key.toLowerCase()))
                          .where((e) => e.value.toString().toLowerCase() != 'unknown') // Filter out unknown values
                          .map((e) => TableRow(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 8, right: 16),
                                child: Text(
                                  _capitalize(e.key),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  e.value.toString(),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ))
                          .toList(),
                    ),
                    
                    if (widget.isAddMode) ...[
                      const Divider(height: 32),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.deepPurple.shade200),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'Assigned ID:',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.deepPurple),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Auto-Generated (YR-XXXXX)',
                                textAlign: TextAlign.right,
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    Text(
                      confirmMsg,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _resetScan,
                            child: const Text('RE-SCAN', style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _confirmAction,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isNotFound && !widget.isAddMode ? Colors.grey : Colors.deepPurple,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(isNotFound && !widget.isAddMode ? 'NOT FOUND' : 'CONFIRM'),
                          ),
                        ),
                      ],
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

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s.replaceAll('_', ' ').split(' ').map((str) => str.isNotEmpty ? '${str[0].toUpperCase()}${str.substring(1)}' : '').join(' ');
  }

  Widget _buildScannerOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanAreaSize = size.width * 0.7;

    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withOpacity(0.5),
        BlendMode.srcOut,
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.transparent,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              height: scanAreaSize,
              width: scanAreaSize,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          // Corners
          Align(
            alignment: Alignment.center,
            child: Container(
              height: scanAreaSize,
              width: scanAreaSize,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
