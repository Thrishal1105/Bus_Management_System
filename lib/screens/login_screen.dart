import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  
  String _selectedRole = 'passenger';
  bool _isLoading = false;
  bool _obscurePassword = true;

  final Color _primaryBlue = const Color(0xFF0052D4);
  final Color _bgColor = const Color(0xFFFAFAFC);
  final Color _inputBackground = const Color(0xFFF4F5FA);

  /// Converts raw Firebase error strings into clean, user-friendly messages.
  String _friendlyErrorMessage(String error) {
    final lower = error.toLowerCase();
    if (lower.contains('invalid-credential') || lower.contains('wrong-password') || lower.contains('user-not-found')) {
      return 'Incorrect email or password.\nPlease check your credentials and try again.';
    } else if (lower.contains('invalid-email')) {
      return 'The email address is not valid.\nPlease enter a correct email.';
    } else if (lower.contains('user-disabled')) {
      return 'This account has been disabled.\nContact your administrator.';
    } else if (lower.contains('too-many-requests')) {
      return 'Too many failed attempts.\nPlease wait a moment and try again.';
    } else if (lower.contains('network')) {
      return 'No internet connection.\nPlease check your network and try again.';
    }
    return 'Something went wrong.\nPlease try again later.';
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
            // Red error circle
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_rounded, color: Colors.red.shade600, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
              textAlign: TextAlign.center,
            ),
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

  void _login() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.login(
        _emailController.text, 
        _passwordController.text
      );
      
      // Validate role before checking mounted state so stream navigation doesn't cancel it
      if (user != null && user.role != _selectedRole) {
        await _authService.signOut();
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorDialog(
            'Unauthorized Role',
            'You are registered as a "${user.role.toUpperCase()}", not a "${_selectedRole.toUpperCase()}".\n\nPlease select the correct role and try again.',
          );
        }
        return; // Stop execution
      }
      
      if (mounted) {
        setState(() => _isLoading = false);
        if (user == null) {
          _showErrorDialog(
            'Login Failed',
            'Incorrect email or password.\nPlease check your credentials and try again.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(
          'Login Failed',
          _friendlyErrorMessage(e.toString()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Logo
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _primaryBlue,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.directions_bus, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Bus Management System',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF153376),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Frictionless movement for everyone',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(height: 40),
              
              // Welcome Text
              const Text(
                'Welcome back',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Please enter your details to sign in.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 32),

              Text('SELECT ROLE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade400, fontSize: 12)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildRoleCard('passenger', Icons.person, 'PASSENGER'),
                  const SizedBox(width: 8),
                  _buildRoleCard('driver', Icons.directions_car, 'DRIVER'),
                  const SizedBox(width: 8),
                  _buildRoleCard('admin', Icons.admin_panel_settings, 'ADMIN'),
                ],
              ),
              const SizedBox(height: 32),

              // Email Input
              Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'alex@busapp.com',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.mail_outline, color: Colors.grey.shade500),
                  filled: true,
                  fillColor: _inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Password Input
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Password', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                  TextButton(
                    onPressed: () {},
                    child: Text('Forgot Password?', style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.w600)),
                  )
                ],
              ),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade500),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade500),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: _inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Login Button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 4,
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.white),
                        ],
                      ),
                ),
              ),
              const SizedBox(height: 30),
              
              const Divider(),
              const SizedBox(height: 20),
              
              // Register Prompt
              Center(
                child: Text('Don\'t have an account?', style: TextStyle(color: Colors.grey.shade700)),
              ),
              const SizedBox(height: 16),
              
              // Create Account Button
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _primaryBlue, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    'Create Account', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _primaryBlue)
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.help_outline, color: Colors.grey.shade500, size: 18),
                    const SizedBox(width: 4),
                    Text('NEED HELP?', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String roleValue, IconData icon, String label) {
    bool isSelected = _selectedRole == roleValue;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = roleValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? _primaryBlue : _inputBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.blueGrey, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.blueGrey,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
