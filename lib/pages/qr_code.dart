import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanCodePage extends StatefulWidget {
  const ScanCodePage({super.key});

  @override
  State<ScanCodePage> createState() => _ScanCodePageState();
}

class _ScanCodePageState extends State<ScanCodePage> {
  String? scannedData;
  MobileScannerController? controller;
  bool isScanning = true;

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

  void _handleScan(BarcodeCapture capture) {
    if (!isScanning) return;
    final value = capture.barcodes.first.rawValue;
    if (value != null) {
      setState(() {
        scannedData = value;
        isScanning = false;
      });
      controller?.stop();
    }
  }

  void _scanNext() {
    setState(() {
      scannedData = null;
      isScanning = true;
    });
    controller?.start();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanAreaSize = 220.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('QR Scanner'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Camera + overlay
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Full camera preview
                MobileScanner(
                  controller: controller!,
                  onDetect: _handleScan,
                ),

                // Dark overlay with transparent center
                Container(
                  color: Colors.black.withOpacity(0.5),
                ),

                // Scanning box
                Container(
                  width: scanAreaSize,
                  height: scanAreaSize,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.greenAccent,
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),

                // Instruction text
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Text(
                    isScanning
                        ? 'Align QR code within the box'
                        : 'Scan successful',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Result panel
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: scannedData == null
                  ? const Center(
                child: Text(
                  'Ready to scan',
                  style: TextStyle(fontSize: 16),
                ),
              )
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scanned Data',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    scannedData!,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _scanNext,
                      child: const Text('Scan Another QR'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
