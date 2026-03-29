import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';
import 'passenger_home.dart';
import 'driver_home.dart';
import 'admin_home.dart';

class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  final AuthService _authService = AuthService();
  Future<UserModel?>? _userFuture;
  String? _lastUid;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.userStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFFAFAFC), 
            body: Center(child: CircularProgressIndicator())
          );
        }

        final user = snapshot.data;
        if (user != null) {
          // Cache the future so it doesn't refetch and flash UI on every rebuild
          if (_userFuture == null || _lastUid != user.uid) {
            _lastUid = user.uid;
            _userFuture = _authService.getUserData(user.uid);
          }

          return FutureBuilder<UserModel?>(
            future: _userFuture,
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFFFAFAFC), 
                  body: Center(child: CircularProgressIndicator())
                );
              }
              
              if (roleSnapshot.hasData && roleSnapshot.data != null) {
                switch (roleSnapshot.data!.role) {
                  case 'driver':
                    return const DriverHome();
                  case 'admin':
                    return const AdminHome();
                  case 'passenger':
                  default:
                    return const PassengerHome();
                }
              }
              
              // No user doc found
              return Scaffold(
                backgroundColor: const Color(0xFFFAFAFC),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      const Text(
                        'Profile Not Found',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Your account exists, but no role profile was found in the database. Please contact your administrator or create a new account via the Signup page.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          _userFuture = null;
                          _lastUid = null;
                          _authService.signOut();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0052D4),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: const Text('Sign Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        }

        // Not authenticated
        return const LoginScreen();
      },
    );
  }
}
