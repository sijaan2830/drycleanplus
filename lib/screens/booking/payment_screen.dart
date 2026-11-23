import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../config/payment_config.dart';
import '../../config/theme.dart';
import '../../providers/booking_provider.dart';
import '../../providers/prepaid_provider.dart';
import '../../widgets/app_ui.dart';
import 'booking_confirmation_screen.dart';

/// "Pay now" → opens the SumUp payment link inside the app.
///
/// The "MARK PAYMENT AS COMPLETED" button is LOCKED until the app sees that the
/// payment went through on the SumUp page (success URL or success text).
///
/// A static SumUp link cannot call the app back, so the order is stored as
/// `paid_unverified`; staff should match it in the SumUp dashboard. For real
/// server-side verification use the SumUp Checkout API + webhook.
class PaymentScreen extends StatefulWidget {
  final double amount;
  final String currency;

  const PaymentScreen({
    super.key,
    required this.amount,
    this.currency = '£',
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late final WebViewController _controller;
  Timer? _poll;
  Timer? _fallbackTimer;

  int _progress = 0;
  String? _loadError;

  bool _paymentDetected = false;
  bool _detectedManually = false;
  bool _showFallback = false;
  bool _completing = false;

  // Text the SumUp page shows after a successful payment.
  static const _successTextHints = [
    'payment successful',
    'payment complete',
    'payment received',
    'payment confirmed',
    'payment approved',
    'successfully paid',
    'paid successfully',
    'transaction approved',
    'thank you for your payment',
    'your payment was successful',
  ];

  // URL fragments that only appear after a successful payment.
  static final _successUrl = RegExp(r'(success|thank-?you|payment-?complete|receipt)');

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) {
            if (mounted) setState(() => _progress = p);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _loadError = null);
          },
          onPageFinished: (_) => _checkPage(),
          onUrlChange: (change) {
            final url = (change.url ?? '').toLowerCase();
            if (url.isNotEmpty && _successUrl.hasMatch(url)) {
              _markDetected();
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              if (mounted) setState(() => _loadError = 'Could not load the payment page.');
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(PaymentConfig.sumupPayUrl));

    // The SumUp page is a single-page app, so keep watching its visible text.
    _poll = Timer.periodic(const Duration(seconds: 1), (_) => _checkPage());

    if (PaymentConfig.allowManualFallback) {
      _fallbackTimer = Timer(
        const Duration(seconds: PaymentConfig.fallbackAfterSeconds),
        () {
          if (mounted && !_paymentDetected) setState(() => _showFallback = true);
        },
      );
    }
  }

  @override
  void dispose() {
    _poll?.cancel();
    _fallbackTimer?.cancel();
    super.dispose();
  }

  // ── Detection ─────────────────────────────────────────────────────────────

  void _markDetected({bool manual = false}) {
    if (_paymentDetected || !mounted) return;
    _poll?.cancel();
    _fallbackTimer?.cancel();
    HapticFeedback.mediumImpact();
    setState(() {
      _paymentDetected = true;
      _detectedManually = manual;
      _showFallback = false;
    });
    if (!manual) showAppSnack(context, 'Payment detected. You can now complete your order.');
  }

