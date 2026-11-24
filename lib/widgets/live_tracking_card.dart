import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';

import '../config/theme.dart';
import '../models/booking_models.dart' as models;
import '../screens/track_driver_screen.dart';
import '../utils/order_status.dart';

/// Map tiles. OpenStreetMap is fine for testing; for the store release switch to a
/// keyed provider (MapTiler, Mapbox, Stadia…) — only this line needs to change.
const String kMapTilesUrl = 'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}';
const String kSupportPhone = '01636918181';

double _asDouble(dynamic val, [double fallback = 0.0]) {
  if (val == null) return fallback;
  if (val is num) return val.toDouble();
  final s = val.toString().replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(s) ?? fallback;
}

int _asInt(dynamic val, [int fallback = 1]) {
  if (val == null) return fallback;
  if (val is num) return val.toInt();
  final s = val.toString().replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(s) ?? fallback;
}

/// Live driver map for one order.
///
/// The driver app writes `live_tracking/{orderId}` while the driver is on the way
/// (lat, lng, heading, etaMinutes, distanceMeters, state, destination, driver name,
/// vehicle) and deletes it when the stop is finished. This card listens to that
/// document, so the van moves on the customer's screen in real time.
class LiveTrackingCard extends StatefulWidget {
  final models.Order order;
  const LiveTrackingCard({super.key, required this.order});

  @override
  State<LiveTrackingCard> createState() => _LiveTrackingCardState();
}

class _LiveTrackingCardState extends State<LiveTrackingCard> {
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _stream;
  String _for = '';

  Stream<DocumentSnapshot<Map<String, dynamic>>> _streamFor(String orderId) {
    if (_stream == null || _for != orderId) {
      _for = orderId;
      _stream = FirebaseFirestore.instance.collection('live_tracking').doc(orderId).snapshots();
    }
    return _stream!;
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    if (order.orderId.isEmpty) return const SizedBox.shrink();
    final live = isLiveOrderStatus(order.status);
    final cancelled = normalizeOrderStatus(order.status) == 'cancelled';
    final delivered = isOrderDelivered(order.status);

    // Live driver card ONLY appears when driver is actively on the way (en route / arrived)
    if (!live || cancelled || delivered) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _streamFor(order.orderId),
      builder: (context, snap) {
        final data = snap.data?.data();
        if (data == null) {
          return const Padding(padding: EdgeInsets.only(bottom: 30), child: _WaitingCard());
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: Ticker30(
            builder: (_) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _LiveCard(data: data),
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TrackDriverScreen(order: order))),
                  icon: const Icon(Icons.open_in_full_rounded, size: 19),
                  label: Text('Track driver full screen', style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800)),
                  style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primaryBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: _shadow),
      child: Row(children: [
        const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primaryBlue)),
        const SizedBox(width: 14),
        Expanded(
          child: Text('Connecting to your driver’s live location…',
              style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
        ),
      ]),
    );
  }
}

const _shadow = [BoxShadow(color: Color(0x33081F5C), blurRadius: 30, offset: Offset(0, 14), spreadRadius: -12)];

