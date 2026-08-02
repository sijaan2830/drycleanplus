import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../widgets/skeleton_loading.dart';
import '../utils/route_helpers.dart';
import '../widgets/persistent_footer_app.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  bool _isLoading = true;

  final List<Map<String, dynamic>> faqItems = [
    {
      'question': 'Can you clean my item?',
      'answer': 'There are three ways to find out if your item is suitable for services we offer:\n\n1. Search for your item in our price list.\n2. Read our service details to find out which items are suitable for particular service.\n3. Get a custom quote. Send us a photo and a description of your item and we will come back to you on availability, costs and time needed.',
      'category': 'Getting Started',
    },
    {
      'question': 'How do I place an order?',
      'answer': 'Placing an order is simple and takes just a few steps through our app:\n\n1. Select Service: Choose from our range of services including Dry Cleaning, Wash & Iron, Laundry, and more.\n2. Add Address: Provide your collection and delivery address or select from saved addresses.\n3. Choose Time Slot: Select your preferred collection and delivery time slots.\n4. Payment: Complete your order using our secure payment system.\n\nPro Tip: You can save your addresses and payment methods for faster checkout next time!',
      'category': 'Getting Started',
    },
    {
      'question': 'What are order statuses?',
      'answer': 'Your order goes through several stages from collection to delivery:\n\n• Pending: Order received and awaiting confirmation\n• Confirmed: Order confirmed and scheduled for collection\n• Processing: Items collected and being processed\n• Cleaning: Items are being cleaned according to selected service\n• Quality Check: Final quality inspection before packaging\n• Collection Scheduled: Ready for delivery and scheduled for return\n• In Transit: Items are on their way back to you\n• Delivered: Order successfully delivered',
      'category': 'Orders',
    },
    {
      'question': 'How do prepaid packs work?',
      'answer': 'Prepaid packs offer great value for regular customers:\n\n1. Purchase Credits: Buy prepaid packs at discounted rates. The more you buy, more you save.\n2. Automatic Application: Credits are automatically applied to your orders when available.\n3. Track Balance: View your remaining credits in Account section.\n\nSave up to 20% with prepaid packs compared to pay-per-order pricing!',
      'category': 'Payment',
    },
    {
      'question': 'How to prepare?',
      'answer': 'Follow these steps for best service:\n\n1. Pack one service per bag: For example put items for Wash & Iron in bag one, and items for Wash only in bag two. This helps us process your laundry efficiently.\n\nTip: You can use disposable bags for your first order. Your items will be returned in reusable Dryclean Plus bags which you can keep for your next order.\n\n2. Tag each bag: Please label bags with service required (e.g., "Dry Clean" or "Wash & Fold"). If you\'re meeting the driver in person, they will confirm service with you.\n\n3. Prepare for collection: You\'ll receive a notification when our driver is nearby, typically within 30-minute window you selected. Ensure your bags are ready for a quick handover.',
      'category': 'Service',
    },
    {
      'question': 'Pricing and payment',
      'answer': 'Our pricing is clear and competitive. We accept all major credit/debit cards (Visa, Mastercard, Amex).\n\nPayment Security: All payments are securely processed. We do not store your card details.\n\nInvoicing: You will receive a detailed invoice via email after your items have been processed and final price is determined.',
      'category': 'Payment',
    },
    {
      'question': 'How is final price calculated?',
      'answer': 'The price estimated during booking is a guide. The final price reflects actual count, weight, or complexity of items confirmed by our cleaning facility.\n\nThe final price is calculated in two steps:\n\n1. Item Check: Upon arrival at our facility, each item is inspected, counted, and measured (for certain services like wash & fold).\n2. Service Confirmation: Any special requests (e.g., stain removal, repair) are confirmed, and appropriate charges are applied based on our official pricelist.\n\nWe notify you of final price before charging your payment method. You have a short window to raise any queries.',
      'category': 'Payment',
    },
    {
      'question': 'How can I track my order?',
      'answer': 'Tracking your order is easy and fully integrated into app with real-time updates:\n\n1. Orders Tab: Check \'Orders\' tab for real-time status updates and detailed order information.\n2. Order Tracking Screen: Tap on any order to see detailed tracking with status milestones and timestamps.\n3. Push Notifications: Receive instant notifications for status changes, collection alerts, and delivery updates.\n\nEnable notifications to never miss an update about your order!',
      'category': 'Orders',
    },
    {
      'question': 'What services do you offer?',
      'answer': 'We offer a comprehensive range of cleaning services:\n\n• Dry Cleaning: Professional dry cleaning for suits, dresses, coats, and delicate fabrics.\n• Wash & Iron: Complete washing and professional ironing service for everyday clothes.\n• Laundry: General laundry service for underwear, socks, towels, and household linens.\n• Duvets & Bedding: Specialized cleaning for duvets, pillows, and all bedding items.\n• Household Items: Cleaning for curtains, cushion covers, tablecloths, and other household textiles.\n• Sports Kit: Specialized cleaning for sportswear, kits, and athletic equipment.',
      'category': 'Services',
    },
    {
      'question': 'How do I manage my account?',
      'answer': 'Your account section allows you to manage personal information, addresses, and preferences:\n\n1. Personal Information: Update your name, email, phone number, and other contact details.\n2. Address Management: Add, edit, or delete collection and delivery addresses for quick checkout.\n3. Prepaid Credits: View your prepaid pack balance and purchase additional credits.\n4. Order History: Access your complete order history and repeat previous orders easily.',
      'category': 'Account',
    },
    {
      'question': 'Where is DryClean Plus available?',
      'answer': 'Find our location through our service area map. We currently serve the London area with plans for expansion. Check the app for availability in your specific location.',
      'category': 'Service',
      'showMap': true,
    },
    {
      'question': 'What are your delivery times?',
      'answer': 'We offer flexible delivery options to fit your schedule:\n\n1. Time Slots: Choose from multiple 30-minute time slots throughout the day for collection and delivery.\n2. Same-Day Service: Available for certain services. Check during booking for same-day options.\n3. Express Delivery: Priority service available for urgent needs at additional cost.\n\nBook early for best time slot availability!',
      'category': 'Delivery',
    },
    {
      'question': 'How do I cancel or modify an order?',
      'answer': 'Need to make changes to your order? Here\'s what you need to know:\n\nCancellation Window: Cancel free of charge up to 2 hours before your scheduled collection time.',
      'category': 'Orders',
    },
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.white, size: 30),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/more');
            }
          },
        ),
        title: Text(
          'Help & FAQ',
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: _isLoading ? _buildSkeletonLoading() : _buildFAQList(),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      separatorBuilder: (context, index) => Divider(
        color: AppColors.white.withOpacity(0.1),
        thickness: 0.5,
        height: 32,
      ),
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: SkeletonLoading(
                  width: double.infinity,
                  height: 16,
                  borderRadius: 4,
                ),
              ),
              const SizedBox(width: 8),
              const SkeletonLoading(
                width: 24,
                height: 24,
                borderRadius: 4,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFAQList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: faqItems.length,
      separatorBuilder: (context, index) => const Divider(
        color: Color(0xFF757575),
        thickness: 0.5,
        height: 32,
      ),
      itemBuilder: (context, index) {
        return InkWell(
          onTap: () {
            // Check if this is the "Where is DryClean Plus available?" question
            if (faqItems[index]['showMap'] == true) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const FAQMapScreen(),
                ),
              );
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FAQAnswerScreen(
                    question: faqItems[index]['question'],
                    answer: faqItems[index]['answer'],
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    faqItems[index]['question'],
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.white,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class FAQAnswerScreen extends StatefulWidget {
  final String question;
  final String answer;

  const FAQAnswerScreen({
    super.key,
    required this.question,
    required this.answer,
  });

  @override
  State<FAQAnswerScreen> createState() => _FAQAnswerScreenState();
}

class _FAQAnswerScreenState extends State<FAQAnswerScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.white, size: 30),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/more');
            }
          },
        ),
        title: Text(
          'FAQ',
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading ? _buildSkeletonLoading() : _buildContent(),
    );
  }

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoading(
            width: double.infinity,
            height: 24,
            borderRadius: 4,
          ),
          const SizedBox(height: 20),
          const SkeletonLoading(
            width: double.infinity,
            height: 16,
            borderRadius: 4,
          ),
          const SizedBox(height: 8),
          const SkeletonLoading(
            width: double.infinity,
            height: 16,
            borderRadius: 4,
          ),
          const SizedBox(height: 8),
          const SkeletonLoading(
            width: double.infinity,
            height: 16,
            borderRadius: 4,
          ),
          const SizedBox(height: 8),
          SkeletonLoading(
            width: MediaQuery.of(context).size.width * 0.7,
            height: 16,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.question,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.answer,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.white.withOpacity(0.9),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class FAQMapScreen extends StatefulWidget {
  const FAQMapScreen({super.key});

  @override
  State<FAQMapScreen> createState() => _FAQMapScreenState();
}

class _FAQMapScreenState extends State<FAQMapScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _openMap() async {
    // Use coordinates from the embed URL: lat=53.0785402, lng=-0.8098671
    final Uri url = Uri.parse('https://www.google.com/maps?q=53.0785402,-0.8098671');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open map'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.white, size: 30),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/more');
            }
          },
        ),
        title: Text(
          'Our Location',
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading ? _buildSkeletonLoading() : _buildContent(),
    );
  }

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoading(
            width: double.infinity,
            height: 24,
            borderRadius: 4,
          ),
          const SizedBox(height: 20),
          const SkeletonLoading(
            width: double.infinity,
            height: 200,
            borderRadius: 12,
          ),
          const SizedBox(height: 20),
          const SkeletonLoading(
            width: double.infinity,
            height: 16,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where is DryClean Plus available?',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 20),
          // Map placeholder image
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.primaryBlueDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.white.withOpacity(0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 60,
                  color: AppColors.gold,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap button below to open map',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Find our location through our service area map. We currently serve the London area with plans for expansion. Check the app for availability in your specific location.',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.white.withOpacity(0.9),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openMap,
              icon: const Icon(Icons.map_outlined),
              label: Text(
                'Open in Google Maps',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
