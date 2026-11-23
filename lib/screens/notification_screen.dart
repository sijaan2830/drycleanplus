import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_ui.dart';
import '../services/push_notification_service.dart';

enum NotificationCategory { all, orders, offers, updates }

enum NotificationColorTheme { blue, amber, mint, violet }

class AppNotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final String group; // "Today" or "Earlier"
  final NotificationCategory category;
  final NotificationColorTheme theme;
  final IconData icon;
  final String? route;
  final String? orderDocId;
  bool isRead;

  AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.group,
    required this.category,
    required this.theme,
    required this.icon,
    this.route,
    this.orderDocId,
    this.isRead = false,
  });

  Color get colorA {
    switch (theme) {
      case NotificationColorTheme.blue:
        return const Color(0xFF1553D6);
      case NotificationColorTheme.amber:
        return const Color(0xFFF26B00);
      case NotificationColorTheme.mint:
        return const Color(0xFF0B8F7A);
      case NotificationColorTheme.violet:
        return const Color(0xFF4338CA);
    }
  }

  Color get colorB {
    switch (theme) {
      case NotificationColorTheme.blue:
        return const Color(0xFF4F95FF);
      case NotificationColorTheme.amber:
        return const Color(0xFFFFC53D);
      case NotificationColorTheme.mint:
        return const Color(0xFF34D9AE);
      case NotificationColorTheme.violet:
        return const Color(0xFF8B5CF6);
    }
  }

  Color get tint {
    switch (theme) {
      case NotificationColorTheme.blue:
        return const Color(0xFFDCE8FF);
      case NotificationColorTheme.amber:
        return const Color(0xFFFFEBB8);
      case NotificationColorTheme.mint:
        return const Color(0xFFD9F6EC);
      case NotificationColorTheme.violet:
        return const Color(0xFFE9E2FF);
    }
  }
}

