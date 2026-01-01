import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/yarn_service.dart';
import './yarn_detail_page.dart';
import './add_yarn_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanCodePage extends StatefulWidget {
  final String? expectedQr;
  final String? title;

  const ScanCodePage({super.key, this.expectedQr, this.title});

  @override
  State<ScanCodePage> createState() => _ScanCodePageState();
}

class _ScanCodePageState extends State<ScanCodePage> {
  String? scannedData;
  MobileScannerController? controller;
  bool isScanning = true;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _handleScan(BarcodeCapture capture) async {
    if (!isScanning || isLoading) return;

    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    final value = rawValue.trim();

    setState(() {
      scannedData = value;
      isScanning = false;
      isLoading = true;
    });

    controller?.stop();

    // Verification Mode
    if (widget.expectedQr != null) {
      if (value == widget.expectedQr) {
        // Match!
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification Successful!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true for success
      } else {
        // Mismatch!
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: QR Mismatch! Expected ${widget.expectedQr}, but got $value'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        _scanNext(); // Restart scanning
      }
      return;
    }

    // Default Search Mode
    try {
      final yarnService = YarnService();
      final doc = await yarnService.getYarn(value);

      if (!mounted) return;

      if (doc.exists) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => YarnDetailPage(
              qr: value,
              data: doc.data() as Map<String, dynamic>,
            ),
          ),
        ).then((_) => _scanNext());
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddYarnPage(qr: value)),
        ).then((_) => _scanNext());
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
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
          _buildScannerOverlay(context),

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
                Text(
                  widget.title ?? 'Scan Yarn QR',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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
                      'Checking Yarn Database...',
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
