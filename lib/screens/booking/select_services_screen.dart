import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/booking_provider.dart';
import '../../providers/service_provider.dart';
import '../../widgets/booking_ui.dart';
import '../service_overview_screen.dart';

/// Step 1 — pick the services you need. No item counting: our facility counts and
/// prices the bag, and you approve any change before cleaning.
class SelectServicesScreen extends StatefulWidget {
  const SelectServicesScreen({super.key});
  @override
  State<SelectServicesScreen> createState() => _SelectServicesScreenState();
}

class _SelectServicesScreenState extends State<SelectServicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sp = context.read<ServiceProvider>();
      if (sp.services.isEmpty) sp.initializeServicesListener();
    });
  }

  Future<void> _request(BookingProvider bp, String service) async {
    final text = await Navigator.of(context).push<String>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _RequestScreen(service: service, initial: bp.bookingData.serviceRequests[service] ?? ''),
    ));
    if (text != null) bp.setServiceRequest(service, text);
  }

  void _next(BookingProvider bp) {
    final picked = bp.bookingData.selectedServices;
    if (picked.isEmpty) return;
    // a bag booking never carries counted items (prepaid packs use their own flow)
    if (bp.selectedService != 'Prepaid Pack' && bp.bookingData.selectedItems.isNotEmpty) {
      bp.updateBookingData(bp.bookingData.copyWith(selectedItems: const {}));
    }
    bp.setSelectedService(picked.join(' + '));
    Navigator.of(context).pushNamed('/time_slots');
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BookingProvider>();
    final services = context.watch<ServiceProvider>().servicesAsMap;
    final picked = bp.bookingData.selectedServices;
    return Scaffold(
      backgroundColor: const Color(0xFF1245B5),
      extendBody: true, // the page continues behind the floating button
      appBar: const BookingTopBar(title: 'Select a service', step: 1, onBlue: true),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.bgGradient),
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 110), children: [
        Text('What can we clean for you?', style: BK.h(24, c: Colors.white)),
        const SizedBox(height: 6),
        Text('Pick one or more. Just pack everything in a bag — we count, check and price it at our facility.', style: BK.t(14, c: Colors.white.withValues(alpha: .85), w: FontWeight.w500, height: 1.45)),
        const SizedBox(height: 18),
        for (final s in services) ...[
          _ServiceCard(
            service: s,
            selected: picked.contains('${s['name']}'),
            request: bp.bookingData.serviceRequests['${s['name']}'],
            onToggle: () => bp.toggleBagService('${s['name']}'),
            onRequest: () => _request(bp, '${s['name']}'),
            onPrices: () => Navigator.of(context).push(MaterialPageRoute(settings: const RouteSettings(name: '/service_overview'), builder: (_) => ServiceOverviewScreen(serviceType: '${s['name']}', fromBooking: true))),
          ),
          const SizedBox(height: 14),
        ],
        if (services.isEmpty) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: Colors.white))),
        const SizedBox(height: 4),
        BkCard(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            const UiIcon('info', size: 30),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Not sure which to pick? Choose the closest — our team sorts everything at the facility, and you approve the price before we clean.',
                style: BK.t(13, c: BK.ink, w: FontWeight.w600, height: 1.4),
              ),
            ),
          ]),
        ),
      ]),
      ),
      bottomNavigationBar: BottomCta(
        label: 'Next',
        onTap: picked.isEmpty ? null : () => _next(bp),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final Map<String, dynamic> service;
  final bool selected;
  final String? request;
  final VoidCallback onToggle, onRequest, onPrices;
  const _ServiceCard({required this.service, required this.selected, required this.request, required this.onToggle, required this.onRequest, required this.onPrices});

  @override
  Widget build(BuildContext context) {
    final desc = '${service['description'] ?? ''}';
    return GestureDetector(
      onTap: onToggle,
      child: BkCard(
        selected: selected,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            serviceSectionIcon(service, size: 58),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${service['name']}', style: BK.h(18.5)),
                const SizedBox(height: 4),
                Text(
                  selected ? 'Service added' : (desc.isEmpty ? 'Collected, cleaned and returned in 24–48 h.' : desc),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: BK.t(13.5, c: selected ? BK.blue : BK.mut, w: selected ? FontWeight.w700 : FontWeight.w500, height: 1.35),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: onPrices,
                  child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('Prices & more', style: BK.t(14, c: BK.blue, w: FontWeight.w800))),
                ),
              ]),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? BK.blue : Colors.white,
                border: Border.all(color: selected ? BK.blue : BK.line, width: 2),
              ),
              child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
            ),
          ]),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: !selected
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Material(
                      color: BK.blueSoft,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: onRequest,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                          child: Row(children: [
                            const UiIcon('request', size: 26),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                request == null ? 'Add special request' : '“$request”',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: request == null ? TextAlign.center : TextAlign.start,
                                style: BK.t(14.5, c: request == null ? BK.blue : BK.ink, w: FontWeight.w800),
                              ),
                            ),
                            if (request != null) const UiIcon('edit', size: 22),
                          ]),
                        ),
                      ),
                    ),
                  ),
          ),
        ]),
      ),
    );
  }
}

/// Full-screen "Add special request" (cleaning instructions for one service).
class _RequestScreen extends StatefulWidget {
  final String service, initial;
  const _RequestScreen({required this.service, required this.initial});
  @override
  State<_RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends State<_RequestScreen> {
  late final _c = TextEditingController(text: widget.initial)..addListener(() => setState(() {}));
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          titleSpacing: 20,
          title: Row(children: [const UiIcon('request', size: 30), const SizedBox(width: 10), Text('Add special request', style: BK.h(20))]),
          actions: [IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded, size: 28, color: BK.ink))],
        ),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          Text(widget.service, style: BK.t(13, c: BK.mut, w: FontWeight.w700)),
          const SizedBox(height: 8),
          TextField(
            controller: _c,
            autofocus: true,
            minLines: 4,
            maxLines: 8,
            maxLength: 300,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Please add any special cleaning instructions — e.g. “No starch on shirts”, “Stain on the left sleeve”.',
              hintStyle: BK.t(14.5, c: BK.mut, w: FontWeight.w500),
              filled: true,
              fillColor: BK.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: BK.line)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: BK.line)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: BK.blue, width: 1.6)),
            ),
            style: BK.t(15, w: FontWeight.w600),
          ),
          if (widget.initial.isNotEmpty)
            TextButton.icon(onPressed: () => Navigator.pop(context, ''), icon: const Icon(Icons.delete_outline_rounded), label: const Text('Remove request')),
        ]),
        bottomNavigationBar: BottomCta(label: 'Add', onBlue: false, onTap: _c.text.trim().isEmpty ? null : () => Navigator.pop(context, _c.text.trim())),
      );
}
