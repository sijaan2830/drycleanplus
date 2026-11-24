import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../models/booking_models.dart' as models;
import '../screens/track_driver_screen.dart';
import '../screens/track_order_screen.dart';
import '../utils/order_status.dart';

/// Home-screen banner: appears by itself when one of the customer's orders needs
/// attention right now — the driver is on the way / outside, or the facility needs
/// approval. Tapping opens the order with the live map.
class LiveOrderBanner extends StatelessWidget {
  const LiveOrderBanner({super.key});

  static const _watch = ['pickup_en_route', 'pickup_arrived', 'out_for_delivery', 'delivery_arrived', 'awaiting_approval'];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, auth) {
        final uid = auth.data?.uid;
        if (uid == null) return const SizedBox.shrink();
        return _Orders(uid: uid);
      },
    );
  }
}

class _Orders extends StatefulWidget {
  final String uid;
  const _Orders({required this.uid});
  @override
  State<_Orders> createState() => _OrdersState();
}

class _OrdersState extends State<_Orders> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _s = _query();

  Stream<QuerySnapshot<Map<String, dynamic>>> _query() => FirebaseFirestore.instance
      .collection('orders')
      .where('userId', isEqualTo: widget.uid)
      .where('status', whereIn: LiveOrderBanner._watch)
      .snapshots();

  @override
  void didUpdateWidget(covariant _Orders old) {
    super.didUpdateWidget(old);
    if (old.uid != widget.uid) _s = _query();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _s,
      builder: (context, snap) {
        final docs = snap.data?.docs ?? const [];
        if (docs.isEmpty) return const SizedBox.shrink();
        final d = docs.first;
        final order = models.Order.fromJson({...d.data(), 'id': d.id});
        final status = normalizeOrderStatus(order.status);
        final approval = status == 'awaiting_approval';
        final arrived = status.endsWith('_arrived');
        final info = orderStatusInfo(status);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: (approval
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF2563EB))
                      .withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => approval
                        ? TrackOrderScreen(order: order)
                        : TrackDriverScreen(order: order),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: approval
                                ? const [Color(0xFFFEF3C7), Color(0xFFFDE68A)]
                                : const [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: approval
                                ? const Color(0xFFFCD34D)
                                : const Color(0xFFBFDBFE),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          info.icon,
                          color: approval
                              ? const Color(0xFFB45309)
                              : const Color(0xFF1D4ED8),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: approval
                                        ? const Color(0xFFFEF3C7)
                                        : (arrived
                                            ? const Color(0xFFDCFCE7)
                                            : const Color(0xFFEFF6FF)),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: approval
                                          ? const Color(0xFFF59E0B)
                                          : (arrived
                                              ? const Color(0xFF22C55E)
                                              : const Color(0xFF3B82F6)),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: approval
                                              ? const Color(0xFFD97706)
                                              : (arrived
                                                  ? const Color(0xFF16A34A)
                                                  : const Color(0xFF2563EB)),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        approval
                                            ? 'ACTION REQUIRED'
                                            : (arrived ? 'OUTSIDE NOW' : 'EN ROUTE'),
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                          color: approval
                                              ? const Color(0xFFB45309)
                                              : (arrived
                                                  ? const Color(0xFF15803D)
                                                  : const Color(0xFF1D4ED8)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '#${order.orderId}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              info.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              approval
                                  ? 'Tap to review and approve counted items'
                                  : 'Tap to see live van tracking on map',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF475569),
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
