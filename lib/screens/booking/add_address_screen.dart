import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/user_provider.dart';
import '../../models/booking_models.dart';
import '../../services/postcoder_service.dart';
import '../../config/theme.dart';

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({super.key});

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _line1Controller = TextEditingController();
  final _line2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _countyController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _buildingNameController = TextEditingController();
  
  String _selectedCountry = 'uk';
  List<AddressSuggestion> _suggestions = [];
  bool _isSearching = false;
  bool _showSuggestions = false;
  AddressSuggestion? _selectedSuggestion;
  
  final List<Map<String, String>> _countries = [
    {'code': 'uk', 'name': 'United Kingdom'},
    {'code': 'us', 'name': 'United States'},
    {'code': 'ie', 'name': 'Ireland'},
    {'code': 'au', 'name': 'Australia'},
    {'code': 'ca', 'name': 'Canada'},
    {'code': 'de', 'name': 'Germany'},
    {'code': 'fr', 'name': 'France'},
    {'code': 'nl', 'name': 'Netherlands'},
    {'code': 'be', 'name': 'Belgium'},
    {'code': 'lu', 'name': 'Luxembourg'},
    {'code': 'at', 'name': 'Austria'},
    {'code': 'dk', 'name': 'Denmark'},
    {'code': 'se', 'name': 'Sweden'},
    {'code': 'no', 'name': 'Norway'},
    {'code': 'fi', 'name': 'Finland'},
    {'code': 'ch', 'name': 'Switzerland'},
    {'code': 'it', 'name': 'Italy'},
    {'code': 'es', 'name': 'Spain'},
    {'code': 'pt', 'name': 'Portugal'},
    {'code': 'cz', 'name': 'Czech Republic'},
    {'code': 'pl', 'name': 'Poland'},
    {'code': 'hu', 'name': 'Hungary'},
    {'code': 'sk', 'name': 'Slovakia'},
    {'code': 'si', 'name': 'Slovenia'},
    {'code': 'ee', 'name': 'Estonia'},
    {'code': 'lv', 'name': 'Latvia'},
    {'code': 'lt', 'name': 'Lithuania'},
    {'code': 'mt', 'name': 'Malta'},
    {'code': 'cy', 'name': 'Cyprus'},
    {'code': 'is', 'name': 'Iceland'},
    {'code': 'li', 'name': 'Liechtenstein'},
    {'code': 'mc', 'name': 'Monaco'},
    {'code': 'sm', 'name': 'San Marino'},
    {'code': 'va', 'name': 'Vatican City'},
    {'code': 'ad', 'name': 'Andorra'},
    {'code': 'ro', 'name': 'Romania'},
    {'code': 'bg', 'name': 'Bulgaria'},
    {'code': 'hr', 'name': 'Croatia'},
    {'code': 'gr', 'name': 'Greece'},
    {'code': 'al', 'name': 'Albania'},
    {'code': 'mk', 'name': 'North Macedonia'},
    {'code': 'rs', 'name': 'Serbia'},
    {'code': 'me', 'name': 'Montenegro'},
    {'code': 'ba', 'name': 'Bosnia and Herzegovina'},
    {'code': 'xk', 'name': 'Kosovo'},
    {'code': 'ua', 'name': 'Ukraine'},
    {'code': 'by', 'name': 'Belarus'},
    {'code': 'md', 'name': 'Moldova'},
    {'code': 'ru', 'name': 'Russia'},
    {'code': 'tr', 'name': 'Turkey'},
    {'code': 'il', 'name': 'Israel'},
    {'code': 'ae', 'name': 'United Arab Emirates'},
    {'code': 'sa', 'name': 'Saudi Arabia'},
    {'code': 'qa', 'name': 'Qatar'},
    {'code': 'kw', 'name': 'Kuwait'},
    {'code': 'bh', 'name': 'Bahrain'},
    {'code': 'om', 'name': 'Oman'},
    {'code': 'jo', 'name': 'Jordan'},
    {'code': 'lb', 'name': 'Lebanon'},
    {'code': 'nz', 'name': 'New Zealand'},
    {'code': 'za', 'name': 'South Africa'},
    {'code': 'sg', 'name': 'Singapore'},
    {'code': 'my', 'name': 'Malaysia'},
    {'code': 'th', 'name': 'Thailand'},
    {'code': 'ph', 'name': 'Philippines'},
    {'code': 'id', 'name': 'Indonesia'},
    {'code': 'vn', 'name': 'Vietnam'},
    {'code': 'hk', 'name': 'Hong Kong'},
    {'code': 'tw', 'name': 'Taiwan'},
    {'code': 'kr', 'name': 'South Korea'},
    {'code': 'jp', 'name': 'Japan'},
    {'code': 'in', 'name': 'India'},
    {'code': 'pk', 'name': 'Pakistan'},
    {'code': 'bd', 'name': 'Bangladesh'},
    {'code': 'lk', 'name': 'Sri Lanka'},
    {'code': 'np', 'name': 'Nepal'},
    {'code': 'mm', 'name': 'Myanmar'},
    {'code': 'kh', 'name': 'Cambodia'},
    {'code': 'la', 'name': 'Laos'},
    {'code': 'bn', 'name': 'Brunei'},
    {'code': 'mo', 'name': 'Macau'},
    {'code': 'mn', 'name': 'Mongolia'},
    {'code': 'cn', 'name': 'China'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _line1Controller.dispose();
    _line2Controller.dispose();
    _cityController.dispose();
    _countyController.dispose();
    _postalCodeController.dispose();
    _buildingNameController.dispose();
    super.dispose();
  }

  Future<void> _searchAddresses(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _showSuggestions = true;
    });

    final results = await PostcoderService.searchAddresses(
      query,
      country: _selectedCountry,
    );

    if (mounted) {
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _selectAddress(AddressSuggestion suggestion) async {
    setState(() {
      _selectedSuggestion = suggestion;
      _showSuggestions = false;
      _searchController.text = suggestion.summaryline;
    });

    // If we have an ID, fetch full details
    if (suggestion.id != null && suggestion.id!.isNotEmpty) {
      final details = await PostcoderService.getAddressDetails(
        suggestion.id!,
        country: _selectedCountry,
      );

      if (details != null && mounted) {
        setState(() {
          _line1Controller.text = details.getAddressLine1();
          _line2Controller.text = details.getAddressLine2() ?? '';
          _cityController.text = details.getCity();
          _countyController.text = details.getCounty() ?? '';
          _postalCodeController.text = details.getPostcode() ?? '';
          _buildingNameController.text = details.buildingname ?? '';
        });
      }
    } else {
      // Use the suggestion data directly
      setState(() {
        _line1Controller.text = suggestion.street ?? '';
        _cityController.text = suggestion.posttown ?? '';
        _countyController.text = suggestion.county ?? '';
        _postalCodeController.text = suggestion.postcode ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.white, size: 30),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
        ),
        title: Text(
          'Add Address',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Address Details',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Search for your address or enter it manually',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Country Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCountry,
                  dropdownColor: AppColors.primaryBlueDark,
                  style: GoogleFonts.inter(color: AppColors.white),
                  decoration: InputDecoration(
                    labelText: 'Country',
                    labelStyle: const TextStyle(color: AppColors.white),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                    ),
                    filled: true,
                    fillColor: AppColors.primaryBlueDark,
                  ),
                  items: _countries.map((country) {
                    return DropdownMenuItem<String>(
                      value: country['code'],
                      child: Text(country['name']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCountry = value ?? 'uk';
                      _suggestions = [];
                      _showSuggestions = false;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Address Search Field
                Column(
                  children: [
                    TextFormField(
                      controller: _searchController,
                      style: const TextStyle(color: AppColors.white),
                      decoration: InputDecoration(
                        labelText: 'Search for your address',
                        labelStyle: const TextStyle(color: AppColors.white),
                        hintText: 'Start typing your address or postcode',
                        hintStyle: TextStyle(color: AppColors.white.withOpacity(0.5)),
                        prefixIcon: const Icon(Icons.search, color: AppColors.white),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                                ),
                              )
                            : _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: AppColors.white),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _suggestions = [];
                                        _showSuggestions = false;
                                      });
                                    },
                                  )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.gold),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                        ),
                        filled: true,
                        fillColor: AppColors.primaryBlueDark,
                      ),
                      onChanged: (value) {
                        _searchAddresses(value);
                      },
                    ),
                    
                    // Address Suggestions Dropdown
                    if (_showSuggestions && _suggestions.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlueDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gold),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(maxHeight: 200),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _suggestions.length,
                          itemBuilder: (context, index) {
                            final suggestion = _suggestions[index];
                            return ListTile(
                              title: Text(
                                suggestion.summaryline,
                                style: GoogleFonts.inter(fontSize: 14, color: AppColors.white),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _selectAddress(suggestion),
                            );
                          },
                        ),
                      ),
                    
                    if (_showSuggestions && _isSearching)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlueDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gold),
                        ),
                        child: Center(
                          child: Text(
                            'Searching...',
                            style: GoogleFonts.inter(color: AppColors.white.withOpacity(0.7)),
                          ),
                        ),
                      ),
                    
                    if (_showSuggestions && !_isSearching && _suggestions.isEmpty && _searchController.text.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlueDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.gold),
                        ),
                        child: Center(
                          child: Text(
                            'No addresses found. Please enter manually.',
                            style: GoogleFonts.inter(color: AppColors.white.withOpacity(0.7)),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.gold.withOpacity(0.5))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or enter manually',
                        style: GoogleFonts.inter(
                          color: AppColors.goldLight,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.gold.withOpacity(0.5))),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Address Line 1
                TextFormField(
                  controller: _line1Controller,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    labelText: 'Address Line 1',
                    labelStyle: const TextStyle(color: AppColors.white),
                    hintText: 'Street address',
                    hintStyle: TextStyle(color: AppColors.white.withOpacity(0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                    ),
                    filled: true,
                    fillColor: AppColors.primaryBlueDark,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter address line 1';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Address Line 2
                TextFormField(
                  controller: _line2Controller,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    labelText: 'Address Line 2 (Optional)',
                    labelStyle: const TextStyle(color: AppColors.white),
                    hintText: 'Apartment, suite, unit, building, floor, etc.',
                    hintStyle: TextStyle(color: AppColors.white.withOpacity(0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                    ),
                    filled: true,
                    fillColor: AppColors.primaryBlueDark,
                  ),
                ),
                const SizedBox(height: 16),
                // Building Name
                TextFormField(
                  controller: _buildingNameController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    labelText: 'Building Name (Optional)',
                    labelStyle: const TextStyle(color: AppColors.white),
                    hintText: 'Building or complex name',
                    hintStyle: TextStyle(color: AppColors.white.withOpacity(0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                    ),
                    filled: true,
                    fillColor: AppColors.primaryBlueDark,
                  ),
                ),
                const SizedBox(height: 16),
                // City
                TextFormField(
                  controller: _cityController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    labelText: 'Town / City',
                    labelStyle: const TextStyle(color: AppColors.white),
                    hintText: 'City name',
                    hintStyle: TextStyle(color: AppColors.white.withOpacity(0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                    ),
                    filled: true,
                    fillColor: AppColors.primaryBlueDark,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter city';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // County
                TextFormField(
                  controller: _countyController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    labelText: 'County / State (Optional)',
                    labelStyle: const TextStyle(color: AppColors.white),
                    hintText: 'County or state',
                    hintStyle: TextStyle(color: AppColors.white.withOpacity(0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                    ),
                    filled: true,
                    fillColor: AppColors.primaryBlueDark,
                  ),
                ),
                const SizedBox(height: 16),
                // Postal Code
                TextFormField(
                  controller: _postalCodeController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    labelText: 'Postcode / ZIP Code',
                    labelStyle: const TextStyle(color: AppColors.white),
                    hintText: 'Postcode',
                    hintStyle: TextStyle(color: AppColors.white.withOpacity(0.5)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.gold),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
                    ),
                    filled: true,
                    fillColor: AppColors.primaryBlueDark,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter postal code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.white, width: 1.5),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      'SAVE ADDRESS',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveAddress() async {
    if (_formKey.currentState!.validate()) {
      final address = Address(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        line1: _line1Controller.text.trim(),
        line2: _line2Controller.text.trim().isEmpty
            ? null
            : _line2Controller.text.trim(),
        city: _cityController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        buildingName: _buildingNameController.text.trim().isEmpty
            ? null
            : _buildingNameController.text.trim(),
        isDefault: true, // Set as default since it's the first address
      );

      // Save to Firestore - this will automatically update the provider via stream
      await Provider.of<BookingProvider>(context, listen: false)
          .addAddress(address);

      // Save as user's default address
      Provider.of<BookingProvider>(context, listen: false)
          .setUserDefaultAddress(address);

      // Also save to UserProvider for local persistence
      await Provider.of<UserProvider>(context, listen: false).saveAddressData(
        addressId: address.id,
        addressLine1: address.line1,
        addressLine2: address.line2,
        city: address.city,
        postcode: address.postalCode,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Address added successfully',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop();
    }
  }
}
