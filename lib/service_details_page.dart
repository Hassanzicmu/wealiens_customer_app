import 'package:flutter/material.dart';
import 'services/services_service.dart';
import 'contact_us_page.dart';

class ServiceDetailsPage extends StatefulWidget {
  final Map<String, dynamic> service;

  const ServiceDetailsPage({super.key, required this.service});

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  final _servicesService = ServicesService();
  Map<String, dynamic>? _details;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final categoryId = widget.service['id'];
      final details = await _servicesService.getServiceDetailByCategory(categoryId);
      if (mounted) {
        setState(() {
          _details = details;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading service details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _stripHtml(String? htmlString) {
    if (htmlString == null || htmlString.isEmpty) return '';
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').trim();
  }

  String _getText(dynamic item, String key) {
    if (item == null || item is! Map) return '';
    
    if (item['${key}_text'] != null) {
      return _stripHtml(item['${key}_text'].toString());
    }
    
    final data = item[key];
    if (data is Map) {
      final text = data['en'] ?? data['ar'] ?? (data.values.isNotEmpty ? data.values.first : '');
      return _stripHtml(text.toString());
    }
    
    if (data is String) {
      return _stripHtml(data);
    }
    
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_details == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              const Text('Details are being updated by the team.',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Go Back'),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Section
                  _buildSectionHeader('info_title_text', 'ABOUT THIS SERVICE', [const Color(0xFF00E5FF), const Color(0xFF2962FF)]),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Text(
                      _stripHtml(_details?['info_description_text'] ?? _details?['info_description']?['en']),
                      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Benefits Section
                  if (_details?['benefits'] != null && (_details?['benefits'] as List).isNotEmpty)
                    _buildListSection(
                      titleKey: 'benefit_title',
                      defaultTitle: 'BENEFITS',
                      descriptionKey: 'benefit_description',
                      items: _details?['benefits'] as List,
                      icon: Icons.auto_awesome,
                      itemKey: 'title',
                      itemDescKey: 'description',
                      colors: [Colors.greenAccent, Colors.teal],
                    ),

                  // Processes Section
                  if (_details?['processes'] != null && (_details?['processes'] as List).isNotEmpty)
                    _buildListSection(
                      titleKey: 'process_title',
                      defaultTitle: 'OUR PROCESS',
                      descriptionKey: 'process_description',
                      items: _details?['processes'] as List,
                      icon: Icons.bolt,
                      itemKey: 'title',
                      colors: [Colors.blueAccent, Colors.indigo],
                    ),

                  // Trends Section
                  if (_details?['trends'] != null && (_details?['trends'] as List).isNotEmpty)
                    _buildListSection(
                      titleKey: 'trend_title',
                      defaultTitle: 'LATEST TRENDS',
                      descriptionKey: 'trend_description',
                      imageUrlKey: 'trend_image_url',
                      items: _details?['trends'] as List,
                      icon: Icons.trending_up,
                      itemKey: 'title',
                      colors: [Colors.pinkAccent, Colors.purple],
                    ),

                  // Why Us Section
                  if (_details?['why_us_items'] != null && (_details?['why_us_items'] as List).isNotEmpty)
                    _buildListSection(
                      titleKey: 'why_us_title',
                      defaultTitle: 'WHY CHOOSE US',
                      descriptionKey: 'why_us_description',
                      imageUrlKey: 'why_us_image_url',
                      items: _details?['why_us_items'] as List,
                      icon: Icons.star_rounded,
                      itemKey: 'title',
                      colors: [Colors.orangeAccent, Colors.deepOrange],
                    ),

                  const SizedBox(height: 50),
                  _buildCTAButton(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    final String imageUrl = ServicesService.normalizeUrl(_details?['info_image_url'] ?? widget.service['logo_url']);
    final String title = widget.service['name_text'] ?? widget.service['name']?['en'] ?? 'Service';

    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      backgroundColor: Colors.black,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Image.asset(
          'assets/img/logo-wealiens-copyright.png',
          height: 30,
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, e, s) => Container(color: const Color(0xFF131A33)),
              )
            else
              Container(color: const Color(0xFF131A33)),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String titleKey, String defaultTitle, List<Color> colors) {
    final String title = _getText(_details, titleKey.replaceAll('_text', '')) ?? defaultTitle;
    return Row(
      children: [
        Container(
          width: 5,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: colors,
            ),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: colors[0].withOpacity(0.5),
                blurRadius: 8,
                spreadRadius: 1,
              )
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title.isEmpty ? defaultTitle.toUpperCase() : title.toUpperCase(),
            style: TextStyle(
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: colors,
                ).createShader(const Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildListSection({
    required String titleKey,
    required String defaultTitle,
    required String descriptionKey,
    required List items,
    required IconData icon,
    required String itemKey,
    String? itemDescKey,
    String? imageUrlKey,
    required List<Color> colors,
  }) {
    final String? sectionImageUrlRaw = (imageUrlKey != null && _details != null)
        ? _details![imageUrlKey] as String?
        : null;
    final String sectionImageUrl = ServicesService.normalizeUrl(sectionImageUrlRaw);
    final String description = _getText(_details, descriptionKey.replaceAll('_text', ''));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(titleKey, defaultTitle, colors),
        if (description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
          ),
        ],
        const SizedBox(height: 20),
        if (sectionImageUrl != null && sectionImageUrl.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colors[0].withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: -5,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                sectionImageUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (context, e, s) => const SizedBox.shrink(),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        ...items.map((item) {
          final title = _getText(item, itemKey);
          final subDesc = itemDescKey != null ? _getText(item, itemDescKey) : '';
          
          if (title.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors[0].withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors[0].withOpacity(0.1)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors[0].withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: colors[0], size: 20),
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
                          fontSize: 15,
                          height: 1.4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (subDesc.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          subDesc,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCTAButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF00E5FF), Color(0xFF2962FF)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          final String title = widget.service['name_text'] ?? widget.service['name']?['en'] ?? '';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ContactUsPage(initialSubject: 'Inquiry about $title'),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text(
          'BOOK AN APPOINTMENT',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
