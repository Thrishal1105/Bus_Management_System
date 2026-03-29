import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin_dashboard_tab.dart';
import 'admin_add_driver_tab.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    AdminDashboardTab(),
    AdminAddDriverTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFC),
      appBar: AppBar(
        title: const Text('Admin Console', style: TextStyle(color: Color(0xFF0052D4), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.blueGrey),
            onPressed: () => AuthService().signOut(),
          )
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20)],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF0052D4),
          unselectedItemColor: Colors.blueGrey.shade300,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          items: [
            _buildNavItem(Icons.dashboard_outlined, Icons.dashboard, 'Overview', 0),
            _buildNavItem(Icons.person_add_outlined, Icons.person_add, 'Add Driver', 1),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(IconData unselected, IconData selected, String label, int index) {
    return BottomNavigationBarItem(
      icon: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _currentIndex == index ? const Color(0xFF0052D4) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          _currentIndex == index ? selected : unselected,
          color: _currentIndex == index ? Colors.white : Colors.blueGrey.shade300,
        ),
      ),
      label: label,
    );
  }
}
