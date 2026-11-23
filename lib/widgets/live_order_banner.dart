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
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => approval ? TrackOrderScreen(order: order) : TrackDriverScreen(order: order))),
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [BoxShadow(color: Color(0x40061A52), blurRadius: 26, offset: Offset(0, 12), spreadRadius: -12)],
                ),
                child: Row(children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: approval ? const Color(0xFFFFF1DC) : AppColors.skyTint,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(info.icon, color: approval ? const Color(0xFFB45309) : AppColors.primaryBlue, size: 26),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        if (!approval) ...[
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text(arrived ? 'OUTSIDE NOW' : 'LIVE', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: .8, color: AppColors.success)),
                          const SizedBox(width: 8),
                        ],
                        Text('#${order.orderId}', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.muted)),
                      ]),
                      const SizedBox(height: 2),
                      Text(info.label, style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      Text(approval ? 'Tap to review and approve' : 'Tap to see your driver on the map',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
                    ]),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}
