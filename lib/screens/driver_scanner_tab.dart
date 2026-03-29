import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart' as intl;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DriverScannerTab extends StatefulWidget {
  const DriverScannerTab({super.key});

  @override
  State<DriverScannerTab> createState() => _DriverScannerTabState();
}

class _DriverScannerTabState extends State<DriverScannerTab> {
  final MobileScannerController _scannerController = MobileScannerController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isProcessing = false;
  String? _lastScanResult;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? code = barcodes.first.rawValue;
      if (code != null) {
        setState(() => _isProcessing = true);
        await _scannerController.stop(); // Pause scanning
        await _validatePass(code);
      }
    }
  }

  /// Smart Parser that handles JSON, raw text, and potential scan corruption.
  String? _smartParsePassId(String rawData) {
    if (rawData.isEmpty) return null;

    // 1. Try to parse as JSON first (Best practice)
    try {
      final Map<String, dynamic> data = jsonDecode(rawData);
      if (data.containsKey('passId')) {
        return data['passId'].toString().trim();
      }
    } catch (_) {}

    // 2. Fallback: Search for any 20+ char string containing typical UID chars
    // This handles cases where the scanner only reads part of the code
    final idMatch = RegExp(r'[a-zA-Z0-9_-]{20,}').firstMatch(rawData);
    if (idMatch != null) {
      return idMatch.group(0);
    }

    // 3. Last resort: Specific Regex for broken JSON keys
    final jsonMatch = RegExp(r'["'']passId["'']\s*:\s*["'']([^"'']+)["'']', caseSensitive: false).firstMatch(rawData);
    if (jsonMatch != null) {
      return jsonMatch.group(1);
    }

    return null;
  }

  Future<void> _validatePass(String scannedData) async {
    bool isValid = false;
    String message = '';
    String subMessage = ''; // NEW: For showing expiry date.
    
    try {
      final String? passId = _smartParsePassId(scannedData);

      if (passId == null || passId.isEmpty) {
        throw const FormatException("Unrecognized pass format");
      }

      final doc = await _firestore.collection('passes').doc(passId).get();
      
      if (doc.exists) {
        final passData = doc.data()!;
        final status = passData['status'];
        final validUntil = (passData['validUntil'] as Timestamp).toDate();
        final intl.DateFormat formatter = intl.DateFormat('MMM dd, yyyy');
        final String formattedDate = formatter.format(validUntil);

        if (status == 'active' && validUntil.isAfter(DateTime.now())) {
          isValid = true;
          message = 'Valid Pass';
          subMessage = 'Expires on: $formattedDate';
        } else if (status != 'active') {
          message = 'Inactive Pass';
          subMessage = 'This profile is currently restricted.';
        } else {
          message = 'Pass Expired';
          subMessage = 'Expired on: $formattedDate';
        }
      } else {
        message = 'Invalid Pass';
        subMessage = 'Profile not found in database.';
      }

      // Log the scan to database
      final driverId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      await _firestore.collection('scan_logs').add({
        'passId': passId ?? 'unknown',
        'driverId': driverId,
        'tripId': 'active_trip',
        'timestamp': FieldValue.serverTimestamp(),
        'status': isValid ? 'valid' : 'invalid',
        'rawScan': scannedData,
      });

    } catch (e) {
      message = 'Invalid Format';
      subMessage = 'This QR is not a recognized bus pass.';
    }

    // Show Result Dialog
    if (!mounted) return;
    setState(() => _lastScanResult = message);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isValid ? Colors.green.shade50 : Colors.red.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Icon(
          isValid ? Icons.check_circle : Icons.error,
          color: isValid ? Colors.green : Colors.red,
          size: 64,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (subMessage.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subMessage,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ]
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isProcessing = false;
                _lastScanResult = null;
              });
              _scannerController.start(); // Resume
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isValid ? Colors.green : Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('SCAN NEXT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          )
        ],
      )
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onDetect,
        ),

        // Custom Scanner Overlay Design
        Container(
          decoration: ShapeDecoration(
            shape: QrScannerOverlayShape(
              borderColor: Colors.lightGreenAccent,
              borderRadius: 20,
              borderLength: 40,
              borderWidth: 6,
              cutOutSize: MediaQuery.of(context).size.width * 0.7,
            ),
          ),
        ),

        // Controls on the right
        Positioned(
          right: 20,
          top: MediaQuery.of(context).size.height * 0.2,
          child: Column(
            children: [
              _buildControlButton(Icons.flashlight_on, () => _scannerController.toggleTorch()),
              const SizedBox(height: 16),
              _buildControlButton(Icons.cameraswitch, () => _scannerController.switchCamera()),
            ],
          ),
        ),

        // Bottom Info Pill
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                  child: const Icon(Icons.more_horiz, color: Colors.blueGrey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isProcessing ? 'Processing scan...' : 'Waiting for scan...',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        _isProcessing ? 'Please wait' : 'Hold steady for automatic detection',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (!_isProcessing)
                  const Icon(Icons.close, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}

// Custom painter for the nice QR cutout look with faded background
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double overlayColorOpacity;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.green,
    this.borderWidth = 3.0,
    this.overlayColorOpacity = 0.5,
    this.borderRadius = 10.0,
    this.borderLength = 20.0,
    this.cutOutSize = 250.0,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()..fillType = PathFillType.evenOdd;
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path()..addRect(rect);
    double cutOutOriginX = rect.center.dx - cutOutSize / 2;
    double cutOutOriginY = rect.center.dy - cutOutSize / 2 - 40; // Shifted up slightly
    
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(cutOutOriginX, cutOutOriginY, cutOutSize, cutOutSize),
      Radius.circular(borderRadius),
    ));
    path.fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(overlayColorOpacity)
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
      
    double cutOutOriginX = rect.center.dx - cutOutSize / 2;
    double cutOutOriginY = rect.center.dy - cutOutSize / 2 - 40;

    canvas.drawPath(getOuterPath(rect), backgroundPaint);
    
    // Draw the 4 corner borders
    canvas.drawLine(Offset(cutOutOriginX, cutOutOriginY + borderRadius), Offset(cutOutOriginX, cutOutOriginY + borderLength), borderPaint);
    canvas.drawLine(Offset(cutOutOriginX + borderRadius, cutOutOriginY), Offset(cutOutOriginX + borderLength, cutOutOriginY), borderPaint);
    canvas.drawArc(Rect.fromLTWH(cutOutOriginX, cutOutOriginY, borderRadius * 2, borderRadius * 2), 3.14, 1.57, false, borderPaint);

    canvas.drawLine(Offset(cutOutOriginX + cutOutSize, cutOutOriginY + borderRadius), Offset(cutOutOriginX + cutOutSize, cutOutOriginY + borderLength), borderPaint);
    canvas.drawLine(Offset(cutOutOriginX + cutOutSize - borderRadius, cutOutOriginY), Offset(cutOutOriginX + cutOutSize - borderLength, cutOutOriginY), borderPaint);
    canvas.drawArc(Rect.fromLTWH(cutOutOriginX + cutOutSize - borderRadius * 2, cutOutOriginY, borderRadius * 2, borderRadius * 2), 4.71, 1.57, false, borderPaint);

    canvas.drawLine(Offset(cutOutOriginX, cutOutOriginY + cutOutSize - borderRadius), Offset(cutOutOriginX, cutOutOriginY + cutOutSize - borderLength), borderPaint);
    canvas.drawLine(Offset(cutOutOriginX + borderRadius, cutOutOriginY + cutOutSize), Offset(cutOutOriginX + borderLength, cutOutOriginY + cutOutSize), borderPaint);
    canvas.drawArc(Rect.fromLTWH(cutOutOriginX, cutOutOriginY + cutOutSize - borderRadius * 2, borderRadius * 2, borderRadius * 2), 1.57, 1.57, false, borderPaint);

    canvas.drawLine(Offset(cutOutOriginX + cutOutSize, cutOutOriginY + cutOutSize - borderRadius), Offset(cutOutOriginX + cutOutSize, cutOutOriginY + cutOutSize - borderLength), borderPaint);
    canvas.drawLine(Offset(cutOutOriginX + cutOutSize - borderRadius, cutOutOriginY + cutOutSize), Offset(cutOutOriginX + cutOutSize - borderLength, cutOutOriginY + cutOutSize), borderPaint);
    canvas.drawArc(Rect.fromLTWH(cutOutOriginX + cutOutSize - borderRadius * 2, cutOutOriginY + cutOutSize - borderRadius * 2, borderRadius * 2, borderRadius * 2), 0, 1.57, false, borderPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}
