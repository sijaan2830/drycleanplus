import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';

import '../models/booking_models.dart' as models;
import '../utils/order_status.dart';
import '../widgets/booking_ui.dart';
import '../widgets/live_tracking_card.dart';

/// Road route between two points. The free OSRM demo server is fine for testing;
/// for the store release use a keyed router (Google Routes, Mapbox, …) — only this line changes.
const String kRoutingUrl = 'https://router.project-osrm.org/route/v1/driving/';

/// Full-screen live tracking: map with the van on its road route, ETA header,
/// driver card (call / message), order details and hand-over method.
class TrackDriverScreen extends StatefulWidget {
  final models.Order order;
  const TrackDriverScreen({super.key, required this.order});
  @override
  State<TrackDriverScreen> createState() => _TrackDriverScreenState();
}

class _TrackDriverScreenState extends State<TrackDriverScreen> {
  final _db = FirebaseFirestore.instance;
  late final _live = _db.collection('live_tracking').doc(widget.order.orderId).snapshots();
  late final _orderDoc = _db.collection('orders').doc(widget.order.id).snapshots();
  late final _site = _db.collection('settings').doc('website').snapshots();
  final _map = GlobalKey<_TrackMapState>();
  int? _routeMins; // minutes left on the road route (more accurate than the driver's straight-line guess)
  late final Timer _tick = Timer.periodic(const Duration(seconds: 30), (_) {
    if (mounted) setState(() {}); // re-check "last update" while no GPS arrives
  });