class _LiveCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _LiveCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final lat = data['lat'] != null ? _asDouble(data['lat']) : null;
    final lng = data['lng'] != null ? _asDouble(data['lng']) : null;
    final dest = (data['destination'] as Map?)?.cast<String, dynamic>();
    final destLat = dest != null && dest['lat'] != null ? _asDouble(dest['lat']) : null;
    final destLng = dest != null && dest['lng'] != null ? _asDouble(dest['lng']) : null;
    final destLL = (destLat != null && destLng != null && destLat != 0.0) ? LatLng(destLat, destLng) : null;
    final arrived = data['state'] == 'arrived';
    final pickup = data['phase'] != 'delivery';
    final eta = data['etaMinutes'] != null ? _asInt(data['etaMinutes']) : null;
    final meters = data['distanceMeters'] != null ? _asInt(data['distanceMeters']) : null;
    final name = '${data['driverFirstName'] ?? 'Your driver'}';
    final vehicle = [data['vehicle'], if ('${data['regEnding'] ?? ''}'.isNotEmpty) '…${data['regEnding']}'].where((e) => e != null && '$e'.isNotEmpty).join(' · ');
    final updated = (data['updatedAt'] as Timestamp?)?.toDate();

    final title = arrived ? '$name is outside' : (pickup ? '$name is on the way to collect' : 'Your order is on the way');
    final etaText = arrived
        ? 'Arrived'
        : eta == null
            ? 'On the way'
            : eta <= 1
                ? 'Arriving now'
                : '$eta min';

    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(26), boxShadow: _shadow),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        SizedBox(
          height: 250,
          child: Stack(children: [
            if (lat != null && lng != null)
              Positioned.fill(child: _LiveMap(van: LatLng(lat, lng), heading: _asDouble(data['heading'], -1), destination: destLL))
            else
              const Positioned.fill(child: ColoredBox(color: Color(0xFFEEF3F8), child: Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)))),
            Positioned(left: 12, top: 12, child: _Chip(live: true, text: 'Live')),
            Positioned(
              right: 12,
              top: 12,
              child: _Chip(text: etaText, strong: true, color: arrived ? AppColors.success : AppColors.primaryBlue),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 3),
            Text(
              arrived
                  ? (pickup ? 'Please hand over your bags at the door.' : 'Your clean clothes are at your door.')
                  : [
                      if (meters != null) meters >= 1000 ? '${(meters / 1000).toStringAsFixed(1)} km away' : '$meters m away',
                      _ago(updated),
                    ].where((e) => e.isNotEmpty).join(' · '),
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.lightGrey, borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primaryBlue,
                  child: Text(name.isEmpty ? 'D' : name[0].toUpperCase(), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: GoogleFonts.plusJakartaSans(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
                    Text(vehicle.isEmpty ? 'DryClean Plus driver' : vehicle,
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.muted)),
                  ]),
                ),
                Material(
                  color: AppColors.primaryBlue,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => launchUrl(Uri.parse('tel:$kSupportPhone')),
                    child: const Padding(padding: EdgeInsets.all(11), child: Icon(Icons.call_rounded, color: Colors.white, size: 20)),
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }

  static String _ago(DateTime? t) {
    if (t == null) return '';
    final s = DateTime.now().difference(t).inSeconds;
    if (s < 45) return 'Updated just now';
    if (s < 3600) return 'Updated ${(s / 60).round()} min ago';
    return '';
  }
}

class _Chip extends StatelessWidget {
  final String text;
  final bool live, strong;
  final Color color;
  const _Chip({required this.text, this.live = false, this.strong = false, this.color = AppColors.ink});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: strong ? color : Colors.white,
        borderRadius: BorderRadius.circular(99),
        boxShadow: const [BoxShadow(color: Color(0x33081F5C), blurRadius: 14, offset: Offset(0, 6), spreadRadius: -6)],
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (live) const _Pulse(),
        if (live) const SizedBox(width: 7),
        Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: strong ? Colors.white : AppColors.ink)),
      ]),
    );
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse();
  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.success.withValues(alpha: (1 - _c.value) * .55), spreadRadius: 6 * _c.value)],
          ),
        ),
      );
}

/// Map that glides the van between GPS updates (they arrive every few seconds).
class _LiveMap extends StatefulWidget {
  final LatLng van;
  final double heading; // degrees from north, -1 when unknown
  final LatLng? destination;
  const _LiveMap({required this.van, required this.heading, this.destination});

  @override
  State<_LiveMap> createState() => _LiveMapState();
}

class _LiveMapState extends State<_LiveMap> with SingleTickerProviderStateMixin {
  final _map = MapController();
  late final AnimationController _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..addListener(_tick);
  late LatLng _from = widget.van, _to = widget.van, _shown = widget.van;
  late double _bearing = widget.heading >= 0 ? widget.heading : 0;
  bool _follow = true, _ready = false;

  @override
  void didUpdateWidget(covariant _LiveMap old) {
    super.didUpdateWidget(old);
    if (widget.van != _to) {
      _from = _shown;
      _to = widget.van;
      final moved = const Distance().as(LengthUnit.Meter, _from, _to);
      if (widget.heading >= 0) {
        _bearing = widget.heading;
      } else if (moved > 3) {
        _bearing = const Distance().bearing(_from, _to);
      }
      _anim.forward(from: 0);
      if (_follow) _fit(_to);
    }
  }

