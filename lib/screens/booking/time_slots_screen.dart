import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/booking_provider.dart';
import '../../providers/time_slot_provider.dart';
import '../../widgets/booking_ui.dart';
import 'address_selection_screen.dart';

class TimeSlotsScreen extends StatefulWidget {
  final bool isEditMode;

  const TimeSlotsScreen({super.key, this.isEditMode = false});

  @override
  State<TimeSlotsScreen> createState() => _TimeSlotsScreenState();
}

class _TimeSlotsScreenState extends State<TimeSlotsScreen> {
  String _selectedCollectionDate = '';
  String _selectedCollectionTime = '';
  String _selectedDeliveryDate = '';
  String _selectedDeliveryTime = '';
  String _collectionMethod = 'Collect from me in person';
  String _deliveryMethod = 'Deliver to me in person';
  final TextEditingController _instructionsController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final timeSlotProvider = Provider.of<TimeSlotProvider>(context, listen: false);
      timeSlotProvider.initializeTimeSlotsListener();

      // Pre-fill if editing or already selected
      final bd = bookingProvider.bookingData;
      if ((bd.collectionDate ?? '').isNotEmpty) {
        _selectedCollectionDate = bd.collectionDate!;
        _selectedCollectionTime = bd.collectionTime ?? '';
      }
      if ((bd.deliveryDate ?? '').isNotEmpty) {
        _selectedDeliveryDate = bd.deliveryDate!;
        _selectedDeliveryTime = bd.deliveryTime ?? '';
      }
      if ((bd.collectionMethod ?? '').isNotEmpty) {
        _collectionMethod = bd.collectionMethod!;
      }
      if ((bd.deliveryMethod ?? '').isNotEmpty) {
        _deliveryMethod = bd.deliveryMethod!;
      }
      if ((bd.instructions ?? '').isNotEmpty) {
        _instructionsController.text = bd.instructions!;
      }

      // If empty, auto-pick first available collection day
      final availableCollectionDays = timeSlotProvider.getAvailableCollectionDays();
      if (_selectedCollectionDate.isEmpty && availableCollectionDays.isNotEmpty) {
        _selectedCollectionDate = availableCollectionDays.first;
        final collectionSlots = timeSlotProvider.getAvailableCollectionTimeSlotsForDay(_selectedCollectionDate);
        if (collectionSlots.isNotEmpty) {
          _selectedCollectionTime = '${collectionSlots.first.start} - ${collectionSlots.first.end}';
        }
      }

      // Auto-pick delivery day: strictly at least 48 hours after collection
      final openDeliveryDays = timeSlotProvider.deliveryDaySchedules.values.where((d) => d.isOpen).toList();
      if (_selectedCollectionDate.isNotEmpty && openDeliveryDays.isNotEmpty) {
        final colDate = _calculateDateForDay(_selectedCollectionDate);
        openDeliveryDays.sort((a, b) {
          final dateA = _calculateDeliveryDateForDay(a.name, colDate);
          final dateB = _calculateDeliveryDateForDay(b.name, colDate);
          return dateA.compareTo(dateB);
        });

        final needsNewDelivery = _selectedDeliveryDate.isEmpty ||
            _calculateDeliveryDateForDay(_selectedDeliveryDate, colDate).isBefore(
              DateTime(colDate.year, colDate.month, colDate.day).add(const Duration(days: 2)),
            );
        if (needsNewDelivery) {
          _selectedDeliveryDate = openDeliveryDays.first.name;
          final deliverySlots = timeSlotProvider.getAvailableDeliveryTimeSlotsForDay(_selectedDeliveryDate);
          if (deliverySlots.isNotEmpty) {
            _selectedDeliveryTime = '${deliverySlots.first.start} - ${deliverySlots.first.end}';
          }
        }
      }