  @override
  void initState() {
    super.initState();
    _tick; // start the clock
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  String _phone(Map<String, dynamic>? site) => '${site?['phone'] ?? ''}'.trim().isEmpty ? kSupportPhone : '${site!['phone']}';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _orderDoc,
      builder: (context, oSnap) {
        final o = oSnap.data?.data() ?? const <String, dynamic>{};
        final status = normalizeOrderStatus('${o['status'] ?? widget.order.status}');
        final delivery = status.contains('deliver') || status == 'out_for_delivery';
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _live,
          builder: (context, lSnap) {
            final live = lSnap.data?.data();
            return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: _site,
              builder: (context, sSnap) {
                final phone = _phone(sSnap.data?.data());
                final van = (live?['lat'] as num?) == null ? null : LatLng((live!['lat'] as num).toDouble(), (live['lng'] as num).toDouble());
                final dest = live?['destination'] is Map ? LatLng(((live!['destination'] as Map)['lat'] as num).toDouble(), ((live['destination'] as Map)['lng'] as num).toDouble()) : null;
                final arrived = live?['state'] == 'arrived' || status.endsWith('_arrived');
                final phase = live == null ? (delivery ? 'delivery' : 'pickup') : '${live['phase']}';
                final eta = _routeMins ?? (live?['etaMinutes'] as num?)?.toInt();
                // the driver app sends a point when moving and once a minute when standing;
                // nothing for 5 min = app closed or no signal → don't pretend it's live
                final seen = live?['updatedAt'];
                final quiet = seen is Timestamp ? DateTime.now().difference(seen.toDate()).inMinutes : 0;
                final stale = van != null && !arrived && quiet >= 5;
                final top = MediaQuery.paddingOf(context).top;
                return Scaffold(
                  backgroundColor: BK.bg,
                  body: Stack(children: [
                    Positioned.fill(
                      child: _TrackMap(
                        key: _map,
                        van: van,
                        heading: (live?['heading'] as num?)?.toDouble() ?? -1,
                        destination: dest,
                        postcode: _postcode(o),
                        onMinutes: (m) {
                          if (m != _routeMins) setState(() => _routeMins = m);
                        },
                        topInset: top + 150,
                        bottomInset: MediaQuery.sizeOf(context).height * .44,
                      ),
                    ),
                    // header
                    Positioned(
                      top: top + 10,
                      left: 14,
                      right: 14,
                      child: Column(children: [
                        Row(children: [
                          _Round(icon: Icons.arrow_back_rounded, onTap: () => Navigator.of(context).maybePop()),
                          const Spacer(),
                          _Round(icon: Icons.my_location_rounded, onTap: () => _map.currentState?.recenter()),
                        ]),
                        const SizedBox(height: 10),
                        _Header(phase: phase, eta: stale ? null : eta, arrived: arrived, waiting: live == null, status: status, quietMin: stale ? quiet : null),
                      ]),
                    ),
                    // details sheet
                    DraggableScrollableSheet(
                      initialChildSize: .40,
                      minChildSize: .26,
                      maxChildSize: .78,
                      builder: (context, scroll) => Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(28)), boxShadow: BK.shadow(.25)),
                        child: ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(18, 10, 18, 30), children: [
                          Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: BK.line, borderRadius: BorderRadius.circular(9)))),
                          const SizedBox(height: 14),
                          _DriverRow(live: live, arrived: arrived, phone: phone, orderId: widget.order.orderId),
                          const SizedBox(height: 16),
                          const Divider(color: BK.line, height: 1),
                          const SizedBox(height: 14),
                          Row(children: [
                            Text('Order details', style: BK.t(13.5, c: BK.mut, w: FontWeight.w700)),
                            const Spacer(),
                            Text('#${widget.order.orderId}', style: BK.t(13.5, c: BK.mut, w: FontWeight.w700)),
                          ]),
                          const SizedBox(height: 8),
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const UiIcon('pin', size: 28),
                            const SizedBox(width: 10),
                            Expanded(child: Text(_address(o, delivery), style: BK.t(15, w: FontWeight.w600, height: 1.4))),
                          ]),
                          const SizedBox(height: 16),
                          const Divider(color: BK.line, height: 1),
                          const SizedBox(height: 14),
                          Text(delivery ? 'Delivery method' : 'Collection method', style: BK.t(13.5, c: BK.mut, w: FontWeight.w700)),
                          const SizedBox(height: 8),
                          _MethodRow(order: o, docId: widget.order.id, delivery: delivery),
                          const SizedBox(height: 16),
                          _Steps(status: status),
                        ]),
                      ),
                    ),
                  ]),
                );
              },
            );
          },
        );
      },
    );
  }

  static Map<String, dynamic> _b(Map<String, dynamic> o) => o['bookingData'] is Map ? Map<String, dynamic>.from(o['bookingData']) : const {};

  String _postcode(Map<String, dynamic> o) {
    final a = _b(o)['selectedAddress'];
    return a is Map ? '${a['postalCode'] ?? ''}' : (widget.order.bookingData.selectedAddress?.postalCode ?? '');
  }

  String _address(Map<String, dynamic> o, bool delivery) {
    final b = _b(o);
    final a = (delivery ? b['deliveryAddress'] : null) ?? b['selectedAddress'];
    if (a is Map) return [a['buildingName'], a['line1'], a['line2'], a['city'], a['postalCode']].where((e) => '${e ?? ''}'.trim().isNotEmpty).join(', ');
    return widget.order.bookingData.selectedAddress?.fullAddress ?? 'Your address';
  }
}

// ======================================================================= header
class _Header extends StatelessWidget {
  final String phase, status;
  final int? eta;
  final bool arrived, waiting;
  final int? quietMin; // set when the driver's GPS has gone quiet
  const _Header({required this.phase, required this.eta, required this.arrived, required this.waiting, required this.status, this.quietMin});
  @override
  Widget build(BuildContext context) {
    final delivery = phase == 'delivery';
    final small = arrived ? 'Your driver is here' : waiting ? orderStatusInfo(status).label : quietMin != null ? 'Last update $quietMin min ago' : 'Driver arriving soon';
    final big = arrived
        ? 'Outside your door'
        : waiting
            ? 'Live map starts when your driver sets off'
            : '${delivery ? 'Delivery' : 'Collection'} ${eta == null ? 'on the way' : eta! <= 1 ? 'arriving now' : 'in $eta mins'}';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: BK.shadow(.18)),
      child: Row(children: [
        UiIcon(arrived ? 'success' : waiting ? 'clock' : 'truck', size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(small, style: BK.t(13, c: BK.mut, w: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(big, style: BK.h(waiting ? 17 : 22)),
          ]),
        ),
        if (!waiting && !arrived && quietMin == null) const _LiveDot(),
      ]),
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(99)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: (1 - _c.value) * .5), spreadRadius: 5 * _c.value)],
              ),
            ),
            const SizedBox(width: 6),
            Text('LIVE', style: BK.t(11.5, c: const Color(0xFF15803D), w: FontWeight.w800)),
          ]),
        ),
      );
}