  void _tick() {
    final t = Curves.easeInOut.transform(_anim.value);
    setState(() => _shown = LatLng(_from.latitude + (_to.latitude - _from.latitude) * t, _from.longitude + (_to.longitude - _from.longitude) * t));
  }

  void _fit(LatLng van) {
    if (!_ready) return;
    final d = widget.destination;
    if (d == null) {
      _map.move(van, 16);
    } else {
      _map.fitCamera(CameraFit.coordinates(coordinates: [van, d], padding: const EdgeInsets.fromLTRB(46, 64, 46, 40), maxZoom: 16.5));
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.destination;
    return Stack(children: [
      FlutterMap(
        mapController: _map,
        options: MapOptions(
          initialCenter: widget.van,
          initialZoom: 15,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom),
          onMapReady: () {
            _ready = true;
            _fit(_shown);
          },
          onPositionChanged: (_, byUser) {
            if (byUser && _follow) setState(() => _follow = false);
          },
        ),
        children: [
          TileLayer(
            urlTemplate: kMapTilesUrl,
            subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
            maxZoom: 20,
            userAgentPackageName: 'com.drycleanplus.service.uk.app',
          ),
          if (d != null)
            PolylineLayer(polylines: [
              Polyline(points: [_shown, d], strokeWidth: 4, color: AppColors.primaryBlue.withValues(alpha: .55), pattern: StrokePattern.dashed(segments: const [10, 8])),
            ]),
          MarkerLayer(markers: [
            if (d != null) Marker(point: d, width: 44, height: 52, alignment: Alignment.topCenter, child: const HomePinMarker()),
            Marker(
              point: _shown,
              width: 64,
              height: 64,
              child: Transform.rotate(angle: (_bearing - 90) * math.pi / 180, child: const CustomPaint(painter: VanPainter())),
            ),
          ]),
          const RichAttributionWidget(attributions: [TextSourceAttribution('Google Maps')], alignment: AttributionAlignment.bottomLeft),
        ],
      ),
      if (!_follow)
        Positioned(
          right: 12,
          bottom: 12,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 3,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                setState(() => _follow = true);
                _fit(_shown);
              },
              child: const Padding(padding: EdgeInsets.all(10), child: Icon(Icons.my_location_rounded, color: AppColors.primaryBlue, size: 22)),
            ),
          ),
        ),
    ]);
  }
}

class HomePinMarker extends StatelessWidget {
  const HomePinMarker();
  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.ink,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: const [BoxShadow(color: Color(0x55081F5C), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
      ),
      CustomPaint(size: const Size(12, 9), painter: _TipPainter()),
    ]);
  }
}

class _TipPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) => c.drawPath(Path()..moveTo(0, 0)..lineTo(s.width, 0)..lineTo(s.width / 2, s.height)..close(), Paint()..color = AppColors.ink);
  @override
  bool shouldRepaint(_) => false;
}

