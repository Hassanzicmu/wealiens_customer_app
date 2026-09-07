import 'dart:convert';

class CustomerProfile {
  final String status;
  final Customer customer;
  final Statistics statistics;
  final RecentActivity recentActivity;

  CustomerProfile({
    required this.status,
    required this.customer,
    required this.statistics,
    required this.recentActivity,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) => CustomerProfile(
        status: json["status"],
        customer: Customer.fromJson(json["customer"]),
        statistics: Statistics.fromJson(json["statistics"]),
        recentActivity: RecentActivity.fromJson(json["recent_activity"]),
      );
}

class Customer {
  final int id;
  final String name;
  final String email;
  final String? phone;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json["id"],
        name: json["name"],
        email: json["email"],
        phone: json["phone"],
      );
}

class RecentActivity {
  final LatestProject? latestProject;

  RecentActivity({
    this.latestProject,
  });

  factory RecentActivity.fromJson(Map<String, dynamic> json) => RecentActivity(
        latestProject: json["latest_project"] == null
            ? null
            : LatestProject.fromJson(json["latest_project"]),
      );
}

class LatestProject {
  final int id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime createdAt;

  LatestProject({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.createdAt,
  });

  factory LatestProject.fromJson(Map<String, dynamic> json) => LatestProject(
        id: json["id"],
        title: json["title"],
        description: json["description"],
        startDate: DateTime.parse(json["start_date"]),
        createdAt: DateTime.parse(json["created_at"]),
      );
}

class Statistics {
  final int totalProjects;
  final int totalTickets;

  Statistics({
    required this.totalProjects,
    required this.totalTickets,
  });

  factory Statistics.fromJson(Map<String, dynamic> json) => Statistics(
        totalProjects: json["total_projects"],
        totalTickets: json["total_tickets"],
      );
}