class _Round extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Round({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: Colors.black26,
        child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: Padding(padding: const EdgeInsets.all(11), child: Icon(icon, color: BK.ink, size: 23))),
      );
}

// ======================================================================= driver
class _DriverRow extends StatelessWidget {
  final Map<String, dynamic>? live;
  final bool arrived;
  final String phone, orderId;
  const _DriverRow({required this.live, required this.arrived, required this.phone, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final name = '${live?['driverFirstName'] ?? 'Your driver'}';
    final vehicle = [live?['vehicle'], if ('${live?['regEnding'] ?? ''}'.isNotEmpty) '…${live!['regEnding']}'].where((e) => '${e ?? ''}'.isNotEmpty).join(' · ');
    final tel = phone.replaceAll(RegExp(r'[^+\d]'), '');
    return Row(children: [
      Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(color: BK.blue, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(name.isEmpty ? 'D' : name[0].toUpperCase(), style: BK.h(22, c: Colors.white)),
        ),
        const Positioned(right: -6, bottom: -4, child: UiIcon('truck', size: 26)),
      ]),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: BK.h(18)),
          const SizedBox(height: 2),
          Text(arrived ? 'is outside now' : live == null ? 'will set off soon' : 'will arrive soon', style: BK.t(13.5, c: BK.mut, w: FontWeight.w600)),
          if (vehicle.isNotEmpty) Text(vehicle, style: BK.t(12.5, c: BK.mut, w: FontWeight.w500)),
        ]),
      ),
      _Action(icon: Icons.call_rounded, onTap: () => launchUrl(Uri.parse('tel:$tel'))),
      const SizedBox(width: 10),
      _Action(icon: Icons.chat_bubble_outline_rounded, onTap: () => launchUrl(Uri.parse('sms:$tel?body=${Uri.encodeComponent('Hi, about order #$orderId: ')}'))),
    ]);
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
        color: BK.blueSoft,
        shape: const CircleBorder(),
        child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: Padding(padding: const EdgeInsets.all(12), child: Icon(icon, color: BK.blue, size: 22))),
      );
}

// ======================================================================= method
const _deliveryMethods = ['Deliver to me in person', 'Leave at my door', 'Leave with reception / concierge', 'Leave with a neighbour'];
const _collectionMethods = ['Collect from me in person', 'Collect from outside my door', 'Collect from reception / concierge'];

class _MethodRow extends StatelessWidget {
  final Map<String, dynamic> order;
  final String docId;
  final bool delivery;
  const _MethodRow({required this.order, required this.docId, required this.delivery});

  Future<void> _edit(BuildContext context, String current, String note) async {
    final res = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: (_) => _MethodSheet(options: delivery ? _deliveryMethods : _collectionMethods, current: current, note: note),
    );
    if (res == null) return;
    final db = FirebaseFirestore.instance;
    final ref = db.collection('orders').doc(docId);
    final b = db.batch();
    b.update(ref, {
      delivery ? 'bookingData.deliveryMethod' : 'bookingData.collectionMethod': res.$1,
      'customerNote': res.$2,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // the driver's job card shows it straight away
    final jobId = '${order[delivery ? 'deliveryJobId' : 'pickupJobId'] ?? ''}';
    if (jobId.isNotEmpty) b.update(db.collection('jobs').doc(jobId), {'handoff': res.$1, 'customerNote': res.$2});
    await b.commit();
  }

  @override
  Widget build(BuildContext context) {
    final b = order['bookingData'] is Map ? Map<String, dynamic>.from(order['bookingData']) : const <String, dynamic>{};
    final method = '${b[delivery ? 'deliveryMethod' : 'collectionMethod'] ?? (delivery ? _deliveryMethods.first : _collectionMethods.first)}';
    final note = '${order['customerNote'] ?? ''}';
    return InkWell(
      onTap: () => _edit(context, method, note),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
        decoration: BoxDecoration(color: BK.bg, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const UiIcon('handoff', size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(method, style: BK.t(15, w: FontWeight.w700)),
              if (note.isNotEmpty) Text('“$note”', maxLines: 2, overflow: TextOverflow.ellipsis, style: BK.t(13, c: BK.mut, w: FontWeight.w500)),
            ]),
          ),
          Container(width: 36, height: 36, padding: const EdgeInsets.all(7), decoration: const BoxDecoration(color: BK.blueSoft, shape: BoxShape.circle), child: const UiIcon('edit')),
        ]),
      ),
    );
  }
}

