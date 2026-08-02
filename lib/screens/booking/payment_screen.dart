import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:provider/provider.dart';
import 'booking_confirmation_screen.dart';
import '../../providers/booking_provider.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String currency;

  const PaymentScreen({
    super.key,
    required this.amount,
    this.currency = 'GBP',
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {

  late final WebViewController controller;
  bool isLoading = true;
  bool isPaymentCompleted = false;

  final String paymentUrl =
      "https://pay.sumup.com/b2c/Q3MO3NEP";

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            setState(() {
              isLoading = false;
            });
            
            // Inject JavaScript to detect payment completion
            _injectPaymentCompletionDetector();
            
            // Check if payment is completed by looking for success indicators in the URL
            if (url.contains('success') || url.contains('complete') || url.contains('thank-you')) {
              _markPaymentCompleted();
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(paymentUrl));
  }

  void _markPaymentCompleted() async {
    if (!isPaymentCompleted) {
      setState(() {
        isPaymentCompleted = true;
      });
      
      // Create order when payment is completed
      try {
        final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
        await bookingProvider.createOrder();
        print('Order created successfully after payment completion');
      } catch (e) {
        print('Error creating order: $e');
        // Still show confirmation even if order creation fails
        // The user can retry or contact support
      }
      
      // Go directly to booking confirmation
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const BookingConfirmationScreen(),
          ),
          (route) => false,
        );
      }
    }
  }

  void _injectPaymentCompletionDetector() async {
    // Inject JavaScript to detect payment completion
    await controller.runJavaScript("""
      // Function to detect payment success
      function detectPaymentSuccess() {
        // Look for common success indicators
        const successElements = document.querySelectorAll([
          '[class*="success"]',
          '[class*="complete"]',
          '[class*="thank"]',
          '[class*="confirmed"]',
          'h1:contains("Thank")',
          'h1:contains("Success")',
          'h1:contains("Complete")',
          'h2:contains("Thank")',
          'h2:contains("Success")',
          'h2:contains("Complete")'
        ].join(','));
        
        if (successElements.length > 0) {
          window.flutter_inappwebview.postMessage('PAYMENT_SUCCESS');
        }
        
        // Also check URL changes
        if (window.location.href.includes('success') || 
            window.location.href.includes('complete') || 
            window.location.href.includes('thank')) {
          window.flutter_inappwebview.postMessage('PAYMENT_SUCCESS');
        }
      }
      
      // Run detection immediately and every 2 seconds
      detectPaymentSuccess();
      setInterval(detectPaymentSuccess, 2000);
      
      // Add JavaScript channel for communication
      window.flutter_inappwebview = {
        postMessage: function(message) {
          // This will be handled by Flutter
        }
      };
    """);

    // Add JavaScript channel to listen for messages
    controller.addJavaScriptChannel(
      'flutter_inappwebview',
      onMessageReceived: (JavaScriptMessage message) {
        if (message.message == 'PAYMENT_SUCCESS') {
          _markPaymentCompleted();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0066FF),
        title: Text(
          "Secure Payment",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Amount Display Header - Smaller height
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Amount to Pay',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.currency}${widget.amount.toStringAsFixed(2)}',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0066FF),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock,
                            size: 14,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Locked',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Warning message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 16,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please ensure correct payment details. Wrong inputs may cause payment failure.',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // WebView for Payment
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: controller),
                if (isLoading)
                  Container(
                    color: Colors.white,
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0066FF)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Payment completion button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _markPaymentCompleted,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Mark Payment as Completed',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
    );
  }
}