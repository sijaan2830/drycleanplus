import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/time_slot_model.dart';
import '../services/firestore_service.dart';

class TimeSlotProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // Days and slots
  Map<String, DaySchedule> _collectionDaySchedules = {};
  Map<String, List<TimeSlot>> _collectionSlotsByDay = {};
  Map<String, DaySchedule> _deliveryDaySchedules = {};
  Map<String, List<TimeSlot>> _deliverySlotsByDay = {};

  bool _isLoading = false;
  String? _selectedCollectionDay;
  String? _selectedDeliveryDay;
  TimeSlot? _selectedCollectionTimeSlot;
  TimeSlot? _selectedDeliveryTimeSlot;

  // ─── FIXED: track per-day subscriptions so old ones are cancelled
  //     before new ones are created (prevents duplicate listener leak)
  final Map<String, StreamSubscription> _collectionSlotSubs = {};
  final Map<String, StreamSubscription> _deliverySlotSubs   = {};
  StreamSubscription? _collectionDaysSub;
  StreamSubscription? _deliveryDaysSub;

  // Getters
  Map<String, DaySchedule> get collectionDaySchedules => _collectionDaySchedules;
  Map<String, List<TimeSlot>> get collectionSlotsByDay => _collectionSlotsByDay;
  Map<String, DaySchedule> get deliveryDaySchedules => _deliveryDaySchedules;
  Map<String, List<TimeSlot>> get deliverySlotsByDay => _deliverySlotsByDay;
  bool get isLoading => _isLoading;
  String? get selectedCollectionDay => _selectedCollectionDay;
  String? get selectedDeliveryDay => _selectedDeliveryDay;
  TimeSlot? get selectedCollectionTimeSlot => _selectedCollectionTimeSlot;
  TimeSlot? get selectedDeliveryTimeSlot => _selectedDeliveryTimeSlot;

  // ─── Slot accessors ───────────────────────────────────────────────────────

  List<TimeSlot> getCollectionTimeSlotsForDay(String day) {
    return _collectionSlotsByDay[_getDayId(day)] ?? [];
  }

  List<TimeSlot> getDeliveryTimeSlotsForDay(String day) {
    return _deliverySlotsByDay[_getDayId(day)] ?? [];
  }

  List<TimeSlot> getAvailableCollectionTimeSlotsForDay(String day) {
    final dayId       = _getDayId(day);
    final daySchedule = _collectionDaySchedules[dayId];
    if (daySchedule != null && !daySchedule.isOpen) return [];
    return (_collectionSlotsByDay[dayId] ?? [])
        .where((slot) => slot.isAvailable)
        .toList();
  }

  List<TimeSlot> getAvailableDeliveryTimeSlotsForDay(String day) {
    final dayId       = _getDayId(day);
    final daySchedule = _deliveryDaySchedules[dayId];
    if (daySchedule != null && !daySchedule.isOpen) return [];
    return (_deliverySlotsByDay[dayId] ?? [])
        .where((slot) => slot.isAvailable)
        .toList();
  }

  List<String> getAvailableCollectionDays() {
    final days = _collectionDaySchedules.values
        .where((s) => s.isOpen)
        .map((s) => s.name)
        .toList();
    _sortDays(days);
    return days;
  }

  List<String> getAvailableDeliveryDays() {
    final days = _deliveryDaySchedules.values
        .where((s) => s.isOpen)
        .map((s) => s.name)
        .toList();
    _sortDays(days);
    return days;
  }

  void _sortDays(List<String> days) {
    const order = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    days.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
  }

  // ─── FIXED: initializeTimeSlotsListener ──────────────────────────────────
  // Cancels previous top-level subscriptions before re-subscribing, and
  // cancels each per-day slot subscription before replacing it, so there
  // are never duplicate listeners accumulating over the session lifetime.
  Future<void> initializeTimeSlotsListener() async {
    _isLoading = true;
    notifyListeners();

    // Cancel any existing top-level day subscriptions first
    await _collectionDaysSub?.cancel();
    await _deliveryDaysSub?.cancel();

    try {
      // ── Collection days ──────────────────────────────────────────────────
      _collectionDaysSub =
          _firestoreService.getCollectionDaysStream().listen(
        (snapshot) async {
          // Update day schedule map
          for (final doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            _collectionDaySchedules[doc.id] =
                DaySchedule.fromFirestore(data, doc.id);
          }

          // For each day, (re)subscribe to its slots subcollection
          for (final doc in snapshot.docs) {
            final dayId   = doc.id;
            final dayName =
                (doc.data() as Map<String, dynamic>)['day_name'] as String;

            // Cancel old subscription for this day before creating a new one
            await _collectionSlotSubs[dayId]?.cancel();

            _collectionSlotSubs[dayId] =
                _firestoreService.getCollectionSlotsForDayStream(dayId).listen(
              (slotSnapshot) {
                _collectionSlotsByDay[dayId] =
                    slotSnapshot.docs.map((slotDoc) {
                  return TimeSlot.fromFirestore(
                      slotDoc.data() as Map<String, dynamic>, slotDoc.id);
                }).toList();

                debugPrint(
                    'TimeSlotProvider: Collection $dayName — '
                    '${_collectionSlotsByDay[dayId]!.length} slots refreshed');

                notifyListeners();
              },
              onError: (e) {
                debugPrint(
                    'TimeSlotProvider: Error in collection slots stream '
                    'for $dayName: $e');
              },
            );
          }

          if (_isLoading) {
            _isLoading = false;
            notifyListeners();
          } else {
            notifyListeners();
          }
        },
        onError: (e) {
          debugPrint(
              'TimeSlotProvider: Error in collection days stream: $e');
          if (_isLoading) {
            _isLoading = false;
            notifyListeners();
          }
        },
      );

      // ── Delivery days ────────────────────────────────────────────────────
      _deliveryDaysSub =
          _firestoreService.getDeliveryDaysStream().listen(
        (snapshot) async {
          for (final doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            _deliveryDaySchedules[doc.id] =
                DaySchedule.fromFirestore(data, doc.id);
          }

          for (final doc in snapshot.docs) {
            final dayId   = doc.id;
            final dayName =
                (doc.data() as Map<String, dynamic>)['day_name'] as String;

            // Cancel old subscription for this day before creating a new one
            await _deliverySlotSubs[dayId]?.cancel();

            _deliverySlotSubs[dayId] =
                _firestoreService.getDeliverySlotsForDayStream(dayId).listen(
              (slotSnapshot) {
                _deliverySlotsByDay[dayId] =
                    slotSnapshot.docs.map((slotDoc) {
                  return TimeSlot.fromFirestore(
                      slotDoc.data() as Map<String, dynamic>, slotDoc.id);
                }).toList();

                debugPrint(
                    'TimeSlotProvider: Delivery $dayName — '
                    '${_deliverySlotsByDay[dayId]!.length} slots refreshed');

                notifyListeners();
              },
              onError: (e) {
                debugPrint(
                    'TimeSlotProvider: Error in delivery slots stream '
                    'for $dayName: $e');
              },
            );
          }

          if (_isLoading) {
            _isLoading = false;
            notifyListeners();
          } else {
            notifyListeners();
          }
        },
        onError: (e) {
          debugPrint('TimeSlotProvider: Error in delivery days stream: $e');
          if (_isLoading) {
            _isLoading = false;
            notifyListeners();
          }
        },
      );
    } catch (e) {
      debugPrint('TimeSlotProvider: Error initializing listener: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _getDayId(String dayName) {
    const dayMap = {
      'Monday':    'monday',
      'Tuesday':   'tuesday',
      'Wednesday': 'wednesday',
      'Thursday':  'thursday',
      'Friday':    'friday',
      'Saturday':  'saturday',
      'Sunday':    'sunday',
    };
    return dayMap[dayName] ?? dayName.toLowerCase();
  }

  // ─── Selection ────────────────────────────────────────────────────────────

  void selectCollectionDay(String day) {
    _selectedCollectionDay     = day;
    _selectedCollectionTimeSlot = null;
    notifyListeners();
  }

  void selectDeliveryDay(String day) {
    _selectedDeliveryDay     = day;
    _selectedDeliveryTimeSlot = null;
    notifyListeners();
  }

  void selectCollectionTimeSlot(TimeSlot timeSlot) {
    _selectedCollectionTimeSlot = timeSlot;
    notifyListeners();
  }

  void selectDeliveryTimeSlot(TimeSlot timeSlot) {
    _selectedDeliveryTimeSlot = timeSlot;
    notifyListeners();
  }

  void clearSelection() {
    _selectedCollectionDay      = null;
    _selectedDeliveryDay        = null;
    _selectedCollectionTimeSlot = null;
    _selectedDeliveryTimeSlot   = null;
    notifyListeners();
  }

  // ─── Booking count writes ─────────────────────────────────────────────────

  Future<bool> updateCollectionBookingCount(
      String dayId, String slotId, int increment) async {
    try {
      await _firestoreService.updateCollectionSlotBookingCount(
          dayId, slotId, increment);
      return true;
    } catch (e) {
      debugPrint('Error updating collection booking count: $e');
      return false;
    }
  }

  Future<bool> updateDeliveryBookingCount(
      String dayId, String slotId, int increment) async {
    try {
      await _firestoreService.updateDeliverySlotBookingCount(
          dayId, slotId, increment);
      return true;
    } catch (e) {
      debugPrint('Error updating delivery booking count: $e');
      return false;
    }
  }

  // ─── Lookups ──────────────────────────────────────────────────────────────

  TimeSlot? getCollectionTimeSlotById(String id) {
    for (final slots in _collectionSlotsByDay.values) {
      try {
        return slots.firstWhere((slot) => slot.id == id);
      } catch (_) {}
    }
    return null;
  }

  TimeSlot? getDeliveryTimeSlotById(String id) {
    for (final slots in _deliverySlotsByDay.values) {
      try {
        return slots.firstWhere((slot) => slot.id == id);
      } catch (_) {}
    }
    return null;
  }

  bool isCollectionTimeSlotAvailable(String timeSlotId) =>
      getCollectionTimeSlotById(timeSlotId)?.isAvailable ?? false;

  bool isDeliveryTimeSlotAvailable(String timeSlotId) =>
      getDeliveryTimeSlotById(timeSlotId)?.isAvailable ?? false;

  double getCollectionBookingPercentage(String timeSlotId) {
    final slot = getCollectionTimeSlotById(timeSlotId);
    if (slot == null || slot.maxSlots == 0) return 0.0;
    return slot.currentSlots / slot.maxSlots;
  }

  double getDeliveryBookingPercentage(String timeSlotId) {
    final slot = getDeliveryTimeSlotById(timeSlotId);
    if (slot == null || slot.maxSlots == 0) return 0.0;
    return slot.currentSlots / slot.maxSlots;
  }

  // ─── FIXED: dispose cancels ALL active subscriptions ─────────────────────
  @override
  void dispose() {
    _collectionDaysSub?.cancel();
    _deliveryDaysSub?.cancel();
    for (final sub in _collectionSlotSubs.values) sub.cancel();
    for (final sub in _deliverySlotSubs.values)   sub.cancel();
    super.dispose();
  }
}