/// Top-down DryClean Plus van, nose pointing right (east); rotated by the caller.
class VanPainter extends CustomPainter {
  const VanPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    final k = size.width / 64 * 1.15;
    canvas.scale(k);
    RRect r(double x, double y, double w, double h, double rad) => RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(rad));
    final p = Paint();
    canvas.drawRRect(r(-21.5, -9.5, 46, 23, 6), p..color = const Color(0x33081F5C)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2));
    p.maskFilter = null;
    p.color = const Color(0xFF1F2937);
    for (final o in [const Offset(-16, -12.6), const Offset(11.5, -12.6), const Offset(-16, 9), const Offset(11.5, 9)]) {
      canvas.drawRRect(r(o.dx, o.dy, 8.5, 3.6, 1.6), p);
    }
    p.color = AppColors.ink;
    canvas.drawRRect(r(8.2, -15, 3, 4.4, 1.3), p);
    canvas.drawRRect(r(8.2, 10.6, 3, 4.4, 1.3), p);
    canvas.drawRRect(r(-23, -11, 46, 22, 5), p..color = Colors.white);
    canvas.drawRRect(r(-23, -11, 46, 22, 5), Paint()..color = const Color(0xFFC9D3E6)..style = PaintingStyle.stroke..strokeWidth = .8);
    canvas.drawRRect(r(-21, -9, 31, 18, 3), p..color = AppColors.primaryBlue);
    canvas.drawRRect(r(-21, -9, 3.2, 18, 1.2), p..color = const Color(0xFFFDE047));
    canvas.drawCircle(const Offset(-2, 0), 5.4, p..color = Colors.white);
    final tp = TextPainter(
      text: TextSpan(text: 'DC', style: GoogleFonts.plusJakartaSans(fontSize: 5.4, fontWeight: FontWeight.w900, color: AppColors.primaryBlue)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(-2 - tp.width / 2, -tp.height / 2));
    canvas.drawPath(
      Path()
        ..moveTo(11.6, -9)
        ..quadraticBezierTo(15.6, -9.6, 17.6, -8)
        ..lineTo(17.6, 8)
        ..quadraticBezierTo(15.6, 9.6, 11.6, 9)
        ..close(),
      p..color = const Color(0xFF1E293B),
    );
    p.color = const Color(0xFFFDE68A);
    canvas.drawRRect(r(21.3, -9, 1.7, 3.2, .8), p);
    canvas.drawRRect(r(21.3, 5.8, 1.7, 3.2, .8), p);
    p.color = const Color(0xFFEF4444);
    canvas.drawRRect(r(-23, -9.2, 1.3, 3.6, .6), p);
    canvas.drawRRect(r(-23, 5.6, 1.3, 3.6, .6), p);
  }

  @override
  bool shouldRepaint(_) => false;
}

/// Shown when our facility found extra items or damage: the customer approves the new total.
class ApprovalCard extends StatefulWidget {
  final models.Order order;
  const ApprovalCard({super.key, required this.order});

  @override
  State<ApprovalCard> createState() => _ApprovalCardState();
}

class _ApprovalCardState extends State<ApprovalCard> {
  bool _busy = false;
  late final Stream<Map<String, dynamic>?> _doc = orderDocStream(widget.order.id);

