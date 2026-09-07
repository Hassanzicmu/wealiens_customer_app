import 'dart:convert';

class CustomerProjectsResponse {
  final String status;
  final List<Project> projects;

  CustomerProjectsResponse({
    required this.status,
    required this.projects,
  });

  factory CustomerProjectsResponse.fromJson(Map<String, dynamic> json) => CustomerProjectsResponse(
        status: json["status"],
        projects: List<Project>.from(json["projects"].map((x) => Project.fromJson(x))),
      );
}

class Project {
  final int id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime createdAt;
  final List<ProjectCategory> categories;

  Project({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.createdAt,
    required this.categories,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json["id"] is int ? json["id"] : int.tryParse(json["id"].toString()) ?? 0,
        title: json["title"] ?? "Untitled Project",
        description: json["description"] ?? "",
        startDate: json["start_date"] != null
            ? DateTime.tryParse(json["start_date"]) ?? DateTime.now()
            : DateTime.now(),
        createdAt: json["created_at"] != null
            ? DateTime.tryParse(json["created_at"]) ?? DateTime.now()
            : DateTime.now(),
        categories: json["categories"] != null
            ? List<ProjectCategory>.from(
                json["categories"].map((x) => ProjectCategory.fromJson(x)))
            : [],
      );
}

class ProjectCategory {
  final int id;
  final Map<String, dynamic> name;
  final String slug;
  final String image;

  ProjectCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.image,
  });

  factory ProjectCategory.fromJson(Map<String, dynamic> json) => ProjectCategory(
        id: json["id"] is int ? json["id"] : int.tryParse(json["id"].toString()) ?? 0,
        name: json["name"] ?? {},
        slug: json["slug"] ?? "",
        image: json["image"] ?? "",
      );

  String getName(String langCode) {
    if (name.isEmpty) return 'Category';
    return name[langCode] ?? name['en'] ?? 'Category';
  }
}
