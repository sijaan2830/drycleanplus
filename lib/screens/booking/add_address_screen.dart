import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/booking_models.dart';
import '../../providers/booking_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/location_service.dart';
import '../../services/postcoder_service.dart';
import '../../widgets/app_ui.dart';

/// Add address screen matching 3_Add_Address.html mockup.
/// Integrates GPS reverse-geocoding, Postcoder postcode/eircode lookup,
/// and manual address entry with animated map illustration.
class AddAddressScreen extends StatefulWidget {
  final bool autoLocate;
  const AddAddressScreen({super.key, this.autoLocate = true});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _postcode = TextEditingController();
  final _label = TextEditingController();
  final _line1Focus = FocusNode();

  Timer? _debounce;
  String _country = 'uk'; // 'uk' | 'ie'
  String _chipLabel = 'Home'; // 'Home' | 'Work' | 'Other'

  // GPS
  bool _locating = false;
  LocationStatus? _locationStatus;
  String? _locationMessage;
  List<PostcoderAddress> _nearby = [];
  int? _selectedNearby;

  // Search
  bool _searching = false;
  String? _searchError;
  List<PostcoderAddress> _results = [];
  bool _searched = false;

  // Form
  bool _showForm = false;
  bool _needsHouseNumber = false;
  bool _saving = false;
  double? _selectedLat;
  double? _selectedLon;