      setState(() => _isLoading = false);
    });
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  bool _canProceed() {
    return _selectedCollectionDate.isNotEmpty &&
        _selectedCollectionTime.isNotEmpty &&
        _selectedDeliveryDate.isNotEmpty &&
        _selectedDeliveryTime.isNotEmpty;
  }

  void _proceedToNext(BookingProvider provider) {
    if (!_canProceed()) return;

    provider.setCollectionDateTime(_selectedCollectionDate, _selectedCollectionTime);
    provider.setCollectionMethod(_collectionMethod);
    provider.setDeliveryMethod(_deliveryMethod);
    provider.setDeliveryDateTime(_selectedDeliveryDate, _selectedDeliveryTime);
    provider.setInstructions(_instructionsController.text);

    if (widget.isEditMode) {
      Navigator.of(context).pop();
      return;
    }

    if (provider.hasUserDefaultAddress || provider.bookingData.selectedAddress != null) {
      if (provider.hasUserContactInfo) {
        Navigator.of(context).pushNamed('/booking_overview');
      } else {
        Navigator.of(context).pushNamed('/contact_info');
      }
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const AddressSelectionScreen(isFromBookingFlow: true),
        ),
      );
    }
  }

  // ── Bottom Sheet Pickers ───────────────────────────────────────────────────

  void _openDayPicker({required bool isCollection, required TimeSlotProvider timeSlotProvider}) {
    final allDays = (isCollection
            ? timeSlotProvider.collectionDaySchedules.values.toList()
            : timeSlotProvider.deliveryDaySchedules.values.toList())
      ..sort((a, b) => a.order.compareTo(b.order));

    final accentGradient = isCollection
        ? const LinearGradient(colors: [Color(0xFF4338CA), Color(0xFF6D4AFF)])
        : const LinearGradient(colors: [Color(0xFF0B6E64), Color(0xFF12876F)]);
    final accentColor = isCollection ? const Color(0xFF4338CA) : const Color(0xFF0B6E64);
    final accentBg = isCollection ? const Color(0xFFEEF0FF) : const Color(0xFFE4F7F0);
    final currentVal = isCollection ? _selectedCollectionDate : _selectedDeliveryDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetCtx).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x7302104C),
                blurRadius: 30,
                offset: Offset(0, -12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 5px Accent bar on top
              Container(
                height: 5,
                decoration: BoxDecoration(
                  gradient: accentGradient,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
              ),

              // Grab handle
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD5DEF5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select a day',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0B1F5B),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isCollection
                              ? 'Select collection day'
                              : 'Select delivery day (min. 48h turnaround)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5B6B9A),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(sheetCtx),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFEEF3FF),
                        ),
                        child: const Center(
                          child: Icon(Icons.close_rounded, color: Color(0xFF0B1F5B), size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Day List
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: allDays.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final day = allDays[i];
                    final isSel = day.name == currentVal;
                    final isOpen = day.isOpen;
                    final date = isCollection ? _calculateDateForDay(day.name) : _calculateDeliveryDateForDay(day.name);

                    return GestureDetector(
                      onTap: isOpen
                          ? () {
                              setState(() {
                                if (isCollection) {
                                  if (_selectedCollectionDate != day.name) {
                                    _selectedCollectionTime = '';
                                  }
                                  _selectedCollectionDate = day.name;

                                  // Auto-calculate earliest delivery day (min 48 hours later)
                                  final colDate = _calculateDateForDay(day.name);
                                  final openDelDays = timeSlotProvider.deliveryDaySchedules.values.where((d) => d.isOpen).toList();
                                  if (openDelDays.isNotEmpty) {
                                    openDelDays.sort((a, b) {
                                      final dA = _calculateDeliveryDateForDay(a.name, colDate);
                                      final dB = _calculateDeliveryDateForDay(b.name, colDate);
                                      return dA.compareTo(dB);
                                    });
                                    _selectedDeliveryDate = openDelDays.first.name;
                                    final dSlots = timeSlotProvider.getAvailableDeliveryTimeSlotsForDay(_selectedDeliveryDate);
                                    _selectedDeliveryTime = dSlots.isNotEmpty ? '${dSlots.first.start} - ${dSlots.first.end}' : '';
                                  }
                                } else {
                                  if (_selectedDeliveryDate != day.name) {
                                    _selectedDeliveryTime = '';
                                  }
                                  _selectedDeliveryDate = day.name;
                                }
                              });
                              Navigator.pop(sheetCtx);
                              // Auto-open time picker next
                              Future.delayed(const Duration(milliseconds: 200), () {
                                if (mounted) {
                                  _openTimePicker(isCollection: isCollection, timeSlotProvider: timeSlotProvider);
                                }
                              });
                            }
                          : null,
                      child: Container(
                        height: 64,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSel ? accentColor : const Color(0xFFE4EBFB),
                            width: 2,
                          ),
                          color: isSel
                              ? accentBg
                              : (isOpen ? const Color(0xFFF4F7FF) : const Color(0xFFF0F3FA)),
                        ),
                        child: Row(
                          children: [
                            // 50x50 Date Box
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: accentGradient,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    DateFormat('MMM').format(date).toUpperCase(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white.withValues(alpha: 0.9),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('d').format(date),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Day Name
                            Expanded(
                              child: Text(
                                day.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: isOpen
                                      ? const Color(0xFF0B1F5B)
                                      : const Color(0xFF0B1F5B).withValues(alpha: 0.4),
                                ),
                              ),
                            ),

                            // Right Status / Radio Checkmark
                            if (!isOpen)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(999),
                                  color: const Color(0xFFFFEBEE),
                                ),
                                child: Text(
                                  'Closed',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFD32F2F),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSel ? accentColor : Colors.transparent,
                                  border: Border.all(
                                    color: isSel ? accentColor : const Color(0xFFB5C3E8),
                                    width: 2.5,
                                  ),
                                ),
                                child: isSel
                                    ? const Center(
                                        child: Icon(Icons.check_rounded, color: Colors.white, size: 16),
                                      )
                                    : null,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _openTimePicker({required bool isCollection, required TimeSlotProvider timeSlotProvider}) {
    final chosenDay = isCollection ? _selectedCollectionDate : _selectedDeliveryDate;
    if (chosenDay.isEmpty) {
      _openDayPicker(isCollection: isCollection, timeSlotProvider: timeSlotProvider);
      return;
    }

    final slots = isCollection
        ? timeSlotProvider.getAvailableCollectionTimeSlotsForDay(chosenDay)
        : timeSlotProvider.getAvailableDeliveryTimeSlotsForDay(chosenDay);

    final accentColor = isCollection ? const Color(0xFF4338CA) : const Color(0xFF0B6E64);
    final accentBg = isCollection ? const Color(0xFFEEF0FF) : const Color(0xFFE4F7F0);
    final accentGradient = isCollection
        ? const LinearGradient(colors: [Color(0xFF4338CA), Color(0xFF6D4AFF)])
        : const LinearGradient(colors: [Color(0xFF0B6E64), Color(0xFF12876F)]);
    final currentVal = isCollection ? _selectedCollectionTime : _selectedDeliveryTime;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetCtx).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x7302104C),
                blurRadius: 30,
                offset: Offset(0, -12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  gradient: accentGradient,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
              ),
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD5DEF5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'For $chosenDay',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0B1F5B),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select ${isCollection ? 'collection' : 'delivery'} time',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5B6B9A),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(sheetCtx),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFEEF3FF),
                        ),
                        child: const Center(
                          child: Icon(Icons.close_rounded, color: Color(0xFF0B1F5B), size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Flexible(
                child: slots.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No available slots for $chosenDay. Please pick another day.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5B6B9A),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: slots.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) {
                          final slot = slots[i];
                          final slotStr = '${slot.start} – ${slot.end}';
                          final isSel = slotStr == currentVal || '${slot.start} - ${slot.end}' == currentVal;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isCollection) {
                                  _selectedCollectionTime = slotStr;
                                } else {
                                  _selectedDeliveryTime = slotStr;
                                }
                              });
                              Navigator.pop(sheetCtx);
                            },
                            child: Container(
                              height: 64,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: isSel ? accentColor : const Color(0xFFE4EBFB),
                                  width: 2,
                                ),
                                color: isSel ? accentBg : const Color(0xFFF4F7FF),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSel ? accentColor : Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0B1F5B).withValues(alpha: 0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.schedule_rounded,
                                        color: isSel ? Colors.white : accentColor,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  Expanded(
                                    child: Text(
                                      slotStr,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0B1F5B),
                                      ),
                                    ),
                                  ),

                                  // Capacity Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(999),
                                      color: const Color(0xFFDDF6E6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.circle, color: Color(0xFF12A56A), size: 6),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Available',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF0A5C36),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Checkmark Circle
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSel ? accentColor : Colors.transparent,
                                      border: Border.all(
                                        color: isSel ? accentColor : const Color(0xFFB5C3E8),
                                        width: 2.5,
                                      ),
                                    ),
                                    child: isSel
                                        ? const Center(
                                            child: Icon(Icons.check_rounded, color: Colors.white, size: 16),
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _openMethodPicker({required bool isCollection}) {
    final options = isCollection
        ? [
            ('Collect from me in person', Icons.person_rounded),
            ('Collect from outside', Icons.door_front_door_rounded),
            ('Collect from reception/porter', Icons.desk_rounded),
          ]
        : [
            ('Deliver to me in person', Icons.person_rounded),
            ('Deliver outside', Icons.door_front_door_rounded),
            ('Deliver to reception/porter', Icons.desk_rounded),
          ];

    final currentVal = isCollection ? _collectionMethod : _deliveryMethod;
    final accentColor = isCollection ? const Color(0xFF4338CA) : const Color(0xFF0B6E64);
    final accentBg = isCollection ? const Color(0xFFEEF0FF) : const Color(0xFFE4F7F0);
    final accentGradient = isCollection
        ? const LinearGradient(colors: [Color(0xFF4338CA), Color(0xFF6D4AFF)])
        : const LinearGradient(colors: [Color(0xFF0B6E64), Color(0xFF12876F)]);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Color(0x7302104C),
                blurRadius: 30,
                offset: Offset(0, -12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  gradient: accentGradient,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
              ),
              Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD5DEF5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select ${isCollection ? 'collection' : 'delivery'} method',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0B1F5B),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Select preference',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF5B6B9A),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(sheetCtx),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFEEF3FF),
                        ),
                        child: const Center(
                          child: Icon(Icons.close_rounded, color: Color(0xFF0B1F5B), size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: options.map((opt) {
                    final isSel = opt.$1 == currentVal;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isCollection) {
                              _collectionMethod = opt.$1;
                            } else {
                              _deliveryMethod = opt.$1;
                            }
                          });
                          Navigator.pop(sheetCtx);
                        },
                        child: Container(
                          height: 64,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSel ? accentColor : const Color(0xFFE4EBFB),
                              width: 2,
                            ),
                            color: isSel ? accentBg : const Color(0xFFF4F7FF),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSel ? accentColor : Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0B1F5B).withValues(alpha: 0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    opt.$2,
                                    color: isSel ? Colors.white : accentColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              Expanded(
                                child: Text(
                                  opt.$1,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0B1F5B),
                                  ),
                                ),
                              ),

                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSel ? accentColor : Colors.transparent,
                                  border: Border.all(
                                    color: isSel ? accentColor : const Color(0xFFB5C3E8),
                                    width: 2.5,
                                  ),
                                ),
                                child: isSel
                                    ? const Center(
                                        child: Icon(Icons.check_rounded, color: Colors.white, size: 16),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  DateTime _calculateDateForDay(String dayName) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final targetIdx = days.indexOf(dayName.toLowerCase());
    final now = DateTime.now();
    if (targetIdx == -1) return now;

    final currentIdx = now.weekday - 1;
    int diff = targetIdx - currentIdx;
    if (diff <= 0) diff += 7;
    return now.add(Duration(days: diff));
  }

  /// Calculates the delivery date for a weekday name, strictly enforcing a minimum 48-hour
  /// (2 full days) turnaround time after collection.
  DateTime _calculateDeliveryDateForDay(String dayName, [DateTime? collectionDateBase]) {
    final collectionDate = collectionDateBase ??
        (_selectedCollectionDate.isNotEmpty ? _calculateDateForDay(_selectedCollectionDate) : DateTime.now());
    final minDeliveryDate = DateTime(collectionDate.year, collectionDate.month, collectionDate.day).add(const Duration(days: 2));

    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final targetIdx = days.indexOf(dayName.toLowerCase());
    if (targetIdx == -1) return minDeliveryDate;

    final minWeekdayIdx = minDeliveryDate.weekday - 1;
    int diff = targetIdx - minWeekdayIdx;
    if (diff < 0) diff += 7;
    return minDeliveryDate.add(Duration(days: diff));
  }

  // ── Main Screen Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer2<BookingProvider, TimeSlotProvider>(
      builder: (context, bookingProvider, timeSlotProvider, _) {
        if (_isLoading || timeSlotProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
          );
        }

        final canProceed = _canProceed();

        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.bgGradient,
            ),
            child: Stack(
              children: [
                // Ambient top decorative circle
                Positioned(
                  top: -140,
                  right: -150,
                  child: Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.07),
                    ),
                  ),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      // Header Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withValues(alpha: 0.18),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    width: 1.5,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                                ),
                              ),
                            ),
                            Text(
                              'Collection & Delivery',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(width: 44),
                          ],
                        ),
                      ),

                      // Progress Steps Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: List.generate(5, (index) {
                            final isActive = index == 0;
                            return Expanded(
                              child: Container(
                                margin: EdgeInsets.only(right: index < 4 ? 6 : 0),
                                height: 7,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(4),
                                  color: isActive
                                      ? const Color(0xFFFFC73A)
                                      : Colors.white.withValues(alpha: 0.28),
                                  boxShadow: isActive
                                      ? [
                                          const BoxShadow(
                                            color: Color(0xB2FFC73A),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Service Capsule Pill
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 38,
                            padding: const EdgeInsets.fromLTRB(6, 0, 16, 0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Colors.white.withValues(alpha: 0.18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.local_laundry_service_rounded,
                                      size: 16,
                                      color: Color(0xFF1553D6),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Service: ${bookingProvider.selectedService ?? 'Dry Clean'}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Scrollable Cards List
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                          children: [
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 480),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // 1. Collection Time Card
                                    _buildTimeCard(
                                      isCollection: true,
                                      day: _selectedCollectionDate,
                                      time: _selectedCollectionTime,
                                      method: _collectionMethod,
                                      timeSlotProvider: timeSlotProvider,
                                    ),
                                    const SizedBox(height: 18),

                                    // 2. Delivery Time Card
                                    _buildTimeCard(
                                      isCollection: false,
                                      day: _selectedDeliveryDate,
                                      time: _selectedDeliveryTime,
                                      method: _deliveryMethod,
                                      timeSlotProvider: timeSlotProvider,
                                    ),
                                    const SizedBox(height: 18),

                                    // 3. Instructions for driver
                                    _buildInstructionsInput(),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Floating NEXT — the same yellow pill as Select a service (no bar behind it)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 14 + MediaQuery.of(context).padding.bottom,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 448),
                      child: YellowPill(
                        label: widget.isEditMode ? 'Save changes' : 'Next',
                        enabled: canProceed,
                        onTap: () => _proceedToNext(bookingProvider),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Card Builder (Collection / Delivery) ───────────────────────────────────

  Widget _buildTimeCard({
    required bool isCollection,
    required String day,
    required String time,
    required String method,
    required TimeSlotProvider timeSlotProvider,
  }) {
    final title = isCollection ? 'Collection time' : 'Delivery time';
    final accentA = isCollection ? const Color(0xFF4338CA) : const Color(0xFF0B6E64);
    final accentB = isCollection ? const Color(0xFF6D4AFF) : const Color(0xFF12876F);
    final accentT = isCollection ? const Color(0xFFEEF0FF) : const Color(0xFFE4F7F0);
    final isComplete = day.isNotEmpty && time.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x8C02104C),
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background disc (top-right)
            Positioned(
              top: -60,
              right: -50,
              child: Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentT,
                ),
              ),
            ),

            // Floating 3D illustration badge (top-right)
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  color: Colors.white,
                  border: Border.all(color: accentT, width: 4),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x8002104C),
                      blurRadius: 20,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(54, 54),
                    painter: isCollection
                        ? const _CollectionBadgePainter()
                        : const _DeliveryBadgePainter(),
                  ),
                ),
              ),
            ),

            // Card content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(right: 84, bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(17),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [accentA, accentB],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentA.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              isCollection
                                  ? Icons.calendar_today_rounded
                                  : Icons.local_shipping_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0B1F5B),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isCollection
                                    ? 'Pick collection day, time and method'
                                    : 'Delivered min. 48 hours after collection',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isCollection ? const Color(0xFF5B6B9A) : const Color(0xFF0B6E64),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 1. Day field
                  _buildFieldRow(
                    label: 'DAY',
                    value: day.isNotEmpty
                        ? '$day · ${DateFormat('d MMM').format(isCollection ? _calculateDateForDay(day) : _calculateDeliveryDateForDay(day))}'
                        : 'Select day',
                    isSet: day.isNotEmpty,
                    icon: Icons.calendar_month_rounded,
                    accentColor: accentA,
                    accentBg: accentT,
                    onTap: () => _openDayPicker(
                      isCollection: isCollection,
                      timeSlotProvider: timeSlotProvider,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 2. Time field
                  _buildFieldRow(
                    label: 'TIME',
                    value: time.isNotEmpty ? time : 'Select time',
                    isSet: time.isNotEmpty,
                    icon: Icons.schedule_rounded,
                    accentColor: accentA,
                    accentBg: accentT,
                    onTap: () => _openTimePicker(
                      isCollection: isCollection,
                      timeSlotProvider: timeSlotProvider,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 3. Method field
                  _buildFieldRow(
                    label: 'METHOD',
                    value: method,
                    isSet: true,
                    icon: Icons.person_outline_rounded,
                    accentColor: accentA,
                    accentBg: accentT,
                    onTap: () => _openMethodPicker(isCollection: isCollection),
                  ),

                  // Summary bar if ready
                  if (isComplete) ...[
                    const SizedBox(height: 12),
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [accentA, accentB],
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${day.substring(0, math.min(3, day.length))}, ${DateFormat('d MMM').format(_calculateDateForDay(day))} · $time',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldRow({
    required String label,
    required String value,
    required bool isSet,
    required IconData icon,
    required Color accentColor,
    required Color accentBg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 66,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSet ? accentColor : const Color(0xFFE4EBFB),
            width: 2,
          ),
          color: isSet ? accentBg : const Color(0xFFF4F7FF),
        ),
        child: Row(
          children: [
            // Icon Circle
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSet ? accentColor : Colors.white,
                boxShadow: isSet
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(0xFF0B1F5B).withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: isSet ? Colors.white : accentColor,
                  size: 21,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Label & Value
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: const Color(0xFF5B6B9A),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16.5,
                      fontWeight: isSet ? FontWeight.w800 : FontWeight.w700,
                      color: isSet ? const Color(0xFF0B1F5B) : const Color(0xFF6B7BA8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Chevron / Checkmark Circle
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSet ? accentColor : const Color(0xFFE6ECFB),
              ),
              child: Center(
                child: Icon(
                  isSet ? Icons.check_rounded : Icons.chevron_right_rounded,
                  color: isSet ? Colors.white : const Color(0xFF0B1F5B),
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 3. Instructions for driver ─────────────────────────────────────────────

  Widget _buildInstructionsInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructions for driver',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1.5,
            ),
            color: Colors.white.withValues(alpha: 0.16),
          ),
          child: TextField(
            controller: _instructionsController,
            maxLines: 3,
            cursorColor: Colors.white,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
              hintText: 'e.g. Leave with concierge, ring bell twice',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '*Please do not add cleaning instructions here',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFDDE8FF),
          ),
        ),
      ],
    );
  }
}


