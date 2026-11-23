import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import 'persistent_footer_app.dart';
import 'service_price_card.dart';

/// Shared look for the 3-step booking flow (services → timeslots → review).
class BK {
  static const bg = Color(0xFFF4F7FC);
  static const card = Colors.white;
  static const line = Color(0xFFE3E9F4);
  static const blue = AppColors.primaryBlue;
  static const blueSoft = Color(0xFFE6F0FF);
  static const ink = AppColors.ink;
  static const mut = AppColors.muted;

  static TextStyle h(double s, {Color c = ink, FontWeight w = FontWeight.w800}) => GoogleFonts.outfit(fontSize: s, fontWeight: w, color: c, height: 1.15);
  static TextStyle t(double s, {Color c = ink, FontWeight w = FontWeight.w600, double? height}) =>
      GoogleFonts.plusJakartaSans(fontSize: s, fontWeight: w, color: c, height: height);
  static List<BoxShadow> shadow([double o = .08]) => [BoxShadow(color: const Color(0xFF0B1F5B).withValues(alpha: o), blurRadius: 22, offset: const Offset(0, 10), spreadRadius: -10)];
}

/// DryClean Plus UI icon library (assets/icons/ui).
class UiIcon extends StatelessWidget {
  final String name;
  final double size;
  const UiIcon(this.name, {super.key, this.size = 28});
  @override
  Widget build(BuildContext context) => Image.asset('assets/icons/ui/$name.png', width: size, height: size, filterQuality: FilterQuality.medium);
}

/// Icon for a service section: admin-picked hosted icon, else bundled asset, else a generic one.
Widget serviceSectionIcon(Map<String, dynamic> s, {double size = 56}) {
  final url = '${s['imageUrl'] ?? ''}';
  final name = '${s['name'] ?? s['title'] ?? ''}';
  // our own sections: the round 3D badge art bundled in the app (same as the Prices tab)
  if (!url.startsWith('http') || hasBundledArt(url)) {
    final art = ServicePriceConfig.forTitle(name).assetImage;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFF0B1F5B).withValues(alpha: .18), blurRadius: 14, offset: const Offset(0, 6))]),
      child: ClipOval(child: Image.asset(art, fit: BoxFit.cover, errorBuilder: (_, _, _) => const UiIcon('bag'))),
    );
  }
  // sections added later in the admin: the icon picked there, on a soft gradient disc
  return Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(size * .16),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Colors.white, serviceCardColors({'name': name, 'cardColors': s['cardColors']})[0]]),
      boxShadow: [BoxShadow(color: const Color(0xFF0B1F5B).withValues(alpha: .18), blurRadius: 14, offset: const Offset(0, 6))],
    ),
    child: Image.network(url, fit: BoxFit.contain, errorBuilder: (_, _, _) => const UiIcon('bag')),
  );
}

class BookingTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int step;
  /// White text for screens on the blue gradient.
  final bool onBlue;
  const BookingTopBar({super.key, required this.title, required this.step, this.onBlue = false});
  @override
  Size get preferredSize => const Size.fromHeight(86);
  @override
  Widget build(BuildContext context) => AppBar(
        backgroundColor: onBlue ? const Color(0xFF2E7EF7) : BK.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: onBlue ? Colors.white : BK.ink, size: 21),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              persistentFooterAppState?.setTab(0);
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MainTabScreen(tabIndex: 0)),
                (route) => false,
              );
            }
          },
        ),
        title: Text(title, style: BK.h(19, c: onBlue ? Colors.white : BK.ink)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(children: [
              for (var i = 1; i <= 3; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    height: 5,
                    decoration: BoxDecoration(color: i <= step ? (onBlue ? const Color(0xFFFDE047) : BK.blue) : (onBlue ? Colors.white24 : BK.line), borderRadius: BorderRadius.circular(9)),
                  ),
                ),
                if (i < 3) const SizedBox(width: 6),
              ],
              const SizedBox(width: 10),
              Text('Step $step of 3', style: BK.t(12, c: onBlue ? Colors.white70 : BK.mut, w: FontWeight.w700)),
            ]),
          ),
        ),
      );
}

/// The booking NEXT / CONFIRM button: just the yellow pill floating over the page.
/// Not ready yet → the same pill, faded. [onBlue] false on white pages (adds a white bar).
class BottomCta extends StatelessWidget {
  final String label;
  final String? hint;
  final VoidCallback? onTap;
  final bool busy;
  final bool onBlue;
  const BottomCta({super.key, required this.label, this.hint, this.onTap, this.busy = false, this.onBlue = true});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !busy;
    final button = YellowPill(label: label, enabled: enabled, busy: busy, onTap: onTap);
    return Container(
      padding: EdgeInsets.fromLTRB(16, onBlue ? 0 : 12, 16, 14 + MediaQuery.paddingOf(context).bottom),
      color: onBlue ? Colors.transparent : Colors.white,
      child: Align(
        alignment: Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 448), child: button),
      ),
    );
  }
}

/// Gold pill with an arrow — identical on Select a service, Timeslots and Order summary.
class YellowPill extends StatelessWidget {
  final String label;
  final bool enabled, busy;
  final VoidCallback? onTap;
  const YellowPill({super.key, required this.label, required this.enabled, this.busy = false, this.onTap});
  @override
  Widget build(BuildContext context) {
    // not ready → solid pale yellow (never see-through, it floats over the cards)
    final ink = enabled || busy ? const Color(0xFF0B1F5B) : const Color(0xFF0B1F5B).withValues(alpha: .45);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: enabled || busy ? const [Color(0xFFFFD25E), Color(0xFFFFB400)] : const [Color(0xFFFFF0C2), Color(0xFFFFE08A)],
          ),
          boxShadow: [BoxShadow(color: enabled ? const Color(0x8CFFB400) : const Color(0x4D020C3C), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (busy)
            const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.6, color: Color(0xFF0B1F5B)))
          else ...[
            Text(label.toUpperCase(), style: BK.t(17, c: ink, w: FontWeight.w800).copyWith(letterSpacing: .8)),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, color: ink, size: 20),
          ],
        ]),
      ),
    );
  }
}

class BkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool selected;
  const BkCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.selected = false});
  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: padding,
        decoration: BoxDecoration(
          color: BK.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? BK.blue : BK.line, width: selected ? 2 : 1),
          boxShadow: BK.shadow(selected ? .14 : .06),
        ),
        child: child,
      );
}
