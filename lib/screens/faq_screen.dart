import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';

void _faqBack(BuildContext context) {
  if (Navigator.of(context).canPop()) {
    Navigator.of(context).pop();
  } else {
    Navigator.of(context).pushReplacementNamed('/more');
  }
}

/// Help & FAQ Screen matching Help.html mockup.
class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final TextEditingController _search = TextEditingController();
  final MapController _coverageMap = MapController();
  String _query = '';
  String _selectedCategory = 'All';
  int? _openIndex;
  int _selectedHub = 0; // 0 = All Hubs, 1 = Walsall, 2 = Newark, 3 = Barnsley, 4 = Stockton

  // Category styling data
  static const Map<String, _CatMeta> _categories = {
    'All': _CatMeta('All', Color(0xFF1553D6), Color(0xFF4F95FF), Color(0xFFE1ECFF)),
    'Getting started': _CatMeta('Getting started', Color(0xFF1553D6), Color(0xFF4F95FF), Color(0xFFE1ECFF)),
    'Orders': _CatMeta('Orders', Color(0xFF4338CA), Color(0xFF8B5CF6), Color(0xFFE9E2FF)),
    'Payment': _CatMeta('Payment', Color(0xFFF26B00), Color(0xFFFFC53D), Color(0xFFFFEBB8)),
    'Service': _CatMeta('Service', Color(0xFF0B8F7A), Color(0xFF34D9AE), Color(0xFFD9F6EC)),
    'Delivery': _CatMeta('Delivery', Color(0xFF0A7BBF), Color(0xFF38B6FF), Color(0xFFDDF1FF)),
    'Account': _CatMeta('Account', Color(0xFFD92D62), Color(0xFFFF8AA5), Color(0xFFFFE1E8)),
  };

  final List<_FaqItem> _faqList = const [
    _FaqItem(
      category: 'Getting started',
      question: 'Can you clean my item?',
      answer: 'We clean all types of garments, plus duvets, bedding and household items. Not sure about something? Call or email us before you book.',
    ),
    _FaqItem(
      category: 'Getting started',
      question: 'How do I place an order?',
      answer: 'Tap Book now in the bottom bar, add your items, choose collection and delivery, then pay now or pay later.',
    ),
    _FaqItem(
      category: 'Orders',
      question: 'What are order statuses?',
      answer: 'Your order goes through clear stages: Pending confirmation, Items collected, Cleaning in progress, Quality check, Out for delivery, and Delivered.',
    ),
    _FaqItem(
      category: 'Payment',
      question: 'How do prepaid packs work?',
      answer: 'Prepaid packs let you buy cleaning credit in advance at a discount. Credits are automatically applied to your orders when available.',
    ),
    _FaqItem(
      category: 'Service',
      question: 'How to prepare?',
      answer: 'Pack one service per bag (e.g. Wash & Iron in one bag, Dry Clean in another). Tag each bag with the requested service, and have them ready for our driver.',
    ),
    _FaqItem(
      category: 'Payment',
      question: 'Pricing and payment',
      answer: 'Our pricing is clear and competitive. We accept all major cards (Visa, Mastercard, Amex). Invoices are sent via email after item processing.',
    ),
    _FaqItem(
      category: 'Payment',
      question: 'How is final price calculated?',
      answer: 'The price estimated during booking is a guide. The final price reflects actual count, weight, or complexity of items confirmed at our facility.',
    ),
    _FaqItem(
      category: 'Orders',
      question: 'How can I track my order?',
      answer: 'Open More, then Orders to follow your active orders in real time with driver status and estimated arrival times.',
    ),
    _FaqItem(
      category: 'Service',
      question: 'What services do you offer?',
      answer: 'Dry cleaning for all garments, laundry and ironing, duvet and bedding cleaning, household item cleaning, and collection and delivery.',
    ),
    _FaqItem(
      category: 'Account',
      question: 'How do I manage my account?',
      answer: 'Open More and tap your profile card to update your address and contact details, view prepaid credits, log out, or delete your account.',
    ),
    _FaqItem(
      category: 'Service',
      question: 'Where is DryClean Plus available?',
      answer: 'We provide free doorstep collection & delivery across 4 major UK regional hubs (Walsall, Newark-on-Trent, Barnsley, Stockton-on-Tees) and all surrounding 0–20 mile coverage areas.',
      isMap: true,
    ),
    _FaqItem(
      category: 'Delivery',
      question: 'What are your delivery times?',
      answer: 'We offer multiple 30-minute time slots throughout the day for collection and delivery, Monday through Saturday.',
    ),
    _FaqItem(
      category: 'Orders',
      question: 'How do I cancel or modify an order?',
      answer: 'You can cancel or modify your order free of charge up to 2 hours before your scheduled collection time directly in the app or by calling us.',
    ),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_FaqItem> get _filteredList {
    return _faqList.where((item) {
      final matchesCat = _selectedCategory == 'All' || item.category == _selectedCategory;
      if (!matchesCat) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return item.question.toLowerCase().contains(q) || item.answer.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _filteredList;

    return Scaffold(
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
            // Ambient glow circles
            Positioned(
              right: -140,
              top: -120,
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              left: -200,
              top: 500,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),

            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Sticky Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Glass back button
                        GestureDetector(
                          onTap: () => _faqBack(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.2),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.28),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'Help & FAQ',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 38),
                      ],
                    ),
                  ),

                  // Main Scrollable Area
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 480),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Hero Title & Subtitle
                              Text(
                                'How can we help?',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 27,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Search or pick a topic below.',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFDCE8FF),
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Search Bar
                              Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF02104C).withValues(alpha: 0.35),
                                      blurRadius: 22,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.search_rounded,
                                      color: Color(0xFF5B6B9A),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextField(
                                        controller: _search,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF0B1F5B),
                                        ),
                                        decoration: InputDecoration(
                                          border: InputBorder.none,
                                          hintText: 'Search questions',
                                          hintStyle: GoogleFonts.plusJakartaSans(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF8A97BE),
                                          ),
                                        ),
                                        onChanged: (v) => setState(() => _query = v.trim()),
                                      ),
                                    ),
                                    if (_search.text.isNotEmpty)
                                      GestureDetector(
                                        onTap: () {
                                          _search.clear();
                                          setState(() => _query = '');
                                        },
                                        child: const Icon(
                                          Icons.close_rounded,
                                          color: Color(0xFF5B6B9A),
                                          size: 18,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Category Chips
                              SizedBox(
                                height: 36,
                                child: ListView(
                                  scrollDirection: Axis.horizontal,
                                  children: _categories.keys.map((catKey) {
                                    final isSel = _selectedCategory == catKey;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: GestureDetector(
                                        onTap: () => setState(() => _selectedCategory = catKey),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 180),
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          decoration: BoxDecoration(
                                            color: isSel ? Colors.white : Colors.white.withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(999),
                                            border: Border.all(
                                              color: isSel ? Colors.white : Colors.white.withValues(alpha: 0.26),
                                              width: 1.5,
                                            ),
                                            boxShadow: isSel
                                                ? [
                                                    BoxShadow(
                                                      color: const Color(0xFF02104C).withValues(alpha: 0.25),
                                                      blurRadius: 12,
                                                      offset: const Offset(0, 4),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Center(
                                            child: Text(
                                              catKey,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: isSel ? const Color(0xFF0B1F5B) : Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // FAQ List Cards
                              if (visibleItems.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 40, bottom: 20),
                                  child: Column(
                                    children: [
                                      Text(
                                        'No questions found',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Try a different word or topic.',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFFDCE8FF),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                ...List.generate(visibleItems.length, (i) {
                                  final item = visibleItems[i];
                                  final catMeta = _categories[item.category] ?? _categories['All']!;
                                  final isOpen = _openIndex == i;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 9),
                                    child: _buildFaqCard(
                                      item: item,
                                      catMeta: catMeta,
                                      isOpen: isOpen,
                                      onToggle: () {
                                        setState(() {
                                          _openIndex = isOpen ? null : i;
                                        });
                                      },
                                    ),
                                  );
                                }),
                              const SizedBox(height: 14),

                              // "Still need help?" Help Card
                              _buildStillNeedHelpCard(),
                            ],
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
      ),
    );
  }

  // ── FAQ Card with Category Color Stripe ────────────────────────────────────

  Widget _buildFaqCard({
    required _FaqItem item,
    required _CatMeta catMeta,
    required bool isOpen,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF02104C).withValues(alpha: 0.35),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Left 4px vertical colored stripe
            Positioned(
              left: 0,
              top: 14,
              bottom: 14,
              width: 4,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [catMeta.colorA, catMeta.colorB],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              catMeta.label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: catMeta.colorA,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.question,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0B1F5B),
                                height: 1.3,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Circle chevron or map icon
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOpen ? catMeta.colorA : catMeta.tint,
                        ),
                        child: Center(
                          child: Icon(
                            isOpen
                                ? Icons.keyboard_arrow_up_rounded
                                : (item.isMap ? Icons.map_outlined : Icons.keyboard_arrow_down_rounded),
                            size: 16,
                            color: isOpen ? Colors.white : catMeta.colorA,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isOpen) ...[
                    const SizedBox(height: 12),
                    if (item.isMap)
                      _buildInlineCoverageMap()
                    else
                      Text(
                        item.answer,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF34457D),
                          height: 1.55,
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

  // ── "Still need help?" Card ───────────────────────────────────────────────

  Widget _buildStillNeedHelpCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF02104C).withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1553D6), Color(0xFF4F95FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1553D6).withValues(alpha: 0.4),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.headset_mic_rounded, color: Colors.white, size: 23),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Still need help?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0B1F5B),
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Our team is happy to help.',
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

          // Two buttons in a grid: Email us & Call us
          Row(
            children: [
              // Email us button
              Expanded(
                child: GestureDetector(
                  onTap: () => _launchUrl('mailto:contact@drycleanplus.co.uk'),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1553D6), Color(0xFF4F95FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1553D6).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.mail_outline_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Email us',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Call us button
              Expanded(
                child: GestureDetector(
                  onTap: () => _launchUrl('tel:01636918181'),
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4338CA), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4338CA).withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Call us',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
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

  // ── Inline Coverage Map for "Where is DryClean Plus available?" ─────────────

  static const List<_CoverageHubData> _hubs = [
    _CoverageHubData(
      name: 'Walsall Hub',
      region: 'West Midlands',
      center: LatLng(52.5862, -1.9829),
      zoom: 9.3,
      color: Color(0xFF1553D6),
      postcodes: 'WS, B, WV, DY, CV, ST, TF',
      innerTowns: [
        'West Bromwich (4 mi)',
        'Wolverhampton (6 mi)',
        'Dudley (6 mi)',
        'Sutton Coldfield (6 mi)',
        'Cannock (7 mi)',
        'Birmingham (8 mi)',
        'Lichfield (9 mi)',
        'Halesowen (9 mi)',
        'Stourbridge (10 mi)',
      ],
      outerTowns: [
        'Tamworth (12 mi)',
        'Solihull (14 mi)',
        'Stafford (16 mi)',
        'Kidderminster (17 mi)',
        'Redditch (19 mi)',
        'Telford (20 mi)',
        'Coventry',
      ],
    ),
    _CoverageHubData(
      name: 'Newark-on-Trent Hub',
      region: 'Nottinghamshire',
      center: LatLng(53.0768, -0.8090),
      zoom: 9.3,
      color: Color(0xFF059669),
      postcodes: 'NG, LN, DN',
      innerTowns: [
        'Southwell (7 mi)',
      ],
      outerTowns: [
        'Bingham (11 mi)',
        'Grantham (13 mi)',
        'Arnold (14 mi)',
        'Lincoln (15 mi)',
        'Nottingham (16 mi)',
        'West Bridgford (16 mi)',
        'Hucknall (16 mi)',
        'Mansfield (16 mi)',
        'Retford (17 mi)',
        'Sleaford (17 mi)',
        'Sutton-in-Ashfield (19 mi)',
        'Worksop (20 mi)',
      ],
    ),
    _CoverageHubData(
      name: 'Barnsley Hub',
      region: 'South Yorkshire',
      center: LatLng(53.5526, -1.4797),
      zoom: 9.3,
      color: Color(0xFFD97706),
      postcodes: 'S, WF, LS, HD, HX, BD',
      innerTowns: [
        'Wakefield (9 mi)',
      ],
      outerTowns: [
        'Rotherham (11 mi)',
        'Dewsbury (12 mi)',
        'Sheffield (13 mi)',
        'Huddersfield (14 mi)',
        'Pontefract (14 mi)',
        'Doncaster (15 mi)',
        'Leeds (19 mi)',
        'Bradford (20 mi)',
        'Halifax (20 mi)',
      ],
    ),
    _CoverageHubData(
      name: 'Stockton-on-Tees Hub',
      region: 'Teesside & Durham',
      center: LatLng(54.5694, -1.3195),
      zoom: 9.3,
      color: Color(0xFF7C3AED),
      postcodes: 'TS, DL, DH, SR',
      innerTowns: [
        'Thornaby-on-Tees (2 mi)',
        'Billingham (3 mi)',
        'Middlesbrough (4 mi)',
        'Yarm (4 mi)',
        'Redcar (10 mi)',
      ],
      outerTowns: [
        'Darlington (11 mi)',
        'Hartlepool (11 mi)',
        'Guisborough (11 mi)',
        'Newton Aycliffe (12 mi)',
        'Bishop Auckland (17 mi)',
        'Durham (18 mi)',
        'Northallerton (18 mi)',
      ],
    ),
  ];

  Widget _buildInlineCoverageMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'We collect & deliver directly to your doorstep across 4 major UK operational hubs and surrounding towns (0–20 miles radius):',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF34457D),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),

        // Quick Hub Selector Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              _buildHubFilterChip(
                label: 'All 4 Hubs (UK)',
                isSelected: _selectedHub == 0,
                color: const Color(0xFF1553D6),
                onTap: () {
                  setState(() => _selectedHub = 0);
                  _coverageMap.move(const LatLng(53.5, -1.5), 6.8);
                },
              ),
              const SizedBox(width: 8),
              ..._hubs.asMap().entries.map((entry) {
                final idx = entry.key + 1;
                final hub = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildHubFilterChip(
                    label: hub.name.replaceAll(' Hub', ''),
                    isSelected: _selectedHub == idx,
                    color: hub.color,
                    onTap: () {
                      setState(() => _selectedHub = idx);
                      _coverageMap.move(hub.center, hub.zoom);
                    },
                  ),
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Interactive Map Card
        Container(
          height: 270,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _coverageMap,
                options: const MapOptions(
                  initialCenter: LatLng(53.5, -1.5),
                  initialZoom: 6.8,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                    subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
                    maxZoom: 20,
                    userAgentPackageName: 'com.drycleanplus.service.uk.app',
                  ),
                  CircleLayer(
                    circles: _hubs.map((hub) {
                      return CircleMarker(
                        point: hub.center,
                        radius: 28000,
                        useRadiusInMeter: true,
                        color: hub.color.withValues(alpha: 0.18),
                        borderColor: hub.color.withValues(alpha: 0.85),
                        borderStrokeWidth: 2,
                      );
                    }).toList(),
                  ),
                  MarkerLayer(
                    markers: _hubs.asMap().entries.map((entry) {
                      final idx = entry.key + 1;
                      final hub = entry.value;
                      final isCurrent = _selectedHub == idx;
                      return Marker(
                        point: hub.center,
                        width: 140,
                        height: 54,
                        alignment: Alignment.center,
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _selectedHub = idx);
                            _coverageMap.move(hub.center, hub.zoom);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isCurrent ? hub.color : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: hub.color,
                                width: isCurrent ? 2 : 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: hub.color.withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 16,
                                  color: isCurrent ? Colors.white : hub.color,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    hub.name.replaceAll(' Hub', ''),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: isCurrent ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // Top Live Coverage Badge
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '0–20 Miles Doorstep Service',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0B1F5B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Zoom & Recenter Controls Overlay
              Positioned(
                bottom: 10,
                right: 10,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildMapControlBtn(
                      icon: Icons.add_rounded,
                      onTap: () {
                        _coverageMap.move(
                          _coverageMap.camera.center,
                          (_coverageMap.camera.zoom + 0.8).clamp(5.0, 15.0),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    _buildMapControlBtn(
                      icon: Icons.remove_rounded,
                      onTap: () {
                        _coverageMap.move(
                          _coverageMap.camera.center,
                          (_coverageMap.camera.zoom - 0.8).clamp(5.0, 15.0),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                    _buildMapControlBtn(
                      icon: Icons.my_location_rounded,
                      onTap: () {
                        setState(() => _selectedHub = 0);
                        _coverageMap.move(const LatLng(53.5, -1.5), 6.8);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Hub Details Accordion / List
        ..._hubs.asMap().entries.map((entry) {
          final idx = entry.key + 1;
          final hub = entry.value;
          final isSelected = _selectedHub == idx;
          return _buildHubDetailCard(hub, idx, isSelected);
        }),

        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF1D4ED8)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Don\'t see your location? We are actively expanding across the UK. Get in touch to check upcoming routes in your postcode!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E40AF),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHubFilterChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _buildMapControlBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 18, color: const Color(0xFF0F172A)),
        ),
      ),
    );
  }

  Widget _buildHubDetailCard(_CoverageHubData hub, int index, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? hub.color.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? hub.color : const Color(0xFFE2E8F0),
          width: isSelected ? 1.6 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              _selectedHub = isSelected ? 0 : index;
            });
            if (_selectedHub == index) {
              _coverageMap.move(hub.center, hub.zoom);
            } else {
              _coverageMap.move(const LatLng(53.5, -1.5), 6.8);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: hub.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$index',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: hub.color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${hub.name} (${hub.region})',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Postcodes: ${hub.postcodes}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: hub.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                      size: 20,
                      color: const Color(0xFF64748B),
                    ),
                  ],
                ),
                if (isSelected) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                  const SizedBox(height: 10),
                  Text(
                    '📍 0–10 miles:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hub.innerTowns.join(', '),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '🚚 11–20 miles:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF334155),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hub.outerTowns.join(', '),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverageHubData {
  final String name;
  final String region;
  final LatLng center;
  final double zoom;
  final Color color;
  final String postcodes;
  final List<String> innerTowns;
  final List<String> outerTowns;

  const _CoverageHubData({
    required this.name,
    required this.region,
    required this.center,
    required this.zoom,
    required this.color,
    required this.postcodes,
    required this.innerTowns,
    required this.outerTowns,
  });
}

class _CatMeta {
  final String label;
  final Color colorA;
  final Color colorB;
  final Color tint;

  const _CatMeta(this.label, this.colorA, this.colorB, this.tint);
}

class _FaqItem {
  final String category;
  final String question;
  final String answer;
  final bool isMap;

  const _FaqItem({
    required this.category,
    required this.question,
    required this.answer,
    this.isMap = false,
  });
}
