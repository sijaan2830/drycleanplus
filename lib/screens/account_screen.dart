import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/skeleton_loading.dart';
import '../widgets/dryclean_loader.dart';
import '../widgets/persistent_footer_app.dart';
import '../providers/booking_provider.dart';
import '../providers/user_provider.dart';
import '../models/booking_models.dart';
import '../utils/route_helpers.dart';
import 'booking/address_selection_screen.dart';
import 'booking/contact_info_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Simulate loading delay for account data
    Future.delayed(const Duration(milliseconds: 1500), () {
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
            // Check if we can pop, otherwise go to more tab
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/more');
            }
          },
        ),
        title: Text(
          'Account',
          style: GoogleFonts.inter(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading 
          ? _buildSkeletonLoading()
          : Consumer<BookingProvider>(
              builder: (context, provider, child) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 1),
                      
                      // Addresses Section
                      _buildSection(
                        title: "Addresses",
                        content: _buildAddressContent(provider),
                        onEdit: null, // Remove edit option
                      ),

                      // Contact Details Section
                      _buildSection(
                        title: "Contact details",
                        content: _buildContactDetailsContent(provider),
                        onEdit: () {
                          // Navigate to contact info page for real-time editing
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const ContactInfoScreen(isEditMode: true),
                            ),
                          ).then((_) {
                            // Refresh the account page when returning from contact info
                            setState(() {});
                          });
                        },
                      ),

                      // Country Section
                      _buildSection(
                        title: "Country",
                        content: _buildCountryContent(),
                        onEdit: null, // Country is not editable
                      ),

                      // Action Buttons
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            TextButton(
                              onPressed: () {
                                _showLogoutDialog(context);
                              },
                              child: Text(
                                "Log out",
                                style: GoogleFonts.inter(
                                  color: AppColors.gold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextButton(
                              onPressed: () {
                                _showDeleteAccountDialog(context);
                              },
                              child: Text(
                                "Delete account",
                                style: GoogleFonts.inter(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSkeletonLoading() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 1),
          // Addresses Section Skeleton
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.primaryBlueDark,
              border: Border(bottom: BorderSide(color: AppColors.white.withOpacity(0.1))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    SkeletonLoading(
                      width: 80,
                      height: 18,
                      borderRadius: 4,
                    ),
                    SkeletonLoading(
                      width: 60,
                      height: 32,
                      borderRadius: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const SkeletonLoading(
                  height: 15,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                const SkeletonLoading(
                  width: 250,
                  height: 15,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
          
          // Contact Details Section Skeleton
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.primaryBlueDark,
              border: Border(bottom: BorderSide(color: AppColors.white.withOpacity(0.1))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    SkeletonLoading(
                      width: 120,
                      height: 18,
                      borderRadius: 4,
                    ),
                    SkeletonLoading(
                      width: 60,
                      height: 32,
                      borderRadius: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildDetailItemSkeleton(),
                const SizedBox(height: 20),
                _buildDetailItemSkeleton(),
                const SizedBox(height: 20),
                _buildDetailItemSkeleton(),
                const SizedBox(height: 20),
                _buildDetailItemSkeleton(),
              ],
            ),
          ),
          
          // Country Section Skeleton
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              color: AppColors.primaryBlueDark,
              border: Border(bottom: BorderSide(color: AppColors.white.withOpacity(0.1))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    SkeletonLoading(
                      width: 60,
                      height: 18,
                      borderRadius: 4,
                    ),
                    SkeletonLoading(
                      width: 60,
                      height: 32,
                      borderRadius: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    SkeletonLoading(
                      width: 32,
                      height: 20,
                      borderRadius: 2,
                    ),
                    SizedBox(width: 12),
                    SkeletonLoading(
                      width: 120,
                      height: 16,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action Buttons Skeleton
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: const [
                SkeletonLoading(
                  width: 80,
                  height: 18,
                  borderRadius: 4,
                ),
                const SizedBox(height: 15),
                SkeletonLoading(
                  width: 120,
                  height: 18,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItemSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonLoading(
          width: 60,
          height: 14,
          borderRadius: 4,
        ),
        const SizedBox(height: 4),
        SkeletonLoading(
          width: 100,
          height: 16,
          borderRadius: 4,
        ),
      ],
    );
  }

  Widget _buildAddressContent(BookingProvider provider) {
    final address = provider.userDefaultAddress;
    if (address != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            address.fullAddress,
            style: TextStyle(
              color: AppColors.white.withOpacity(0.9),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              // Navigate to address selection for editing
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddressSelectionScreen(isEditMode: true),
                ),
              ).then((_) {
                // Refresh the account page when returning from address editing
                setState(() {});
              });
            },
            child: Text(
              "Edit Address",
              style: GoogleFonts.inter(
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.gold,
              ),
            ),
          ),
        ],
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "No address set",
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            // Navigate to address selection to add address
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AddressSelectionScreen(isEditMode: true),
              ),
            ).then((_) {
              // Refresh the account page when returning from address adding
              setState(() {});
            });
          },
          child: Text(
            "Add Address",
            style: GoogleFonts.inter(
              color: const Color(0xFF0066CC),
              fontWeight: FontWeight.bold,
              fontSize: 14,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactDetailsContent(BookingProvider provider) {
    final userProvider = Provider.of<UserProvider>(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailItem("First name", userProvider.firstName.isNotEmpty ? userProvider.firstName : "Not set"),
        const SizedBox(height: 20),
        _buildDetailItem("Last name", userProvider.lastName.isNotEmpty ? userProvider.lastName : "Not set"),
        const SizedBox(height: 20),
        _buildDetailItem("Mobile number", userProvider.phone.isNotEmpty ? userProvider.phone : "Not set"),
        const SizedBox(height: 20),
        _buildDetailItem("Email", userProvider.email.isNotEmpty ? userProvider.email : "Not set"),
      ],
    );
  }

  Widget _buildCountryContent() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
              )
            ],
          ),
          child: const CustomPaint(painter: UKFlagPainter()),
        ),
        const SizedBox(width: 12),
        Text(
          "United Kingdom",
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required Widget content,
    VoidCallback? onEdit,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.primaryBlueDark.withOpacity(0.5),
        border: Border(bottom: BorderSide(color: AppColors.white.withOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                  letterSpacing: -0.5,
                ),
              ),
              if (onEdit != null)
                ElevatedButton(
                  onPressed: onEdit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.primaryBlue,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    minimumSize: const Size(60, 32),
                  ),
                  child: Text(
                    "Edit",
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFFAAAAAA),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: value == "Not set" ? AppColors.white.withOpacity(0.4) : AppColors.white,
          ),
        ),
      ],
    );
  }

  void _showEditContactDialog(BuildContext context, BookingProvider provider) {
    final firstNameController = TextEditingController(text: provider.bookingData.firstName);
    final lastNameController = TextEditingController(text: provider.bookingData.lastName);
    final emailController = TextEditingController(text: provider.bookingData.email);
    final phoneController = TextEditingController(text: provider.bookingData.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Contact Details',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.updateContactInfo(
                firstName: firstNameController.text.trim(),
                lastName: lastNameController.text.trim(),
                email: emailController.text.trim(),
                phone: phoneController.text.trim(),
              );
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contact details updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }


  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          height: 120,
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Log Out',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to log out?',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showLoaderAndNavigateToLogin();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Log Out',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoaderAndNavigateToLogin() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DrycleanLoader(),
    );

    // Show loader for 2 seconds then navigate to login
    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted) {
        // Clear user data from providers
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
        
        // Clear all user data
        await userProvider.clearUserData();
        bookingProvider.clearBookingData();
        
        // Clear any additional cached data
        await _clearAdditionalUserData();
        
        // Reset footer navigation to Home tab
        persistentFooterAppState?.resetToHomeTab();
        
        Navigator.of(context).pop(); // Close loader
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/onboarding',
          (route) => false,
        );
      }
    });
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          height: 125,
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Account Deletion',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to delete your account? This action cannot be undone.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'No',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Show loader for 2 seconds then navigate to login
                      _showLoaderAndDeleteAccount();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Yes',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLoaderAndDeleteAccount() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DrycleanLoader(),
    );

    // Show loader for 2 seconds then navigate to login
    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted) {
        // Clear user data from providers
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
        
        // Clear all user data
        await userProvider.clearUserData();
        bookingProvider.clearBookingData();
        
        // Clear any additional cached data
        await _clearAdditionalUserData();
        
        // Reset footer navigation to Home tab
        persistentFooterAppState?.resetToHomeTab();
        
        Navigator.of(context).pop(); // Close loader
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/onboarding',
          (route) => false,
        );
      }
    });
  }

  Future<void> _clearAdditionalUserData() async {
    try {
      // Clear any additional SharedPreferences data
      final prefs = await SharedPreferences.getInstance();
      
      // Clear any additional user-related preferences
      await prefs.remove('user_displayName');
      await prefs.remove('is_guest');
      await prefs.remove('is_logged_in');
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      
      // Clear any session data
      await prefs.remove('session_start_time');
      await prefs.remove('last_active_time');
      
    } catch (e) {
      // Log error but don't prevent account deletion
      print('Error clearing additional user data: $e');
    }
  }
}

// Custom Painter for the UK Flag
class UKFlagPainter extends CustomPainter {
  const UKFlagPainter();
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final rect = Offset.zero & size;

    // Background Blue
    paint.color = const Color(0xFF012169);
    canvas.drawRect(rect, paint);

    // White Diagonals
    paint.color = Colors.white;
    paint.strokeWidth = size.height * 0.2;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);

    // Red Diagonals (St George's Cross style offsets)
    paint.color = const Color(0xFFC8102E);
    paint.strokeWidth = size.height * 0.12;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);

    // White Horizontal/Vertical
    paint.color = Colors.white;
    paint.strokeWidth = size.height * 0.3;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);

    // Red Horizontal/Vertical
    paint.color = const Color(0xFFC8102E);
    paint.strokeWidth = size.height * 0.18;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