  Future<void> _checkPage() async {
    if (_paymentDetected || !mounted) return;
    try {
      final result = await _controller.runJavaScriptReturningResult(
        "(document.title + ' ' + (document.body ? document.body.innerText : '')).toLowerCase().slice(0, 6000)",
      );
      final text = result.toString().toLowerCase().replaceAll(r'\n', ' ');
      if (_successTextHints.any(text.contains)) _markDetected();
    } catch (_) {
      // Page not ready yet — ignore.
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _manualFallback() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Already paid?', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Text(
          'Only continue if SumUp showed that your payment went through. '
          'Your order will be flagged so we can check it against our SumUp account.',
          style: GoogleFonts.inter(height: 1.4, color: AppColors.white.withOpacity(0.9)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not yet')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, I paid', style: TextStyle(color: AppColors.gold)),
          ),
        ],
      ),
    );
    if (ok == true) _markDetected(manual: true);
  }

  Future<void> _complete() async {
    if (!_paymentDetected || _completing) return;

    setState(() => _completing = true);
    try {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final isPrepaidPack = bookingProvider.selectedService == 'Prepaid Pack';

      final order = await bookingProvider.createOrder(
        paymentMethod: PaymentConfig.methodSumUp,
        paymentStatus: _detectedManually
            ? PaymentConfig.statusPaidManualCheck
            : PaymentConfig.statusPaidUnverified,
      );

      // If prepaid pack, add to user's active prepaid packs
      if (isPrepaidPack) {
        try {
          final prepaidProvider = Provider.of<PrepaidProvider>(context, listen: false);
          final packItem = order.bookingData.selectedItems.values.isNotEmpty
              ? order.bookingData.selectedItems.values.first
              : null;
          final packName = order.bookingData.prepaidPackName ?? packItem?.category ?? 'Prepaid Pack';
          final itemType = packItem?.itemType ?? '';
          final count = int.tryParse(itemType.replaceAll(RegExp(r'[^0-9]'), '')) ?? 5;

          await prepaidProvider.addPack(PrepaidPack(
            id: order.id.isNotEmpty ? order.id : DateTime.now().millisecondsSinceEpoch.toString(),
            name: packName,
            description: 'Paid online · ${order.orderId}',
            itemCount: count,
            usedCount: 0,
            price: widget.amount,
            itemType: itemType.isNotEmpty ? itemType : packName,
            purchasedDate: DateTime.now(),
            expiryDate: DateTime.now().add(const Duration(days: 90)),
          ));
        } catch (e) {
          debugPrint('Error adding prepaid pack to provider: $e');
        }
      }

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        smoothRoute(const BookingConfirmationScreen(), name: '/booking_confirmation'),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _completing = false);
      showAppSnack(
        context,
        'Payment received but the order could not be saved. Tap the button to try again.',
        error: true,
      );
    }
  }

  /// Leaving after paying would lose the order, so confirm first.
  Future<bool> _confirmLeave() async {
    if (!_paymentDetected || _completing) return true;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Leave without finishing?', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Text(
          'Your payment was detected but your order has not been placed yet.',
          style: GoogleFonts.inter(height: 1.4, color: AppColors.white.withOpacity(0.9)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave', style: TextStyle(color: Color(0xFFFF8A80))),
          ),
        ],
      ),
    );
    return leave == true;
  }

  Future<void> _handleBack() async {
    if (await _confirmLeave() && mounted) Navigator.of(context).pop();
  }

  // ── UI ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final amount = '${widget.currency}${widget.amount.toStringAsFixed(2)}';

    return PopScope(
      canPop: !_paymentDetected || _completing,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && mounted) Navigator.of(context).pop();
      },
      child: AppScaffold(
        title: 'Secure payment',
        onBack: _handleBack,
        bottom: keyboardOpen ? null : _buildBottom(),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Column(
            children: [
              _buildAmountBanner(amount),
              const SizedBox(height: 12),
              Expanded(child: _buildWebView()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountBanner(String amount) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const IconBadge(icon: Icons.lock_rounded, size: 36),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount to pay',
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.white.withOpacity(0.75)),
                ),
                Text(
                  amount,
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.white),
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _paymentDetected
                ? _chip('Payment detected', Icons.check_circle_rounded, const Color(0xFF7CFFB0), AppColors.success,
                    key: const ValueKey('done'))
                : _chip('Waiting for payment', Icons.hourglass_top_rounded, AppColors.goldLight, AppColors.gold,
                    key: const ValueKey('wait')),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icon, Color fg, Color bg, {Key? key}) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.22),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: fg),
          ),
        ],
      ),
    );
  }

  Widget _buildWebView() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Stack(
        children: [
          Container(color: Colors.white),
          if (_loadError == null) WebViewWidget(controller: _controller),
          if (_loadError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded, size: 42, color: AppColors.muted),
                    const SizedBox(height: 10),
                    Text(
                      _loadError!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: AppColors.ink, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => _loadError = null);
                        _controller.loadRequest(Uri.parse(PaymentConfig.sumupPayUrl));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          if (_progress < 100 && _loadError == null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _progress == 0 ? null : _progress / 100,
                minHeight: 3,
                color: AppColors.gold,
                backgroundColor: Colors.transparent,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottom() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _paymentDetected
              ? Padding(
                  key: const ValueKey('ok'),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF7CFFB0)),
                      const SizedBox(width: 6),
                      Text(
                        'Payment done — tap below to place your order.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                )
              : Padding(
                  key: const ValueKey('locked'),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 15, color: AppColors.white.withOpacity(0.8)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Pay on the SumUp page above. This button unlocks after your payment.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.white.withOpacity(0.8)),
                            ),
                          ),
                        ],
                      ),
                      if (_showFallback)
                        TextButton(
                          onPressed: _manualFallback,
                          child: const Text('Paid, but still locked?'),
                        ),
                    ],
                  ),
                ),
        ),
        AppButton(
          label: 'MARK PAYMENT AS COMPLETED',
          icon: _paymentDetected ? Icons.check_circle_rounded : Icons.lock_rounded,
          loading: _completing,
          onPressed: _paymentDetected ? _complete : null,
        ),
      ],
    );
  }
}
