import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'services/auth_service.dart';
import 'models/ticket.dart';

class TicketDetailsPage extends StatefulWidget {
  final int ticketId;
  const TicketDetailsPage({super.key, required this.ticketId});

  @override
  State<TicketDetailsPage> createState() => _TicketDetailsPageState();
}

class _TicketDetailsPageState extends State<TicketDetailsPage> {
  final _authService = AuthService();
  final _replyController = TextEditingController();
  Ticket? _ticket;
  bool _isLoading = true;
  bool _isSending = false;
  File? _replyAttachment;

  Future<void> _pickReplyFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _replyAttachment = File(result.files.single.path!);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _authService.getTicketDetails(widget.ticketId),
        _authService.getTicketComments(widget.ticketId),
      ]);

      if (mounted) {
        final ticket = results[0] as Ticket?;
        final comments = results[1] as List<TicketReply>;

        setState(() {
          if (ticket != null) {
            _ticket = Ticket(
              id: ticket.id,
              customerProjectId: ticket.customerProjectId,
              title: ticket.title,
              description: ticket.description,
              status: ticket.status,
              attachmentUrl: ticket.attachmentUrl,
              createdAt: ticket.createdAt,
              updatedAt: ticket.updatedAt,
              replies: comments.isNotEmpty ? comments : ticket.replies,
            );
          } else {
            _ticket = null;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendReply() async {
    if (_replyController.text.trim().isEmpty) return;

    if (mounted) setState(() => _isSending = true);
    final success = await _authService.replyToTicket(
      ticketId: widget.ticketId,
      replyText: _replyController.text.trim(),
      attachment: _replyAttachment,
    );

    if (mounted) {
      setState(() => _isSending = false);
      if (success) {
        _replyController.clear();
        setState(() => _replyAttachment = null);
        _fetchDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send reply')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Image.asset(
          'assets/img/logo-wealiens-copyright.png',
          height: 30,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E5FF)))
          : _ticket == null
              ? const Center(child: Text('Ticket not found', style: TextStyle(color: Colors.white)))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          _buildOriginalMessage(),
                          const SizedBox(height: 24),
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 24),
                          ...(_ticket!.replies.map((reply) => _buildReplyItem(reply))),
                        ],
                      ),
                    ),
                    _buildReplyInput(),
                  ],
                ),
    );
  }

  Widget _buildOriginalMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('ORIGINAL MESSAGE',
                style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.bold, fontSize: 12)),
            Text(_ticket!.createdAt.toString().split('.').first,
                style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF00E5FF).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _ticket!.description,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
          ),
        ),
        if (_ticket!.attachmentUrl != null) ...[
          const SizedBox(height: 12),
          _buildAttachmentButton(_ticket!.attachmentUrl!),
        ],
      ],
    );
  }

  Widget _buildReplyItem(TicketReply reply) {
    final isCustomer = reply.isCustomerReply;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: isCustomer ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isCustomer ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                isCustomer ? 'YOU' : 'SUPPORT TEAM',
                style: TextStyle(
                  color: isCustomer ? const Color(0xFF00E5FF) : Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                reply.createdAt.toString().split('.').first,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isCustomer ? const Color(0xFF1D284C) : const Color(0xFF131A33),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isCustomer ? 12 : 0),
                bottomRight: Radius.circular(isCustomer ? 0 : 12),
              ),
              border: Border.all(
                color: isCustomer ? const Color(0xFF00E5FF).withOpacity(0.3) : Colors.cyan.withOpacity(0.3),
              ),
            ),
            child: Text(
              reply.replyText,
              style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
            ),
          ),
          if (reply.attachmentUrl != null) ...[
            const SizedBox(height: 8),
            _buildAttachmentButton(reply.attachmentUrl!),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentButton(String url) {
    return InkWell(
      onTap: () async {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open attachment')),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.attach_file, color: Colors.grey, size: 14),
            SizedBox(width: 8),
            Text('View Attachment', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1021),
        border: Border(top: BorderSide(color: const Color(0xFF00E5FF).withOpacity(0.1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_replyAttachment != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, color: Color(0xFF00E5FF), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _replyAttachment!.path.split('/').last,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 16, color: Color(0xFF00E5FF)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _replyAttachment = null),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              IconButton(
                onPressed: _pickReplyFile,
                icon: const Icon(Icons.attach_file, color: Colors.grey),
              ),
              Expanded(
                child: TextField(
                  controller: _replyController,
                  maxLines: null,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Type your reply...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    fillColor: const Color(0xFF131A33),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _isSending
                  ? const CircularProgressIndicator(color: Color(0xFF00E5FF))
                  : IconButton(
                      onPressed: _sendReply,
                      icon: const Icon(Icons.send, color: Color(0xFF00E5FF)),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}
