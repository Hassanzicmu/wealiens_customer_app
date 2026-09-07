import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/services_service.dart';
import '../home_page.dart';
import '../dashboard_page.dart';
import '../projects_page.dart';
import '../tickets_page.dart';
import '../profile_page.dart';
import '../login_page.dart';

class AppSidebar extends StatefulWidget {
  const AppSidebar({super.key});

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar> {
  final _authService = AuthService();
  final _servicesService = ServicesService();
  Map<String, dynamic>? _currentUser;
  List<dynamic> _parentCategories = [];
  bool _isCategoriesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _authService.getStoredCustomer();
    if (mounted) setState(() => _currentUser = user);

    try {
      final categories = await _servicesService.getCategoriesTree();
      if (mounted) {
        setState(() {
          _parentCategories = categories;
          _isCategoriesLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isCategoriesLoading = false);
    }

    // Refresh user from API
    final freshUser = await _authService.getCurrentUser();
    if (freshUser != null) {
      if (mounted) setState(() => _currentUser = freshUser);
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0B1021),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF131A33),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/img/logo-wealiens-copyright.png',
                  height: 50,
                  width: 50,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.business, color: Color(0xFF00E5FF)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        (_currentUser?['name'] ?? 'WE ALIENS').toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        (_currentUser?['email'] ?? 'Digital Marketing Agency').toString(),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.home_outlined, 'Home', () {
            Navigator.pop(context);
            if (ModalRoute.of(context)?.settings.name != '/') {
               Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
            }
          }),
          if (_currentUser != null)
            _buildDrawerItem(Icons.dashboard_outlined, 'Dashboard', () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardPage()),
              );
            }),
          if (_currentUser != null)
            _buildDrawerItem(Icons.rocket_launch_outlined, 'My Projects', () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProjectsPage()),
              );
            }),
          if (_currentUser != null)
            _buildDrawerItem(Icons.confirmation_number_outlined, 'My Tickets', () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const TicketsPage()),
              );
            }),
          if (_currentUser != null)
            _buildDrawerItem(Icons.person_outline, 'Profile', () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            }),
          const Divider(color: Colors.white10),
          _buildDrawerItem(Icons.info_outline, 'About Us', () {
            Navigator.pop(context);
          }),
          const Divider(color: Colors.white10),
          if (_currentUser == null)
            _buildDrawerItem(Icons.login_outlined, 'Login', () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            })
          else
            _buildDrawerItem(Icons.logout_outlined, 'Logout', _logout),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70, size: 22),
      title: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      onTap: onTap,
    );
  }
}