  Future<void> _approve() async {
    setState(() => _busy = true);
    try {
      final db = FirebaseFirestore.instance;
      final ref = db.collection('orders').doc(widget.order.id);
      final b = db.batch();
      b.update(ref, {'status': 'cleaning', 'approval.status': 'approved', 'approval.respondedAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()});
      b.set(ref.collection('history').doc(), {'status': 'cleaning', 'at': FieldValue.serverTimestamp(), 'byRole': 'customer', 'note': 'New total approved in the app'});
      await b.commit();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Couldn’t send your approval. Please try again.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<Map<String, dynamic>?>(
        stream: _doc,
        builder: (context, snap) => _card(context, snap.data ?? const {}),
      );

  Widget _card(BuildContext context, Map<String, dynamic> docData) {
    final a = (docData['approval'] as Map?)?.cast<String, dynamic>() ?? const {};
    final amountVal = a['amount'] ?? docData['transactionAmount'] ?? docData['totalAmount'] ?? docData['finalAmount'];
    final prevVal = a['previousAmount'] ?? docData['pricing']?['estimated'] ?? docData['pricing']?['total'];
    final double? amount = amountVal != null ? _asDouble(amountVal) : null;
    final double? prev = prevVal != null ? _asDouble(prevVal) : null;
    final note = a['notes']?.toString() ?? a['note']?.toString() ?? '';

    // Extract counted items
    final List<Map<String, dynamic>> itemsList = [];
    final rawItems = docData['items'] ??
        docData['selectedItems'] ??
        docData['bookingData']?['selectedItems'];

    if (rawItems is List) {
      for (final itm in rawItems) {
        if (itm is Map) {
          itemsList.add(Map<String, dynamic>.from(itm));
        }
      }
    } else if (rawItems is Map) {
      rawItems.forEach((k, v) {
        if (v is Map) {
          final q = _asInt(v['quantity'] ?? v['qty'], 1);
          final p = _asDouble(v['unitPrice'] ?? v['price'], 0.0);
          itemsList.add({
            'name': k.toString(),
            'qty': q,
            'quantity': q,
            'unitPrice': p,
            'price': p,
            'total': p * q,
          });
        }
      });
    }

    // Fallback to order items if still empty
    if (itemsList.isEmpty && widget.order.bookingData.selectedItems.isNotEmpty) {
      widget.order.bookingData.selectedItems.forEach((k, v) {
        final p = v.numericPrice;
        itemsList.add({
          'name': v.itemType.isNotEmpty ? v.itemType : k,
          'qty': 1,
          'quantity': 1,
          'unitPrice': p,
          'price': p,
          'total': p,
        });
      });
    }

    final delta = (amount != null && prev != null) ? (amount - prev) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFFFB020), width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33B45309),
            blurRadius: 26,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Accent Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                ),
                border: Border(bottom: BorderSide(color: Color(0xFFFFD7A8))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.pending_actions_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ACTION REQUIRED',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: const Color(0xFFC2410C),
                          ),
                        ),
                        Text(
                          'Review & Approve Counted Items',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF431407),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (delta != 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: delta > 0 ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: delta > 0 ? const Color(0xFFFCA5A5) : const Color(0xFF86EFAC),
                        ),
                      ),
                      child: Text(
                        '${delta > 0 ? '+' : ''}£${delta.abs().toStringAsFixed(2)}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: delta > 0 ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content Body
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Our facility team has counted and inspected your clothes. Please check the itemized breakdown below:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                      height: 1.4,
                    ),
                  ),

                  // Optional inspector note
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.sticky_note_2_rounded, size: 18, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              note,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF334155),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Itemized Table
                  if (itemsList.isNotEmpty) ...[
                    Text(
                      'COUNTED GARMENTS (${itemsList.length})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < itemsList.length; i++) ...[
                            if (i > 0) const Divider(height: 1, color: Color(0xFFE2E8F0)),
                            Builder(builder: (context) {
                              final itm = itemsList[i];
                              final name = itm['itemType']?.toString() ?? itm['name']?.toString() ?? 'Garment';
                              final qty = _asInt(itm['quantity'] ?? itm['qty'], 1);
                              final uPrice = _asDouble(itm['unitPrice'] ?? itm['price'], 0.0);
                              final lineTot = _asDouble(itm['total'], uPrice * qty);

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF2FF),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.checkroom_rounded, size: 15, color: Color(0xFF4F46E5)),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xFFCBD5E1)),
                                      ),
                                      child: Text(
                                        '×$qty',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF334155),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      '£${lineTot.toStringAsFixed(2)}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Price Summary Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL DUE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: const Color(0xFF4338CA),
                              ),
                            ),
                            if (prev != null && amount != null && prev != amount)
                              Text(
                                'Was £${prev.toStringAsFixed(2)}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                        Text(
                          amount != null ? '£${amount.toStringAsFixed(2)}' : 'Pending',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF1E1B4B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Action Buttons
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => launchUrl(Uri.parse('tel:$kSupportPhone')),
                        icon: const Icon(Icons.phone_rounded, size: 16),
                        label: const Text('Call Us'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(100, 48),
                          foregroundColor: const Color(0xFF334155),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _busy ? null : _approve,
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_circle_rounded, size: 18),
                          label: Text(
                            _busy ? 'Approving...' : 'Approve & Clean',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            backgroundColor: const Color(0xFF0E3AA8),
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Raw order document stream — for fields the Order model doesn't carry (approval).
Stream<Map<String, dynamic>?> orderDocStream(String docId) =>
    FirebaseFirestore.instance.collection('orders').doc(docId).snapshots().map((d) => d.data());

/// Re-renders every 30 s so "Updated x min ago" stays honest even without new GPS points.
class Ticker30 extends StatefulWidget {
  final WidgetBuilder builder;
  const Ticker30({super.key, required this.builder});
  @override
  State<Ticker30> createState() => _Ticker30State();
}

class _Ticker30State extends State<Ticker30> {
  late final Timer _t = Timer.periodic(const Duration(seconds: 30), (_) => setState(() {}));
  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