  late AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    if (widget.autoLocate) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _locate());
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _debounce?.cancel();
    _searchController.dispose();
    _line1.dispose();
    _line2.dispose();
    _city.dispose();
    _postcode.dispose();
    _label.dispose();
    _line1Focus.dispose();
    super.dispose();
  }

  // ── GPS → Postcoder ───────────────────────────────────────────────────────

  Future<void> _locate() async {
    if (_locating) return;
    setState(() {
      _locating = true;
      _locationMessage = 'Finding your GPS coordinates…';
      _locationStatus = null;
      _selectedNearby = null;
    });

    final loc = await LocationService.getCurrentPosition();
    if (!mounted) return;

    if (!loc.ok) {
      setState(() {
        _locating = false;
        _locationStatus = loc.status;
        _locationMessage = _messageFor(loc.status);
      });
      return;
    }

    final lat = loc.position!.latitude;
    final lng = loc.position!.longitude;
    final accuracy = loc.position!.accuracy.round();

    setState(() {
      _locationMessage = 'GPS acquired (within ${accuracy}m). Extracting real-time address…';
    });

    var lookup = await PostcoderService.reverseGeocode(lat, lng, country: _country);
    if (lookup.items.isEmpty && _country == 'uk') {
      final ie = await PostcoderService.reverseGeocode(lat, lng, country: 'ie');
      if (ie.items.isNotEmpty) {
        lookup = ie;
        _country = 'ie';
      }
    }
    if (!mounted) return;

    setState(() {
      _locating = false;
      _nearby = lookup.items.take(10).toList();
      if (_nearby.isNotEmpty) {
        final top = _nearby.first;
        _selectedNearby = 0;

        // Auto-fill form in real-time
        _line1.text = top.line1;
        _line2.text = top.line2;
        _city.text = top.city;
        _postcode.text = top.postcode;
        _needsHouseNumber = top.streetOnly;
        _showForm = true;

        final display = [top.line1, top.city, top.postcode].where((e) => e.isNotEmpty).join(', ');
        _locationMessage = '📍 Found: $display. Check details and save.';
      } else {
        _locationMessage = lookup.error ??
            'We could not read the address at your coordinates. Enter it manually below.';
        _showForm = true;
      }
    });
  }

  String _messageFor(LocationStatus s) {
    switch (s) {
      case LocationStatus.serviceDisabled:
        return 'Location services are turned off on your phone.';
      case LocationStatus.denied:
        return 'Location permission was not granted.';
      case LocationStatus.deniedForever:
        return 'Location permission is blocked. Enable it in Settings to auto-fill your address.';
      case LocationStatus.error:
      case LocationStatus.ok:
        return 'We could not get your location. Try again or search by postcode.';
    }
  }

  // ── Search ────────────────────────────────────────────────────────────────

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final q = value.trim();
    setState(() {});
    if (q.length < 3) {
      setState(() {
        _results = [];
        _searching = false;
        _searched = false;
        _searchError = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 450), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    setState(() {
      _searching = true;
      _searchError = null;
    });
    final res = await PostcoderService.searchAddresses(q, country: _country);
    if (!mounted || _searchController.text.trim() != q) return;
    setState(() {
      _searching = false;
      _searched = true;
      _results = res.items;
      _searchError = res.error;
    });
  }

  // ── Apply / save ──────────────────────────────────────────────────────────

  void _apply(PostcoderAddress a) {
    FocusScope.of(context).unfocus();
    setState(() {
      _line1.text = a.line1;
      _line2.text = a.line2;
      _city.text = a.city;
      _postcode.text = a.postcode;
      _selectedLat = a.latitude;
      _selectedLon = a.longitude;
      _showForm = true;
      _needsHouseNumber = a.streetOnly;
      _results = [];
      _searched = false;
      _searchController.clear();
    });
    if (a.streetOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _line1Focus.requestFocus();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final address = Address(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      line1: _line1.text.trim(),
      line2: _line2.text.trim().isEmpty ? null : _line2.text.trim(),
      city: _city.text.trim(),
      postalCode: _postcode.text.trim().toUpperCase(),
      buildingName: _chipLabel == 'Home'
          ? 'Home'
          : (_chipLabel == 'Work'
              ? 'Work'
              : (_label.text.trim().isEmpty ? null : _label.text.trim())),
      isDefault: true,
      latitude: _selectedLat,
      longitude: _selectedLon,
    );

    final booking = Provider.of<BookingProvider>(context, listen: false);
    final user = Provider.of<UserProvider>(context, listen: false);

    await booking.addAddress(address);
    booking.setUserDefaultAddress(address);
    await user.saveAddressData(
      addressId: address.id,
      addressLine1: address.line1,
      addressLine2: address.line2,
      city: address.city,
      postcode: address.postalCode,
    );

    if (!mounted) return;
    setState(() => _saving = false);
    showAppSnack(context, 'Address saved');
    Navigator.of(context).pop(address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C61E4),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2F7BF5),
              Color(0xFF1C61E4),
              Color(0xFF1245B5),
            ],
            stops: [0.0, 0.45, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Decorative ambient circles
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
              left: -210,
              bottom: -160,
              child: Container(
                width: 420,
                height: 420,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top navigation bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Glass back button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.22),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'Add address',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 44),
                      ],
                    ),
                  ),

                  // Main content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 130),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hero title & subtitle
                            Text(
                              'Where should we collect from?',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'We find your address automatically. You can also search by postcode.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFDDE8FF),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Card 1: GPS Card with Map Banner
                            _buildGpsCard(),
                            const SizedBox(height: 16),

                            // Card 2: Search by postcode
                            _buildSearchCard(),
                            const SizedBox(height: 16),

                            // Card 3: Manual entry form (collapsible or shown)
                            if (_showForm) ...[
                              _buildManualFormCard(),
                              const SizedBox(height: 12),
                            ],

                            // "Enter address manually" button if form is hidden
                            if (!_showForm)
                              Center(
                                child: TextButton.icon(
                                  onPressed: () {
                                    setState(() => _showForm = true);
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white),
                                  label: Text(
                                    'Enter address manually',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Fixed bottom dock if manual form is active
            if (_showForm)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    14 + MediaQuery.of(context).padding.bottom,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        const Color(0xFF0A2468).withOpacity(0.85),
                      ],
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 448),
                      child: GestureDetector(
                        onTap: _saving ? null : _save,
                        child: Container(
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0xFFFFD25E), Color(0xFFFFB400)],
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFFB400).withOpacity(0.6),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_saving) ...[
                                const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Color(0xFF0B1F5B),
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ] else ...[
                                const Icon(
                                  Icons.check_rounded,
                                  color: Color(0xFF0B1F5B),
                                  size: 22,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                _saving ? 'SAVING...' : 'SAVE ADDRESS',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: const Color(0xFF0B1F5B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Card 1: GPS Card ───────────────────────────────────────────────────────

  Widget _buildGpsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF02104C).withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background soft pastel circle
          Positioned(
            right: -60,
            top: -70,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE8F0FF),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Map Banner (164px height)
                Container(
                  height: 164,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1553D6), Color(0xFF4F46E5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Map roads and buildings painter
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MapBackgroundPainter(),
                        ),
                      ),

                      // Bottom gradient overlay for readability
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 70,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                const Color(0xFF0A2468).withOpacity(0.65),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Center radar pin badge
                      Center(
                        child: AnimatedBuilder(
                          animation: _animCtrl,
                          builder: (context, child) {
                            final ping = _animCtrl.value;
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                if (_locating) ...[
                                  // Outer ripple
                                  Container(
                                    width: 52 + (ping * 36),
                                    height: 52 + (ping * 36),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity((1 - ping).clamp(0.0, 0.8)),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  // Second ripple
                                  Container(
                                    width: 52 + (((ping + 0.4) % 1.0) * 36),
                                    height: 52 + (((ping + 0.4) % 1.0) * 36),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(
                                          (1 - ((ping + 0.4) % 1.0)).clamp(0.0, 0.8),
                                        ),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ],
                                // Main white radar tile
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.25),
                                        spreadRadius: 8,
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withOpacity(0.12),
                                        spreadRadius: 18,
                                      ),
                                      BoxShadow(
                                        color: const Color(0xFF02104C).withOpacity(0.35),
                                        blurRadius: 18,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.my_location_rounded,
                                      color: Color(0xFF1553D6),
                                      size: 26,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                      // Top-right refresh button
                      Positioned(
                        right: 12,
                        top: 12,
                        child: GestureDetector(
                          onTap: _locate,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                            ),
                            child: Center(
                              child: _locating
                                  ? RotationTransition(
                                      turns: _animCtrl,
                                      child: const Icon(
                                        Icons.refresh_rounded,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.refresh_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                            ),
                          ),
                        ),
                      ),

                      // Bottom text info
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Addresses near you',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _locating
                                  ? 'Waiting for GPS…'
                                  : (_nearby.isNotEmpty
                                      ? 'Tap an address to auto-fill'
                                      : 'Uses your phone GPS'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.92),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Button: Use my current location (Gold gradient button)
                GestureDetector(
                  onTap: _locating ? null : _locate,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD25E), Color(0xFFFFB400)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFB400).withOpacity(0.55),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.near_me_rounded,
                          color: Color(0xFF0B1F5B),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _locating ? 'Finding you…' : 'Use my current location',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0B1F5B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Location message or error banner
                if (_locationMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _locationStatus != null && _locationStatus != LocationStatus.ok
                          ? const Color(0xFFFFEDEE)
                          : const Color(0xFFE8F0FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _locationStatus != null && _locationStatus != LocationStatus.ok
                              ? Icons.info_outline_rounded
                              : Icons.check_circle_outline_rounded,
                          color: _locationStatus != null && _locationStatus != LocationStatus.ok
                              ? const Color(0xFF8E1B28)
                              : const Color(0xFF1553D6),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _locationMessage!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              height: 1.4,
                              color: _locationStatus != null && _locationStatus != LocationStatus.ok
                                  ? const Color(0xFF8E1B28)
                                  : const Color(0xFF0B1F5B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_locationStatus != null && _locationStatus != LocationStatus.ok) ...[
                    const SizedBox(height: 10),
                    _buildPermissionButton(),
                  ],
                ],

                // Nearby addresses result list
                if (_nearby.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text(
                    '${_nearby.length} addresses found',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5B6B9A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...List.generate(_nearby.length, (i) {
                    final a = _nearby[i];
                    final isSel = _selectedNearby == i;
                    final subtitle = [
                      if (a.line2.isNotEmpty) a.line2,
                      a.city,
                      a.postcode
                    ].where((e) => e.isNotEmpty).join(', ');

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedNearby = i);
                          _apply(a);
                        },
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xFFFFF9E6) : const Color(0xFFF4F7FF),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSel ? const Color(0xFFFFC73A) : const Color(0xFFE4EBFB),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: Color(0xFF1553D6),
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      a.line1,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0B1F5B),
                                      ),
                                    ),
                                    if (subtitle.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF5B6B9A),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (a.streetOnly)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF1C7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Add house no.',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF7A5200),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionButton() {
    if (_locationStatus == LocationStatus.serviceDisabled) {
      return GestureDetector(
        onTap: () => LocationService.openLocationSettings(),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4EBFB), width: 1.5),
          ),
          child: Center(
            child: Text(
              'TURN ON LOCATION',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1553D6),
              ),
            ),
          ),
        ),
      );
    }
    if (_locationStatus == LocationStatus.deniedForever) {
      return GestureDetector(
        onTap: () => LocationService.openAppSettings(),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE4EBFB), width: 1.5),
          ),
          child: Center(
            child: Text(
              'OPEN SETTINGS',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1553D6),
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // ── Card 2: Postcode Search ────────────────────────────────────────────────

  Widget _buildSearchCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF02104C).withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Teal pastel backdrop circle
          Positioned(
            right: -60,
            top: -70,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFE4F7F0),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Teal gradient tile
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0B6E64), Color(0xFF12876F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0B6E64).withOpacity(0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.search_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Search by postcode',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0B1F5B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pick your address from the list',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF5B6B9A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Country Segmented Switcher (UK / Ireland)
                Container(
                  height: 42,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_country != 'uk') {
                              setState(() => _country = 'uk');
                              final q = _searchController.text.trim();
                              if (q.length >= 3) _runSearch(q);
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: _country == 'uk'
                                  ? const LinearGradient(
                                      colors: [Color(0xFF0B6E64), Color(0xFF12876F)],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: _country == 'uk'
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF0B6E64).withOpacity(0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'UK',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _country == 'uk'
                                      ? Colors.white
                                      : const Color(0xFF5B6B9A),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (_country != 'ie') {
                              setState(() => _country = 'ie');
                              final q = _searchController.text.trim();
                              if (q.length >= 3) _runSearch(q);
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: _country == 'ie'
                                  ? const LinearGradient(
                                      colors: [Color(0xFF0B6E64), Color(0xFF12876F)],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: _country == 'ie'
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF0B6E64).withOpacity(0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                'Ireland',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: _country == 'ie'
                                      ? Colors.white
                                      : const Color(0xFF5B6B9A),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Postcode search textfield
                Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE4EBFB), width: 2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF6B7BA8),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          textCapitalization: TextCapitalization.characters,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0B1F5B),
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: _country == 'uk'
                                ? 'Postcode, e.g. SW1A 1AA'
                                : 'Eircode, e.g. D02 X285',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7BA8),
                            ),
                          ),
                          onChanged: _onSearchChanged,
                          onSubmitted: (v) => _runSearch(v.trim()),
                        ),
                      ),
                      if (_searching)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Color(0xFF0B6E64),
                          ),
                        )
                      else if (_searchController.text.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                          child: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF6B7BA8),
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // Hint
                if (_results.isEmpty && !_searching && !_searched)
                  Text(
                    'Type at least 3 characters to see addresses.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5B6B9A),
                    ),
                  ),

                // No results found
                if (_searched && _results.isEmpty && _searchError == null && !_searching)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'No addresses found. Check the postcode or enter it manually below.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF5B6B9A),
                      ),
                    ),
                  ),

                // Search error
                if (_searchError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _searchError!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFC22A3A),
                      ),
                    ),
                  ),

                // Results list
                if (_results.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    '${_results.length} addresses found',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF5B6B9A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: _results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final a = _results[i];
                        final sub = [
                          if (a.line2.isNotEmpty) a.line2,
                          a.city,
                          a.postcode,
                        ].where((e) => e.isNotEmpty).join(', ');

                        return InkWell(
                          onTap: () => _apply(a),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F7FF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE4EBFB), width: 1.5),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.location_on_rounded,
                                  color: Color(0xFF0B6E64),
                                  size: 22,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.line1.isEmpty ? a.summary : a.line1,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0B1F5B),
                                        ),
                                      ),
                                      if (sub.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          sub,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF5B6B9A),
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
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Card 3: Manual Entry Form ──────────────────────────────────────────────

  Widget _buildManualFormCard() {
    String? validateRequired(String? v, String msg) =>
        (v == null || v.trim().isEmpty) ? msg : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF02104C).withOpacity(0.35),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Purple pastel backdrop circle
          Positioned(
            right: -60,
            top: -70,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEEF0FF),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    // Purple gradient tile
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4338CA), Color(0xFF6D4AFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4338CA).withOpacity(0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.edit_outlined, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter manually',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0B1F5B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Add the full address yourself',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF5B6B9A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_needsHouseNumber) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Please add your house or flat number below.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7A5200),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Chips for Home / Work / Other
                Row(
                  children: [
                    _buildChip('Home'),
                    const SizedBox(width: 8),
                    _buildChip('Work'),
                    const SizedBox(width: 8),
                    _buildChip('Other'),
                  ],
                ),
                const SizedBox(height: 14),

                // Address line 1
                _buildField(
                  controller: _line1,
                  focusNode: _line1Focus,
                  label: 'Address line 1',
                  hint: 'House number & street name',
                  validator: (v) => validateRequired(v, 'Address line 1 is required'),
                ),
                const SizedBox(height: 10),

                // Address line 2 (optional)
                _buildField(
                  controller: _line2,
                  label: 'Address line 2 (optional)',
                  hint: 'Flat, suite, unit (optional)',
                ),
                const SizedBox(height: 10),

                // Town / City and Postcode in two columns
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildField(
                        controller: _city,
                        label: 'Town or city',
                        hint: 'e.g. Nottingham',
                        validator: (v) => validateRequired(v, 'City required'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildField(
                        controller: _postcode,
                        label: 'Postcode',
                        hint: 'e.g. NG1 1AA',
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => validateRequired(v, 'Postcode required'),
                      ),
                    ),
                  ],
                ),
                if (_chipLabel == 'Other') ...[
                  const SizedBox(height: 10),
                  _buildField(
                    controller: _label,
                    label: 'Address label',
                    hint: "e.g. Mum's House, Gym",
                  ),
                ],
                const SizedBox(height: 16),

                // In-card "Save address" button
                GestureDetector(
                  onTap: _saving ? null : _save,
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD25E), Color(0xFFFFB400)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFB400).withOpacity(0.55),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _saving ? 'Saving...' : 'Save address',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0B1F5B),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    final isSel = _chipLabel == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _chipLabel = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 44,
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFFEEF0FF) : const Color(0xFFF4F7FF),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: isSel ? const Color(0xFF4338CA) : const Color(0xFFE4EBFB),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: isSel ? const Color(0xFF4338CA) : const Color(0xFF0B1F5B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String? hint,
    FocusNode? focusNode,
    TextCapitalization textCapitalization = TextCapitalization.words,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EBFB), width: 2),
      ),
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF6B7BA8),
            ),
          ),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            textCapitalization: textCapitalization,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0B1F5B),
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.only(top: 4, bottom: 2),
              border: InputBorder.none,
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7BA8).withOpacity(0.6),
              ),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom Painter for Map Banner Roads and Blocks
