import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'models/ticket.dart';
import 'ticket_details_page.dart';
import 'create_ticket_page.dart';
import 'widgets/app_sidebar.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  final _authService = AuthService();
  List<Ticket> _tickets = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  Future<void> _fetchTickets({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      if (mounted) setState(() => _isLoading = true);
    }

    final paginated = await _authService.getTickets(page: _currentPage);
    if (mounted) {
      setState(() {
        if (refresh) {
          _tickets = paginated?.tickets ?? [];
        } else {
          _tickets.addAll(paginated?.tickets ?? []);
        }
        _hasMore = (paginated?.currentPage ?? 1) < (paginated?.lastPage ?? 1);
        _isLoading = false;
      });
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
      body: _isLoading && _tickets.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
          : _tickets.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => _fetchTickets(refresh: true),
                  color: const Color(0xFF00E5FF),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24.0),
                    itemCount: _tickets.length + (_hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _tickets.length) {
                        _currentPage++;
                        _fetchTickets();
                        return const Center(
                            child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                        ));
                      }
                      final ticket = _tickets[index];
                      return _buildTicketCard(ticket);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateTicketPage()),
          );
          if (result == true) {
            _fetchTickets(refresh: true);
          }
        },
        backgroundColor: const Color(0xFF00E5FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.confirmation_number_outlined,
              size: 64, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'NO TICKETS FOUND',
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Need help? Create a support ticket.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateTicketPage()),
              );
              if (result == true) {
                _fetchTickets(refresh: true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E5FF)),
            child: const Text('CREATE TICKET', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Ticket ticket) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF131A33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00E5FF).withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketDetailsPage(ticketId: ticket.id),
            ),
          );
        },
        title: Row(
          children: [
            Expanded(
              child: Text(
                ticket.title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            _buildStatusBadge(ticket.status),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.grey, size: 14),
                const SizedBox(width: 4),
                Text(
                  ticket.createdAt.toString().split('.').first,
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
                const Spacer(),
                if (ticket.attachmentUrl != null) ...[
                  const Icon(Icons.attach_file, color: Color(0xFF00E5FF), size: 14),
                  const SizedBox(width: 12),
                ],
                const Icon(Icons.comment_outlined, color: Color(0xFF00E5FF), size: 14),
                const SizedBox(width: 4),
                Text(
                  '${ticket.repliesCount}',
                  style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'open':
        color = Colors.green;
        break;
      case 'closed':
        color = Colors.red;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      default:
        color = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