/// Notification Screen matching the Notifications.html mockup.
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  NotificationCategory _selectedCategory = NotificationCategory.all;
  late List<AppNotificationItem> _notifications;

  StreamSubscription? _sub;
  bool _loading = true;

  CollectionReference<Map<String, dynamic>>? get _inbox {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null ? null : FirebaseFirestore.instance.collection('users').doc(uid).collection('notifications');
  }

  @override
  void initState() {
    super.initState();
    _notifications = [];
    final inbox = _inbox;
    if (inbox == null) {
      _loading = false;
      return;
    }
    // Written by the server (Cloud Functions) whenever an order moves.
    _sub = inbox.orderBy('createdAt', descending: true).limit(100).snapshots().listen((snap) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _notifications = snap.docs.map(_fromDoc).toList();
      });
    }, onError: (_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  static const _icons = <String, IconData>{
    'local_shipping': Icons.local_shipping_rounded,
    'event_available': Icons.event_available_rounded,
    'person_pin': Icons.person_pin_circle_rounded,
    'where_to_vote': Icons.where_to_vote_rounded,
    'event_busy': Icons.event_busy_rounded,
    'inventory': Icons.inventory_2_rounded,
    'warehouse': Icons.warehouse_rounded,
    'pending_actions': Icons.pending_actions_rounded,
    'laundry': Icons.local_laundry_service_rounded,
    'checkroom': Icons.checkroom_rounded,
    'check_circle': Icons.check_circle_rounded,
    'cancel': Icons.cancel_rounded,
    'receipt': Icons.receipt_long_rounded,
    'offer': Icons.local_offer_rounded,
  };

  AppNotificationItem _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final at = (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = now.difference(at);
    final time = diff.inMinutes < 1
        ? 'Just now'
        : diff.inMinutes < 60
            ? '${diff.inMinutes}m ago'
            : diff.inHours < 24
                ? '${diff.inHours}h ago'
                : '${diff.inDays}d ago';
    final category = switch ('${m['category'] ?? 'orders'}') {
      'offers' => NotificationCategory.offers,
      'updates' => NotificationCategory.updates,
      _ => NotificationCategory.orders,
    };
    final theme = switch ('${m['theme'] ?? 'blue'}') {
      'amber' => NotificationColorTheme.amber,
      'mint' => NotificationColorTheme.mint,
      'violet' => NotificationColorTheme.violet,
      _ => NotificationColorTheme.blue,
    };
    final orderId = '${m['orderId'] ?? ''}';
    return AppNotificationItem(
      id: d.id,
      title: '${m['title'] ?? 'DryClean Plus'}',
      message: '${m['body'] ?? ''}',
      time: time,
      group: at.isBefore(today) ? 'Earlier' : 'Today',
      category: category,
      theme: theme,
      icon: _icons['${m['icon']}'] ?? Icons.notifications_rounded,
      route: orderId.isEmpty ? (category == NotificationCategory.offers ? '/offers' : null) : null,
      orderDocId: orderId.isEmpty ? null : orderId,
      isRead: m['read'] == true,
    );
  }

  Future<void> _setRead(Iterable<AppNotificationItem> items) async {
    final inbox = _inbox;
    if (inbox == null) return;
    final b = FirebaseFirestore.instance.batch();
    for (final n in items) {
      b.update(inbox.doc(n.id), {'read': true});
    }
    await b.commit().catchError((_) {});
  }

  Future<void> _deleteAll(Iterable<AppNotificationItem> items) async {
    final inbox = _inbox;
    if (inbox == null) return;
    final b = FirebaseFirestore.instance.batch();
    for (final n in items) {
      b.delete(inbox.doc(n.id));
    }
    await b.commit().catchError((_) {});
  }

  List<AppNotificationItem> get _filteredNotifications {
    if (_selectedCategory == NotificationCategory.all) {
      return _notifications;
    }
    return _notifications.where((n) => n.category == _selectedCategory).toList();
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  void _markAllAsRead() {
    if (_unreadCount == 0) return;
    HapticFeedback.mediumImpact();
    final unread = _notifications.where((n) => !n.isRead).toList();
    setState(() {
      for (final n in _notifications) {
        n.isRead = true;
      }
    });
    _setRead(unread);
    showAppSnack(context, 'All marked as read');
  }

  void _showClearConfirmSheet() {
    if (_notifications.isEmpty) return;
    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(18, 10, 18, 18 + MediaQuery.of(ctx).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFD5DDF0),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              // Danger trash circle
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFE1E8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD92D62).withValues(alpha: 0.1),
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.delete_outline_rounded, color: Color(0xFFD92D62), size: 27),
                ),
              ),
              const SizedBox(height: 14),

              // Title & Message
              Text(
                'Clear all notifications?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0B1F5B),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This will remove all your notifications.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13.5,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5B6B9A),
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      _deleteAll(List.of(_notifications));
                      setState(() => _notifications.clear());
                      showAppSnack(context, 'Notifications cleared');
                    },
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD92D62), Color(0xFFFF6B8A)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD92D62).withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Clear all',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF1FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0B1F5B),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleNotificationTap(AppNotificationItem item) {
    HapticFeedback.lightImpact();
    if (!item.isRead) _setRead([item]);
    setState(() => item.isRead = true);
    if (item.orderDocId != null) {
      PushNotificationService.openOrder(item.orderDocId!);
    } else if (item.route != null && item.route!.isNotEmpty) {
      Navigator.of(context).pushNamed(item.route!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredNotifications;
    final unread = _unreadCount;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF1245B5),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF3282F8),
                Color(0xFF1C61E4),
                Color(0xFF1245B5),
              ],
              stops: [0.0, 0.4, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Radial ambient background glows
              Positioned(
                right: -60,
                top: -40,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFFFC83C).withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: -80,
                top: 340,
                child: Container(
                  width: 380,
                  height: 380,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -60,
                bottom: 80,
                child: Container(
                  width: 340,
                  height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF2DD4A8).withValues(alpha: 0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    // ── Sticky Header (.hd) ──────────────────────────────────
                    _buildHeader(unread),

                    // ── Category Filters (.cats) ─────────────────────────────
                    _buildCategoryFilterRow(),
                    const SizedBox(height: 4),

                    // ── Notification List or Empty State ─────────────────────
                    Expanded(
                      child: list.isEmpty
                          ? _buildEmptyState()
                          : _buildGroupedList(list),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header (.hd) ──────────────────────────────────────────────────────────

  Widget _buildHeader(int unread) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF2468EE).withValues(alpha: 0.62),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 34px circular glass back button (.ib)
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.28),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Notifications',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (unread > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD25E),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD25E).withValues(alpha: 0.6),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Text(
                          '$unread new',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0B1F5B),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'Stay updated on orders & perks',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFDCE8FF),
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons: Mark all as read & Clear all
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mark all read
              GestureDetector(
                onTap: unread > 0 ? _markAllAsRead : null,
                child: Opacity(
                  opacity: unread > 0 ? 1.0 : 0.45,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.done_all_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Clear all
              GestureDetector(
                onTap: _notifications.isNotEmpty ? _showClearConfirmSheet : null,
                child: Opacity(
                  opacity: _notifications.isNotEmpty ? 1.0 : 0.45,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.delete_outline_rounded, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Category Filters (.cats) ──────────────────────────────────────────────

  Widget _buildCategoryFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          _buildFilterPill('All', NotificationCategory.all),
          const SizedBox(width: 8),
          _buildFilterPill('Orders', NotificationCategory.orders),
          const SizedBox(width: 8),
          _buildFilterPill('Offers', NotificationCategory.offers),
          const SizedBox(width: 8),
          _buildFilterPill('Updates', NotificationCategory.updates),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label, NotificationCategory cat) {
    final isSelected = _selectedCategory == cat;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedCategory = cat);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
          border: isSelected
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.26), width: 1.5),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF02104C).withValues(alpha: 0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isSelected ? const Color(0xFF0B1F5B) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ── Grouped Notification List ─────────────────────────────────────────────

  Widget _buildGroupedList(List<AppNotificationItem> list) {
    // Collect distinct groups in order ("Today", "Earlier", etc.)
    final groups = <String>[];
    for (final item in list) {
      if (!groups.contains(item.group)) {
        groups.add(item.group);
      }
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 40),
      itemCount: groups.length,
      itemBuilder: (context, gIndex) {
        final groupName = groups[gIndex];
        final groupItems = list.where((x) => x.group == groupName).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 4),
              child: Text(
                groupName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFDCE8FF),
                ),
              ),
            ),
            ...groupItems.map((item) => _buildNotificationCard(item)),
          ],
        );
      },
    );
  }

  // ── Notification Card (.n) ────────────────────────────────────────────────

  Widget _buildNotificationCard(AppNotificationItem item) {
    final isUnread = !item.isRead;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(top: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFD92D62),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        _deleteAll([item]);
        setState(() => _notifications.removeWhere((n) => n.id == item.id));
        showAppSnack(context, 'Notification dismissed');
      },
      child: GestureDetector(
        onTap: () => _handleNotificationTap(item),
        child: Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.fromLTRB(15, 10, 11, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: isUnread
                ? LinearGradient(
                    colors: [item.tint, Colors.white],
                    stops: const [0.0, 0.58],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: isUnread ? null : Colors.white.withValues(alpha: 0.13),
            border: Border.all(
              color: isUnread
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.24),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF02104C).withValues(alpha: isUnread ? 0.3 : 0.15),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Left Accent Stripe (.n::before)
              Positioned(
                left: -15,
                top: 2,
                bottom: 2,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(3),
                      bottomRight: Radius.circular(3),
                    ),
                    gradient: LinearGradient(
                      colors: [item.colorA, item.colorB],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 38px Gradient Tile (.tile)
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      gradient: LinearGradient(
                        colors: [item.colorA, item.colorB],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: item.colorA.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(item.icon, color: Colors.white, size: 19),
                    ),
                  ),
                  const SizedBox(width: 11),

                  // Middle Texts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Time & Glowing Dot
                        Row(
                          children: [
                            if (isUnread) ...[
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [item.colorA, item.colorB],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              item.time,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isUnread ? item.colorA : const Color(0xFFC3D6FF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),

                        // Title
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: isUnread ? const Color(0xFF0B1F5B) : Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),

                        // Message Body (2 lines max)
                        Text(
                          item.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: isUnread ? const Color(0xFF34457D) : const Color(0xFFDCE8FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // View Button (.v)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isUnread
                          ? LinearGradient(
                              colors: [item.colorA, item.colorB],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isUnread ? null : Colors.white.withValues(alpha: 0.2),
                      boxShadow: isUnread
                          ? [
                              BoxShadow(
                                color: item.colorA.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty State (.emp) ────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    final isCompletelyEmpty = _notifications.isEmpty;

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 84x84 White Bubble with Bell
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    spreadRadius: 7,
                  ),
                  BoxShadow(
                    color: const Color(0xFF02104C).withValues(alpha: 0.4),
                    blurRadius: 26,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.notifications_outlined,
                  color: Color(0xFF1553D6),
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Heading
            Text(
              isCompletelyEmpty ? 'You’re all caught up' : 'Nothing here yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 5),

            // Subtitle
            Text(
              isCompletelyEmpty
                  ? 'New notifications will show up here.'
                  : 'No notifications in this category.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFDCE8FF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
