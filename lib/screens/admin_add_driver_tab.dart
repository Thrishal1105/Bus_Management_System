import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminAddDriverTab extends StatefulWidget {
  const AdminAddDriverTab({super.key});

  @override
  State<AdminAddDriverTab> createState() => _AdminAddDriverTabState();
}

class _AdminAddDriverTabState extends State<AdminAddDriverTab> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController(); // Used as temporary password or verification pin
  bool _isLoading = false;

  /// Converts raw Firebase error strings into clean, user-friendly messages.
  String _friendlyErrorMessage(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('email-already-in-use')) {
      return 'This email is already registered to another user.';
    } else if (lower.contains('weak-password')) {
      return 'The password is too weak. Please use at least 6 characters.';
    } else if (lower.contains('invalid-email')) {
      return 'The email address format is not valid.';
    } else if (lower.contains('network')) {
      return 'No internet connection detected.';
    }
    return 'Failed to add driver. Please try again.';
  }

  /// Shows a premium error popup with red icon and styled dismiss button.
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
              child: Icon(Icons.error_rounded, color: Colors.red.shade600, size: 48),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Try Again', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a premium success popup with green icon.
  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
              child: Icon(Icons.check_circle_rounded, color: Colors.green.shade600, size: 48),
            ),
            const SizedBox(height: 20),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052D4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('OK', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addDriver() async {
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showErrorDialog('Incomplete Form', 'Please provide a name, email, and password to register a new driver.');
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Use a secondary Firebase App instance to securely create the new user in Firebase Auth
      FirebaseApp app = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );
      
      try {
        UserCredential cred = await FirebaseAuth.instanceFor(app: app).createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Add the profile mapping to the primary Firestore Database
        await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
          'uid': cred.user!.uid,
          'role': 'driver',
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      } finally {
        await app.delete();
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();
        _showSuccessDialog(
          'Driver Registered!',
          'Driver account and profile secure in Firestore and Database successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(
          'Registration Error',
          _friendlyErrorMessage(e.toString()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('REGISTER NEW DRIVER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text('Add a new driver to the system registry. They will receive access to the Driver App.', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Driver Full Name'),
                _buildTextField(_nameController, Icons.person_outline, 'John Doe'),
                const SizedBox(height: 20),
                
                _buildLabel('Email Address'),
                _buildTextField(_emailController, Icons.mail_outline, 'driver@company.com', isEmail: true),
                const SizedBox(height: 20),
                
                _buildLabel('Password'),
                _buildTextField(_passwordController, Icons.lock_outline, 'securepassword123'),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addDriver,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0052D4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Add Driver Profile', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon, String hint, {bool isEmail = false}) {
    return TextField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: Colors.grey.shade500),
        filled: true,
        fillColor: const Color(0xFFF4F5FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
