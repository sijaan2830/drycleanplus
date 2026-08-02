import 'package:cloud_firestore/cloud_firestore.dart';

class TimeSlot {
  final String id;
  final String start;
  final String end;
  final int maxSlots;
  final int currentSlots;
  final bool isActive;
  final bool isOpen;
  final DateTime createdAt;
  final DateTime updatedAt;

  TimeSlot({
    required this.id,
    required this.start,
    required this.end,
    required this.maxSlots,
    this.currentSlots = 0,
    this.isActive = true,
    this.isOpen = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TimeSlot.fromFirestore(Map<String, dynamic> data, String id) {
    return TimeSlot(
      id: id,
      start: data['start'] ?? '',
      end: data['end'] ?? '',
      maxSlots: data['max'] ?? 0,
      currentSlots: data['current'] ?? 0,
      isActive: data['isActive'] ?? true,
      isOpen: data['isOpen'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'start': start,
      'end': end,
      'max': maxSlots,
      'current': currentSlots,
      'isActive': isActive,
      'isOpen': isOpen,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  TimeSlot copyWith({
    String? id,
    String? start,
    String? end,
    int? maxSlots,
    int? currentSlots,
    bool? isActive,
    bool? isOpen,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
      maxSlots: maxSlots ?? this.maxSlots,
      currentSlots: currentSlots ?? this.currentSlots,
      isActive: isActive ?? this.isActive,
      isOpen: isOpen ?? this.isOpen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get availableSlots => maxSlots - currentSlots;

  /// Check if slot is available
  bool get isAvailable => isActive && isOpen && availableSlots > 0;

  /// Get display time range
  String get timeRange => '$start - $end';

  /// Check if slot is fully booked
  bool get isFullyBooked => currentSlots >= maxSlots;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeSlot &&
        other.id == id &&
        other.start == start &&
        other.end == end &&
        other.maxSlots == maxSlots &&
        other.currentSlots == currentSlots &&
        other.isActive == isActive &&
        other.isOpen == isOpen;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        start.hashCode ^
        end.hashCode ^
        maxSlots.hashCode ^
        currentSlots.hashCode ^
        isActive.hashCode ^
        isOpen.hashCode;
  }

  @override
  String toString() {
    return 'TimeSlot(id: $id, time: $timeRange, slots: $currentSlots/$maxSlots, active: $isActive, open: $isOpen)';
  }
}

class DaySchedule {
  final String id;
  final String name;
  final int order;
  final bool isOpen;
  final DateTime createdAt;
  final DateTime updatedAt;

  DaySchedule({
    required this.id,
    required this.name,
    required this.order,
    this.isOpen = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DaySchedule.fromFirestore(Map<String, dynamic> data, String id) {
    return DaySchedule(
      id: id,
      name: data['day_name'] ?? '',
      order: data['order'] ?? 0,
      isOpen: data['isOpen'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day_name': name,
      'order': order,
      'isOpen': isOpen,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  DaySchedule copyWith({
    String? id,
    String? name,
    int? order,
    bool? isOpen,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DaySchedule(
      id: id ?? this.id,
      name: name ?? this.name,
      order: order ?? this.order,
      isOpen: isOpen ?? this.isOpen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