class _MethodSheet extends StatefulWidget {
  final List<String> options;
  final String current, note;
  const _MethodSheet({required this.options, required this.current, required this.note});
  @override
  State<_MethodSheet> createState() => _MethodSheetState();
}

class _MethodSheetState extends State<_MethodSheet> {
  late String _sel = widget.options.contains(widget.current) ? widget.current : widget.options.first;
  late final _note = TextEditingController(text: widget.note);
  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [const UiIcon('handoff', size: 30), const SizedBox(width: 10), Text('How should we hand over?', style: BK.h(19))]),
          const SizedBox(height: 12),
          for (final o in widget.options)
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              value: o,
              groupValue: _sel,
              activeColor: BK.blue,
              onChanged: (v) => setState(() => _sel = v!),
              title: Text(o, style: BK.t(15, w: FontWeight.w600)),
            ),
          const SizedBox(height: 6),
          TextField(
            controller: _note,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Note for your driver (gate code, flat number…)',
              prefixIcon: const Padding(padding: EdgeInsets.all(10), child: UiIcon('note', size: 22)),
              filled: true,
              fillColor: BK.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, (_sel, _note.text.trim())),
              style: FilledButton.styleFrom(backgroundColor: BK.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: Text('SAVE', style: BK.t(15, c: Colors.white, w: FontWeight.w800)),
            ),
          ),
        ]),
      );
}

// ======================================================================= steps
class _Steps extends StatelessWidget {
  final String status;
  const _Steps({required this.status});
  @override
  Widget build(BuildContext context) {
    final step = orderStatusInfo(status).step;
    return Row(children: [
      for (var i = 0; i < kOrderSteps.length; i++) ...[
        Expanded(
          child: Column(children: [
            Container(height: 5, decoration: BoxDecoration(color: i <= step ? BK.blue : BK.line, borderRadius: BorderRadius.circular(9))),
            const SizedBox(height: 6),
            Text(kOrderSteps[i].$1, maxLines: 1, overflow: TextOverflow.ellipsis, style: BK.t(10.5, c: i <= step ? BK.ink : BK.mut, w: i == step ? FontWeight.w800 : FontWeight.w600)),
          ]),
        ),
        if (i < kOrderSteps.length - 1) const SizedBox(width: 6),
      ],
    ]);
  }
}

// ======================================================================= map
class _TrackMap extends StatefulWidget {
  final LatLng? van, destination;
  final double heading, topInset, bottomInset;
  final String postcode;
  final ValueChanged<int>? onMinutes;
  const _TrackMap({super.key, required this.van, required this.heading, required this.destination, required this.postcode, required this.topInset, required this.bottomInset, this.onMinutes});
  @override
  State<_TrackMap> createState() => _TrackMapState();
}

class _TrackMapState extends State<_TrackMap> with SingleTickerProviderStateMixin {
  final _map = MapController();
  late final _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..addListener(_tick);
  LatLng? _from, _to, _shown, _home;
  double _bearing = 0;
  bool _ready = false, _follow = true;
  List<LatLng> _route = const [];
  LatLng? _routeFrom;
  DateTime _routeAt = DateTime(2000);
  final _trail = <LatLng>[];

  @override
  void initState() {
    super.initState();
    _shown = _to = widget.van;
    _home = widget.destination;
    if (widget.van != null) _trail.add(widget.van!);
    if (_home == null && widget.postcode.isNotEmpty) _geocode();
    _maybeRoute();
  }

  Future<void> _geocode() async {
    try {
      final r = await http.get(Uri.parse('https://api.postcodes.io/postcodes/${widget.postcode.replaceAll(' ', '')}')).timeout(const Duration(seconds: 6));
      final j = jsonDecode(r.body)['result'];
      if (!mounted || j == null) return;
      setState(() => _home = LatLng((j['latitude'] as num).toDouble(), (j['longitude'] as num).toDouble()));
      _fit();
    } catch (_) {}
  }

