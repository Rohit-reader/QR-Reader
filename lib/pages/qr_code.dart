import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './yarn_detail_page.dart';

class ScanCodePage extends StatefulWidget {
  final String? expectedQr;
  final bool isAddMode;
  final String? title;

  const ScanCodePage({
    super.key,
    this.expectedQr,
    this.isAddMode = false,
    this.title,
  });

  @override
  State<ScanCodePage> createState() => _ScanCodePageState();
}

class _ScanCodePageState extends State<ScanCodePage>
    with SingleTickerProviderStateMixin {
  MobileScannerController? controller;
  bool isScanning = true;
  bool isLoading = false;
  String? scannedQr;

  late AnimationController animationController;
  late Animation<double> laserAnimation;
  Timer? idleTimer;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      returnImage: false,
    );

    // Animation for scanning laser
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: false);

    laserAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: animationController, curve: Curves.linear),
    );

    _startIdleTimer();
  }

  void _startIdleTimer() {
    idleTimer?.cancel();
    idleTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    animationController.dispose();
    idleTimer?.cancel();
    super.dispose();
  }

  // 🔥 UPDATE FIRESTORE AFTER SCAN
  Future<void> _markAsScanned(String qr) async {
    final query = await FirebaseFirestore.instance
        .collection('reserved_collection')
        .where('id', isEqualTo: qr)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final docRef = query.docs.first.reference;
      await docRef.update({
        'state': 'VERIFIED',
        'is_scanned': true,
        'verified_at': FieldValue.serverTimestamp(),
        'last_state_change': FieldValue.serverTimestamp(),
      });
    }
  }

  void _handleScan(BarcodeCapture capture) async {
    if (!isScanning || isLoading) return;

    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    idleTimer?.cancel();

    setState(() {
      scannedQr = rawValue.trim();
      isScanning = false;
      isLoading = true; // show loader during Firestore update
    });
    controller?.stop();

    // 🔥 Firestore update
    await _markAsScanned(scannedQr!);

    setState(() {
      isLoading = false;
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => YarnDataPage(
          qr: scannedQr!,
          expectedQr: widget.expectedQr,
          isAddMode: widget.isAddMode,
        ),
      ),
    ).then((_) {
      setState(() {
        scannedQr = null;
        isScanning = true;
      });
      controller?.start();
      _startIdleTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanAreaSize = size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          MobileScanner(
            controller: controller!,
            onDetect: _handleScan,
          ),
          _buildScannerOverlay(context),
          Center(
            child: SizedBox(
              height: scanAreaSize,
              width: scanAreaSize,
              child: AnimatedBuilder(
                animation: laserAnimation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _LaserPainter(progress: laserAnimation.value),
                  );
                },
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.white70,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.orange),
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
        Colors.white.withOpacity(0.5),
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LaserPainter extends CustomPainter {
  final double progress;

  _LaserPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent.withOpacity(0.7)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final y = size.height * progress;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant _LaserPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}