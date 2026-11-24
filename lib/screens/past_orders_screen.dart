import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/theme.dart';
import '../models/booking_models.dart' as models;
import '../utils/order_status.dart';
import '../widgets/order_card_widget.dart';
import '../widgets/persistent_footer_app.dart';
import 'track_order_screen.dart';

class PastOrdersScreen extends StatefulWidget {
  const PastOrdersScreen({super.key});

  @override
  State<PastOrdersScreen> createState() => _PastOrdersScreenState();
}

class _PastOrdersScreenState extends State<PastOrdersScreen> {
  bool _isLoading = true;

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      final state = persistentFooterAppState ?? persistentFooterKey.currentState;
      if (state != null && state.tabHistory.length > 1) {
        state.tabHistory.removeLast();
        final prevTab = state.tabHistory.last;
        state.setTab(prevTab, addToHistory: false);
      } else {
        Navigator.of(context).pushReplacementNamed('/more');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _openTrack(models.Order order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrackOrderScreen(order: order),
        settings: const RouteSettings(name: '/track_order'),
      ),
    );
  }

  models.Order _parseOrder(Map<String, dynamic> data, String id) {
    try {
      final copy = Map<String, dynamic>.from(data);
      copy['id'] = copy['id'] ?? id;
      return models.Order.fromJson(copy);
    } catch (_) {
      final total = (data['transactionAmount'] ?? data['totalAmount'] ?? data['totalPrice'] ?? 0.0);
      final totalVal = total is num ? total.toDouble() : 0.0;
      final createdAt = data['createdAt'];
      return models.Order(
        id: id,
        orderId: (data['orderId'] ?? data['id'] ?? id).toString(),
        bookingData: models.BookingData(
          totalPrice: totalVal,
        ),
        transactionAmount: totalVal,
        type: (data['type'] ?? 'regular').toString(),
        status: (data['status'] ?? 'delivered').toString(),
        createdAt: createdAt is Timestamp ? createdAt.toDate() : DateTime.now(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Scaffold(
        backgroundColor: const Color(0xFF1245B5),
        body: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.bgGradient,
          ),
          child: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                // Soft background ambient circles
                Positioned(
                  right: -150,
                  top: -140,
                  child: Container(
                    width: 360,
                    height: 360,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                ),
                Positioned(
                  left: -230,
                  top: 720,
                  child: Container(
                    width: 420,
                    height: 420,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                ),

                Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: _isLoading
                          ? const _PastSkeleton()
                          : user == null
                              ? _message(
                                  icon: Icons.lock_outline_rounded,
                                  title: 'Sign in required',
                                  text: 'Please sign in to view your past orders.',
                                )
                              : StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('orders')
                                      .where('userId', isEqualTo: user.uid)
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const _PastSkeleton();
                                    }
                                    if (snapshot.hasError) {
                                      return _message(
                                        icon: Icons.error_outline_rounded,
                                        title: 'Could not load orders',
                                        text: 'Please check your connection and try again.',
                                      );
                                    }

                                    final docs = snapshot.data?.docs ?? [];
                                    final sorted = docs.toList()
                                      ..sort((a, b) {
                                        final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                                        final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                                        if (aTime == null) return 1;
                                        if (bTime == null) return -1;
                                        return bTime.compareTo(aTime);
                                      });

                                    final past = sorted.where((doc) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      return isOrderDelivered((data['status'] ?? '').toString());
                                    }).toList();

                                    if (past.isEmpty) {
                                      return _message(
                                        icon: Icons.history_rounded,
                                        title: 'No past orders yet',
                                        text: 'Your delivered orders will appear here.',
                                      );
                                    }

                                    return ListView.builder(
                                      physics: const AlwaysScrollableScrollPhysics(
                                        parent: BouncingScrollPhysics(),
                                      ),
                                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                                      itemCount: past.length,
                                      itemBuilder: (context, i) {
                                        final data = past[i].data() as Map<String, dynamic>;
                                        final order = _parseOrder(data, past[i].id);
                                        return Center(
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 480),
                                            child: OrderCardWidget(
                                              order: order,
                                              onTrack: () => _openTrack(order),
                                              onReorder: () => Navigator.of(context).pushNamed('/home'),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          Material(
            color: Colors.white.withOpacity(0.18),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _goBack,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.22), width: 1.5),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Past orders',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _message({required IconData icon, required String title, required String text}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 104,
              height: 104,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.14),
                border: Border.all(color: Colors.white.withOpacity(0.22)),
              ),
              child: Icon(icon, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.4,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PastSkeleton extends StatelessWidget {
  const _PastSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: 2,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 24),
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(26),
        ),
      ),
    );
  }
}