  /// Fetch the road route; refresh when the van has gone 150 m off it or after 60 s.
  Future<void> _maybeRoute() async {
    final a = _to, b = widget.destination ?? _home;
    if (a == null || b == null) return;
    final moved = _routeFrom == null ? 1e9 : const Distance().as(LengthUnit.Meter, _routeFrom!, a);
    if (moved < 150 && DateTime.now().difference(_routeAt) < const Duration(seconds: 60)) return;
    _routeFrom = a;
    _routeAt = DateTime.now();
    try {
      final r = await http.get(Uri.parse('$kRoutingUrl${a.longitude},${a.latitude};${b.longitude},${b.latitude}?overview=full&geometries=geojson')).timeout(const Duration(seconds: 8));
      final route = (jsonDecode(r.body)['routes'] as List).first;
      final coords = route['geometry']['coordinates'] as List;
      if (mounted) setState(() => _route = [for (final c in coords) LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())]);
      final secs = (route['duration'] as num?)?.toDouble();
      if (mounted && secs != null) widget.onMinutes?.call(math.max(1, (secs / 60).round()));
    } catch (_) {
      if (mounted) setState(() => _route = const []); // straight dashed line instead
    }
  }

  @override
  void didUpdateWidget(covariant _TrackMap old) {
    super.didUpdateWidget(old);
    if (widget.destination != null && widget.destination != _home) _home = widget.destination;
    final v = widget.van;
    if (v != null && v != _to) {
      _from = _shown ?? v;
      _to = v;
      _trail.add(v);
      if (widget.heading > 0) {
        _bearing = widget.heading;
      } else if (const Distance().as(LengthUnit.Meter, _from!, v) > 3) {
        _bearing = const Distance().bearing(_from!, v);
      }
      _anim.forward(from: 0);
      _maybeRoute();
      if (_follow) _fit();
    }
  }

  void _tick() {
    final f = _from, t = _to;
    if (f == null || t == null) return;
    final k = Curves.easeInOut.transform(_anim.value);
    setState(() => _shown = LatLng(f.latitude + (t.latitude - f.latitude) * k, f.longitude + (t.longitude - f.longitude) * k));
  }

  void recenter() {
    setState(() => _follow = true);
    _fit();
  }

  void _fit() {
    if (!_ready) return;
    final pts = [if (_shown != null) _shown!, if (_home != null) _home!];
    if (pts.isEmpty) return;
    final pad = EdgeInsets.fromLTRB(50, widget.topInset, 50, widget.bottomInset + 20);
    if (pts.length == 1) {
      _map.move(pts.first, 15.5);
    } else {
      _map.fitCamera(CameraFit.coordinates(coordinates: pts, padding: pad, maxZoom: 16.5));
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final van = _shown, home = _home;
    final route = _route.length > 1 ? [if (van != null) van, ..._route] : (van != null && home != null ? [van, home] : <LatLng>[]);
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: van ?? home ?? const LatLng(51.5074, -0.1278),
        initialZoom: 14.5,
        interactionOptions: const InteractionOptions(flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom),
        onMapReady: () {
          _ready = true;
          _fit();
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
        if (_trail.length > 1) PolylineLayer(polylines: [Polyline(points: List.of(_trail), strokeWidth: 5, color: BK.blue.withValues(alpha: .35))]),
        if (route.length > 1)
          PolylineLayer(polylines: [
            Polyline(points: route, strokeWidth: 9, color: Colors.white),
            Polyline(
              points: route,
              strokeWidth: 5.5,
              color: BK.blue,
              pattern: _route.length > 1 ? const StrokePattern.solid() : StrokePattern.dashed(segments: const [12, 9]),
            ),
          ]),
        MarkerLayer(markers: [
          if (home != null) Marker(point: home, width: 44, height: 52, alignment: Alignment.topCenter, child: const HomePinMarker()),
          if (van != null)
            Marker(
              point: van,
              width: 72,
              height: 72,
              child: Transform.rotate(angle: (_bearing - 90) * math.pi / 180, child: const CustomPaint(painter: VanPainter())),
            ),
        ]),
        const RichAttributionWidget(attributions: [TextSourceAttribution('Google Maps'), TextSourceAttribution('OSRM')], alignment: AttributionAlignment.bottomLeft),
      ],
    );
  }
}
