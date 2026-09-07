import 'package:flutter/material.dart';
import 'login_page.dart';
import 'dashboard_page.dart';
import 'services/auth_service.dart';
import 'services/services_service.dart';
import 'services_page.dart';
import 'profile_page.dart';
import 'projects_page.dart';
import 'tickets_page.dart';
import 'widgets/app_sidebar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    await Future.wait([
      _loadUser(),
      _loadCategories(),
    ]);
  }

  Future<void> _loadUser() async {
    final user = await _authService.getStoredCustomer();
    if (user != null) {
      if (mounted) setState(() => _currentUser = user);
    }
    // Optionally refresh from API
    final freshUser = await _authService.getCurrentUser();
    if (freshUser != null) {
      if (mounted) setState(() => _currentUser = freshUser);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _servicesService.getCategoriesTree();
      if (mounted) {
        setState(() {
          _parentCategories = categories;
          _isCategoriesLoading = false;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      if (mounted) {
        setState(() => _isCategoriesLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      setState(() => _currentUser = null);
      Navigator.pop(context); // Close drawer
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Image.asset(
          'assets/img/logo-wealiens-copyright.png',
          height: 30,
        ),
      ),
      drawer: const AppSidebar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            Container(
              height: 400,
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0B1021), Color(0xFF131A33)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentUser != null 
                      ? 'WELCOME\n${(_currentUser?['name'] ?? '').toString().toUpperCase()}' 
                      : 'WE ALIENS\nAGENCY',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Leading Digital Marketing & Software House.\nWe build the future of your business.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
            
            // Dynamic Services Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'OUR SERVICES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isCategoriesLoading)
                    const Center(child: CircularProgressIndicator(color: Colors.white))
                  else if (_parentCategories.isEmpty)
                    const Text('No services available at the moment.', style: TextStyle(color: Colors.grey))
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _parentCategories.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final category = _parentCategories[index];
                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ServicesPage(parentCategory: category),
                              ),
                            );
                          },
                          child: _buildServiceCard(
                            ServicesService.normalizeUrl(category['logo_url'] ?? ''),
                            category['name_text'] ?? category['name']['en'] ?? 'Service',
                            category['description_text'] ?? category['description']['en'] ?? '',
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white70)),
      onTap: onTap,
    );
  }

  Widget _buildServiceCard(String logoUrl, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF131A33),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: logoUrl.isNotEmpty
                  ? Image.network(
                      logoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.work_outline, color: Color(0xFF00E5FF)),
                    )
                  : const Icon(Icons.work_outline, color: Color(0xFF00E5FF)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }
}
