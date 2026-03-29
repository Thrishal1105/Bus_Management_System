import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class PassengerPassTab extends StatefulWidget {
  const PassengerPassTab({super.key});

  @override
  State<PassengerPassTab> createState() => _PassengerPassTabState();
}

class _PassengerPassTabState extends State<PassengerPassTab> {
  bool _provisioned = false;

  @override
  void initState() {
    super.initState();
    _ensurePassExists();
  }

  /// Auto-create a pass document in Firestore so the driver's scanner can validate it.
  Future<void> _ensurePassExists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final passRef = FirebaseFirestore.instance.collection('passes').doc(user.uid);
    final doc = await passRef.get();

    if (!doc.exists) {
      // First time opening the pass tab — provision a new active pass
      await passRef.set({
        'userId': user.uid,
        'status': 'active',
        'validUntil': Timestamp.fromDate(
          DateTime(DateTime.now().year + 1, 12, 31), // Valid until Dec 31 next year
        ),
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) setState(() => _provisioned = true);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    // For MVP reliability, we use the raw UID. This creates a simpler QR code
    // that is 3x faster to scan than a complex JSON string.
    final String passData = user?.uid ?? 'unknown';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.menu, color: Color(0xFF0052D4)), onPressed: () {}),
        title: const Text('Bus App', style: TextStyle(color: Color(0xFF0052D4), fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.logout, color: Colors.blueGrey), onPressed: () => AuthService().signOut()),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Digital Transit Pass', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 4),
            Text('Tap and hold to zoom QR code', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 32),
            
            // The main pass card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: const Color(0xFF0052D4), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.speed, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text('BUS APP', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0052D4), letterSpacing: 1.2)),
                        ],
                      ),
                      Text('ANNUAL PASS', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // QR Code Box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                          child: QrImageView(
                            data: passData, // The actual Firebase UID to be scanned by the driver
                            version: QrVersions.auto,
                            size: 160.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Text('Safe in work', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(20)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.qr_code_scanner, color: Color(0xFF0052D4), size: 18),
                        SizedBox(width: 8),
                        Text('Ready to scan', style: TextStyle(color: Color(0xFF0052D4), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Please present this screen to the driver.', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                  const SizedBox(height: 12),
                  
                  const Text('PASS ID', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text('#${passData.substring(0, 5).toUpperCase()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                  
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFF4F5FA), thickness: 2),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('EXPIRES ON', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Dec 31, ${DateTime.now().year + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

