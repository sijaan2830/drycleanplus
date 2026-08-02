import 'package:cloud_firestore/cloud_firestore.dart';

class Service {
  final String id;
  final String name;
  final String icon;
  final String description;
  final bool isActive;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Map<String, dynamic>>? items;
  final String? imageUrl;

  const Service({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.isActive,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    this.items,
    this.imageUrl,
  });

  factory Service.fromJson(Map<String, dynamic> json, String id) {
    return Service(
      id: id,
      name: json['name'] ?? '',
      icon: json['icon'] ?? '',
      description: json['description'] ?? '',
      isActive: json['isActive'] ?? true,
      order: json['order'] ?? 0,
      createdAt: json['createdAt'] is Timestamp 
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: json['updatedAt'] is Timestamp 
          ? (json['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      items: json['items'] != null ? List<Map<String, dynamic>>.from(json['items']) : null,
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'icon': icon,
      'description': description,
      'isActive': isActive,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'imageUrl': imageUrl,
    };
  }

  Service copyWith({
    String? id,
    String? name,
    String? icon,
    String? description,
    bool? isActive,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? imageUrl,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Service &&
        other.id == id &&
        other.name == name &&
        other.icon == icon &&
        other.description == description &&
        other.isActive == isActive &&
        other.order == order;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        icon.hashCode ^
        description.hashCode ^
        isActive.hashCode ^
        order.hashCode;
  }

  @override
  String toString() {
    return 'Service(id: $id, name: $name, icon: $icon, active: $isActive, order: $order, imageUrl: ${imageUrl?.isNotEmpty == true ? "YES" : "NO"})';
  }
}
