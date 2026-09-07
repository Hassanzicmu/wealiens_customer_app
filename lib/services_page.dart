import 'package:flutter/material.dart';
import 'service_details_page.dart';
import 'services/services_service.dart';

class ServicesPage extends StatelessWidget {
  final Map<String, dynamic> parentCategory;

  const ServicesPage({super.key, required this.parentCategory});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> children = parentCategory['children'] ?? [];
    final String title = parentCategory['name_text'] ?? parentCategory['name']['en'] ?? 'Services';

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
        centerTitle: true,
      ),
      body: children.isEmpty
          ? const Center(
              child: Text(
                'No sub-services found for this category.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: children.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final child = children[index];
                return _buildServiceCard(context, child);
              },
            ),
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> service) {
    final String logoUrl = ServicesService.normalizeUrl(service['logo_url'] ?? '');
    final String title = service['name_text'] ?? service['name']['en'] ?? 'Service';
    final String description = service['description_text'] ?? service['description']['en'] ?? '';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceDetailsPage(service: service),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF131A33),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF00E5FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: logoUrl.isNotEmpty
                    ? Image.network(
                        logoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.miscellaneous_services, color: Colors.white),
                      )
                    : const Icon(Icons.miscellaneous_services, color: Colors.white),
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
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