class _CollectionBadgePainter extends CustomPainter {
  const _CollectionBadgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64.0, size.height / 64.0);

    final strokeDark = Paint()
      ..color = const Color(0xFF14173F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final bodyRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(8, 12, 44, 42),
      const Radius.circular(7),
    );
    canvas.drawRRect(bodyRRect, fillWhite);
    canvas.drawRRect(bodyRRect, strokeDark);

    final topBarPath = Path()
      ..moveTo(8, 19)
      ..arcToPoint(const Offset(15, 12), radius: const Radius.circular(7))
      ..lineTo(45, 12)
      ..arcToPoint(const Offset(52, 19), radius: const Radius.circular(7))
      ..lineTo(52, 26)
      ..lineTo(8, 26)
      ..close();
    canvas.drawPath(topBarPath, Paint()..color = const Color(0xFF6D4AFF));
    canvas.drawPath(topBarPath, strokeDark);

    final ringPaint = Paint()
      ..color = const Color(0xFF14173F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(20, 7), const Offset(20, 18), ringPaint);
    canvas.drawLine(const Offset(40, 7), const Offset(40, 18), ringPaint);

    canvas.drawLine(const Offset(17, 36), const Offset(23, 36), ringPaint);
    canvas.drawLine(const Offset(28, 36), const Offset(34, 36), ringPaint);
    canvas.drawLine(const Offset(39, 36), const Offset(45, 36), ringPaint);
    canvas.drawLine(const Offset(17, 45), const Offset(23, 45), ringPaint);
    canvas.drawLine(const Offset(28, 45), const Offset(34, 45), ringPaint);

    const clockCenter = Offset(47, 46);
    canvas.drawCircle(clockCenter, 12.5, Paint()..color = const Color(0xFFFFC73A));
    canvas.drawCircle(clockCenter, 12.5, strokeDark);

    final handPath = Path()
      ..moveTo(47, 39)
      ..lineTo(47, 46.5)
      ..lineTo(51.5, 49.5);
    canvas.drawPath(handPath, strokeDark);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DeliveryBadgePainter extends CustomPainter {
  const _DeliveryBadgePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 64.0, size.height / 64.0);

    final strokeDark = Paint()
      ..color = const Color(0xFF14173F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawLine(const Offset(2, 24), const Offset(7, 24), strokeDark);
    canvas.drawLine(const Offset(4, 31), const Offset(8, 31), strokeDark);

    final bodyPath = Path()
      ..moveTo(10, 46)
      ..lineTo(10, 21)
      ..arcToPoint(const Offset(15, 16), radius: const Radius.circular(5))
      ..lineTo(37, 16)
      ..arcToPoint(const Offset(40, 19), radius: const Radius.circular(3))
      ..lineTo(40, 25)
      ..lineTo(48.5, 25)
      ..arcToPoint(const Offset(50.9, 26.2), radius: const Radius.circular(3))
      ..lineTo(59, 36.5)
      ..lineTo(59, 46)
      ..close();

    canvas.drawPath(bodyPath, Paint()..color = Colors.white);
    canvas.drawRect(const Rect.fromLTWH(10, 31, 30, 7), Paint()..color = const Color(0xFF12A38A));
    canvas.drawPath(bodyPath, strokeDark);

    final winPath = Path()
      ..moveTo(43.5, 28.5)
      ..lineTo(47.7, 28.5)
      ..lineTo(54, 36.5)
      ..lineTo(43.5, 36.5)
      ..close();
    canvas.drawPath(winPath, Paint()..color = const Color(0xFFBFE8FF));
    canvas.drawPath(
      winPath,
      Paint()
        ..color = const Color(0xFF14173F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeJoin = StrokeJoin.round,
    );

    for (final cx in [22.0, 49.0]) {
      canvas.drawCircle(Offset(cx, 47), 7.0, Paint()..color = const Color(0xFF14173F));
      canvas.drawCircle(Offset(cx, 47), 2.6, Paint()..color = Colors.white);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
