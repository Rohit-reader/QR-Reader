import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerifyQRPage extends StatefulWidget {
  final String expectedQr; // expected QR (yarn ID)
  final String yarnId; // yarn ID for title & verification

  const VerifyQRPage({
    super.key,
    required this.expectedQr,
    required this.yarnId,
  });

  @override
  State<VerifyQRPage> createState() => _VerifyQRPageState();
}

class _VerifyQRPageState extends State<VerifyQRPage>
    with SingleTickerProviderStateMixin {
  MobileScannerController? controller;
  bool isScanning = true;
  Timer? idleTimer;

  late AnimationController animationController;
  late Animation<double> laserAnimation;

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
      if (mounted) Navigator.pop(context, false); // return false if idle
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    animationController.dispose();
    idleTimer?.cancel();
    super.dispose();
  }

  /// ✅ Custom styled SnackBar (like YarnDataPage)
  void _showAckSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        content: Row(
          children: [
            Image.asset(
              'assets/icon/app_icon.png', // your app icon
              height: 24,
              width: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Firestore verification logic (update state, keep ID)
  Future<void> _verifyAndUpdate(String qrId) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('reserved_collection')
          .where('id', isEqualTo: qrId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (mounted) _showAckSnackBar('Yarn not found for scanned QR: $qrId');
        return;
      }

      final doc = query.docs.first;
      final data = doc.data();

      // Safe null-aware field access
      final state = (data['state'] ?? 'RESERVED').toString();
      final isAlreadyScanned = (data['is_scanned'] ?? false) as bool;

      if (state == 'VERIFIED' || isAlreadyScanned) {
        if (mounted) _showAckSnackBar('Yarn already scanned');
        return;
      }

      // ✅ Update Firestore: keep the ID, mark as VERIFIED
      await doc.reference.update({
        'state': 'VERIFIED',
        'is_scanned': true,
        'verified_at': FieldValue.serverTimestamp(),
        'last_state_change': FieldValue.serverTimestamp(),
      });

      if (mounted) _showAckSnackBar('Yarn scanned successfully');
    } catch (_) {
      if (mounted) _showAckSnackBar('Yarn scanning completed');
    }
  }

  // Handle scanning barcode
  void _handleScan(BarcodeCapture capture) async {
    if (!isScanning) return;

    final rawValue = capture.barcodes.first.rawValue;
    if (rawValue == null || rawValue.trim().isEmpty) return;

    idleTimer?.cancel();

    String scannedId = rawValue.trim();

    // Parse JSON if QR contains JSON
    try {
      final decoded = json.decode(rawValue);
      if (decoded is Map && decoded.containsKey('id')) {
        scannedId = decoded['id'].toString().trim();
      }
    } catch (_) {
      // Not JSON, leave as rawValue
    }

    final expectedId = widget.expectedQr.trim();

    if (scannedId != expectedId) {
      _showAckSnackBar(
        'QR does not match expected Yarn ID\nScanned: $scannedId\nExpected: $expectedId',
      );
      _startIdleTimer();
      return;
    }

    // ✅ Stop scanning to prevent duplicates
    setState(() {
      isScanning = false;
    });
    controller?.stop();

    // Show acknowledgment
    _showAckSnackBar('QR matched! Scanning...');

    // Update Firestore: mark verified
    await _verifyAndUpdate(scannedId);

    // Return to previous page
    if (mounted) Navigator.pop(context, true);
  }

  /// ✅ Left swipe update logic: mark verified without deleting ID
  Future<void> updateOnLeftSwipe(String qrId) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('reserved_collection')
          .where('id', isEqualTo: qrId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return;

      final doc = query.docs.first;
      final data = doc.data();

      final state = (data['state'] ?? 'RESERVED').toString();
      final isAlreadyScanned = (data['is_scanned'] ?? false) as bool;

      if (state == 'VERIFIED' || isAlreadyScanned) {
        _showAckSnackBar('Yarn already scanned');
        return;
      }

      await doc.reference.update({
        'state': 'VERIFIED',
        'is_scanned': true,
        'verified_at': FieldValue.serverTimestamp(),
        'last_state_change': FieldValue.serverTimestamp(),
      });

      _showAckSnackBar('Yarn scanned successfully via swipe');
    } catch (_) {
      _showAckSnackBar('Yarn scanning completed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanAreaSize = size.width * 0.7;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Scan - ${widget.yarnId}'),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller!,
            onDetect: _handleScan,
          ),
          _buildScannerOverlay(context, scanAreaSize),
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
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context, double scanAreaSize) {
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
      ..color = Colors.green.withOpacity(0.7)
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