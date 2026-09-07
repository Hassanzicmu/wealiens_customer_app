import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'home_page.dart';
import 'models/customer_profile.dart';
import 'widgets/app_sidebar.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _authService = AuthService();
  Map<String, dynamic>? _currentUser;
  CustomerProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final user = await _authService.getStoredCustomer();
    if (mounted) setState(() => _currentUser = user);
    await _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    if (mounted) setState(() => _isLoading = true);
    final profile = await _authService.getProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => HomePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppSidebar(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Image.asset(
          'assets/img/logo-wealiens-copyright.png',
          height: 30,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Text(
              'HELLO, ${(_currentUser?['name'] ?? 'CUSTOMER').toString().toUpperCase()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _currentUser?['email'] ?? '',
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 32),

            // Stats Grid
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                : GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildStatCard(
                        'Active Projects',
                        (_profile?.statistics.totalProjects ?? 0).toString(),
                        Icons.rocket_launch,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Support Tickets',
                        (_profile?.statistics.totalTickets ?? 0).toString(),
                        Icons.confirmation_number,
                        Colors.orange,
                      ),
                      _buildStatCard('Pending Tasks', '12', Icons.list_alt, Colors.purple),
                      _buildStatCard('Total Hours', '128', Icons.timer, Colors.green),
                    ],
                  ),

            const SizedBox(height: 32),

            // Recent Activity
            const Text(
              'RECENT ACTIVITY',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.blue))
            else if (_profile?.recentActivity.latestProject != null)
              _buildActivityItem(
                'Latest Project: "${_profile!.recentActivity.latestProject!.title}"',
                'Started on ${_profile!.recentActivity.latestProject!.startDate.toString().split(' ').first}',
              )
            else
              const Text('No recent activity found', style: TextStyle(color: Colors.grey)),
            
            const SizedBox(height: 12),
            _buildActivityItem('Invoiced #2024-001 has been paid', 'Yesterday'),
            _buildActivityItem('Support ticket #443 closed', '3 days ago'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131A33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A33),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 8, color: Color(0xFF00E5FF)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 4),
                Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
