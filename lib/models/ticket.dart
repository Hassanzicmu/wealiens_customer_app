import 'dart:convert';

class Ticket {
  final int id;
  final int customerProjectId;
  final String title;
  final String description;
  final String status;
  final String? attachmentUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<TicketReply> replies;
  final int repliesCount;

  Ticket({
    required this.id,
    required this.customerProjectId,
    required this.title,
    required this.description,
    required this.status,
    this.attachmentUrl,
    required this.createdAt,
    required this.updatedAt,
    this.replies = const [],
    this.repliesCount = 0,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
        id: json["id"] is int ? json["id"] : int.tryParse(json["id"].toString()) ?? 0,
        customerProjectId: json["customer_project_id"] is int 
            ? json["customer_project_id"] 
            : int.tryParse(json["customer_project_id"].toString()) ?? 0,
        title: json["title"] ?? "Untitled Ticket",
        description: json["description"] ?? "",
        status: json["status"] ?? "open",
        attachmentUrl: json["attachment_url"],
        createdAt: json["created_at"] != null
            ? DateTime.tryParse(json["created_at"]) ?? DateTime.now()
            : DateTime.now(),
        updatedAt: json["updated_at"] != null
            ? DateTime.tryParse(json["updated_at"]) ?? DateTime.now()
            : DateTime.now(),
        replies: json["replies"] != null
            ? List<TicketReply>.from(
                json["replies"].map((x) => TicketReply.fromJson(x)))
            : [],
        repliesCount: json["replies_count"] is int 
            ? json["replies_count"] 
            : int.tryParse(json["replies_count"]?.toString() ?? "0") ?? 0,
      );
}

class TicketReply {
  final int id;
  final int ticketId;
  final String? userId; // For staff
  final String? customerId;
  final String replyText;
  final String? attachmentUrl;
  final DateTime createdAt;

  TicketReply({
    required this.id,
    required this.ticketId,
    this.userId,
    this.customerId,
    required this.replyText,
    this.attachmentUrl,
    required this.createdAt,
  });

  factory TicketReply.fromJson(Map<String, dynamic> json) => TicketReply(
        id: json["id"] is int ? json["id"] : int.tryParse(json["id"].toString()) ?? 0,
        ticketId: json["ticket_id"] is int ? json["ticket_id"] : int.tryParse(json["ticket_id"].toString()) ?? 0,
        userId: json["user_id"]?.toString(),
        customerId: json["customer_id"]?.toString(),
        replyText: json["reply_text"] ?? "",
        attachmentUrl: json["attachment_url"],
        createdAt: json["created_at"] != null
            ? DateTime.tryParse(json["created_at"]) ?? DateTime.now()
            : DateTime.now(),
      );

  bool get isCustomerReply => customerId != null;
}

class PaginatedTickets {
  final List<Ticket> tickets;
  final int currentPage;
  final int lastPage;
  final int total;

  PaginatedTickets({
    required this.tickets,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  factory PaginatedTickets.fromJson(Map<String, dynamic> json) {
    // 1. Identify where the pagination data lives
    Map<String, dynamic> p = json;
    if (json['tickets'] is Map<String, dynamic>) {
      p = json['tickets'];
    }

    // 2. Extract the actual items list or map
    final dynamic rawData = p['data'] ?? p['tickets'] ?? [];
    List<dynamic> dataList = [];
    
    if (rawData is List) {
      dataList = rawData;
    } else if (rawData is Map) {
      dataList = rawData.values.toList();
    }

    // 3. Safely map to objects, skipping metadata if it accidentally got into the list
    final List<Ticket> items = dataList
        .whereType<Map<String, dynamic>>()
        .map((x) => Ticket.fromJson(x))
        .toList();
    
    return PaginatedTickets(
      tickets: items,
      currentPage: p['current_page'] ?? 1,
      lastPage: p['last_page'] ?? 1,
      total: p['total'] ?? items.length,
    );
  }
}