// ─────────────────────────────────────────────────────────────────────────────

class _MapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 400.0;
    final scaleY = size.height / 164.0;

    canvas.save();
    canvas.scale(scaleX, scaleY);

    final blockPaint = Paint()
      ..color = Colors.white.withOpacity(0.09)
      ..style = PaintingStyle.fill;

    // Building / block rects
    final blocks = [
      RRect.fromLTRBAndCorners(12, 14, 98, 66, topLeft: const Radius.circular(10), topRight: const Radius.circular(10), bottomLeft: const Radius.circular(10), bottomRight: const Radius.circular(10)),
      RRect.fromLTRBAndCorners(118, 14, 188, 66, topLeft: const Radius.circular(10), topRight: const Radius.circular(10), bottomLeft: const Radius.circular(10), bottomRight: const Radius.circular(10)),
      RRect.fromLTRBAndCorners(214, 14, 294, 48, topLeft: const Radius.circular(10), topRight: const Radius.circular(10), bottomLeft: const Radius.circular(10), bottomRight: const Radius.circular(10)),
      RRect.fromLTRBAndCorners(318, 14, 388, 84, topLeft: const Radius.circular(10), topRight: const Radius.circular(10), bottomLeft: const Radius.circular(10), bottomRight: const Radius.circular(10)),
      RRect.fromLTRBAndCorners(12, 90, 72, 150, topLeft: const Radius.circular(10), topRight: const Radius.circular(10), bottomLeft: const Radius.circular(10), bottomRight: const Radius.circular(10)),
      RRect.fromLTRBAndCorners(92, 90, 188, 150, topLeft: const Radius.circular(10), topRight: const Radius.circular(10), bottomLeft: const Radius.circular(10), bottomRight: const Radius.circular(10)),
      RRect.fromLTRBAndCorners(214, 72, 294, 150, topLeft: const Radius.circular(10), topRight: const Radius.circular(10), bottomLeft: const Radius.circular(10), bottomRight: const Radius.circular(10)),
      RRect.fromLTRBAndCorners(318, 106, 388, 150, topLeft: const Radius.circular(10), topRight: const Radius.circular(10), bottomLeft: const Radius.circular(10), bottomRight: const Radius.circular(10)),
    ];

    for (final b in blocks) {
      canvas.drawRRect(b, blockPaint);
    }

    // Road curve
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, 78);
    path.cubicTo(80, 70, 120, 94, 200, 78);
    path.cubicTo(280, 62, 330, 62, 400, 82);

    canvas.drawPath(path, roadPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
