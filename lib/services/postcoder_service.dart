import 'dart:convert';
import 'dart:io';

/// Service for Postcoder API address lookup
class PostcoderService {
  static const String _apiKey = 'PCW35-7ZK9M-MJMHF-YRCXE';
  static const String _baseUrl = 'https://ws.postcoder.com/pcw';
  
  /// Search for addresses by postcode or partial address
  /// 
  /// [query] - The postcode or partial address to search for
  /// [country] - Country code (e.g., 'uk', 'us')
  /// Returns a list of address suggestions
  static Future<List<AddressSuggestion>> searchAddresses(
    String query, {
    String country = 'uk',
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }
    
    try {
      final encodedQuery = Uri.encodeComponent(query.trim());
      final url = '$_baseUrl/$_apiKey/address/$country/$encodedQuery';
      
      // Create a custom HTTP request
      final httpClient = HttpClient();
      // Ignore SSL certificate errors (for development only)
      httpClient.badCertificateCallback = (cert, host, port) => true;
      
      final httpRequest = await httpClient.getUrl(Uri.parse(url));
      httpRequest.headers.set('Accept', 'application/json');
      
      final httpResponse = await httpRequest.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();
      
      httpClient.close();
      
      if (httpResponse.statusCode == 200) {
        final List<dynamic> data = json.decode(responseBody);
        return data.map((json) => AddressSuggestion.fromJson(Map<String, dynamic>.from(json))).toList();
      } else {
        print('Postcoder API error: ${httpResponse.statusCode}');
        return [];
      }
    } catch (e) {
      print('Postcoder API exception: $e');
      return [];
    }
  }
  
  /// Get full address details from an address ID
  /// 
  /// [addressId] - The unique ID of the selected address
  /// [country] - Country code
  /// Returns the full address details
  static Future<AddressDetails?> getAddressDetails(
    String addressId, {
    String country = 'uk',
  }) async {
    if (addressId.isEmpty) {
      return null;
    }
    
    try {
      final url = '$_baseUrl/$_apiKey/address/$country/$addressId?format=json';
      
      // Create a custom HTTP request
      final httpClient = HttpClient();
      // Ignore SSL certificate errors (for development only)
      httpClient.badCertificateCallback = (cert, host, port) => true;
      
      final httpRequest = await httpClient.getUrl(Uri.parse(url));
      httpRequest.headers.set('Accept', 'application/json');
      
      final httpResponse = await httpRequest.close();
      final responseBody = await httpResponse.transform(utf8.decoder).join();
      
      httpClient.close();
      
      if (httpResponse.statusCode == 200) {
        final data = json.decode(responseBody);
        if (data is List && data.isNotEmpty) {
          return AddressDetails.fromJson(Map<String, dynamic>.from(data.first));
        } else if (data is Map) {
          return AddressDetails.fromJson(Map<String, dynamic>.from(data));
        }
      }
      return null;
    } catch (e) {
      print('Postcoder API exception: $e');
      return null;
    }
  }
}

/// Represents an address suggestion from the search results
class AddressSuggestion {
  final String summaryline;
  final String? organisation;
  final String? street;
  final String? posttown;
  final String? county;
  final String? postcode;
  final String? id;
  
  AddressSuggestion({
    required this.summaryline,
    this.organisation,
    this.street,
    this.posttown,
    this.county,
    this.postcode,
    this.id,
  });
  
  factory AddressSuggestion.fromJson(Map<String, dynamic> json) {
    return AddressSuggestion(
      summaryline: json['summaryline'] ?? '',
      organisation: json['organisation'],
      street: json['street'],
      posttown: json['posttown'],
      county: json['county'],
      postcode: json['postcode'],
      id: json['id']?.toString(),
    );
  }
  
  @override
  String toString() => summaryline;
}

/// Represents full address details
class AddressDetails {
  final String? organisation;
  final String? buildingname;
  final String? subbuildingname;
  final String? number;
  final String? premise;
  final String? street;
  final String? dependentlocality;
  final String? posttown;
  final String? county;
  final String? postcode;
  final String? country;
  final String? line1;
  final String? line2;
  final String? line3;
  
  AddressDetails({
    this.organisation,
    this.buildingname,
    this.subbuildingname,
    this.number,
    this.premise,
    this.street,
    this.dependentlocality,
    this.posttown,
    this.county,
    this.postcode,
    this.country,
    this.line1,
    this.line2,
    this.line3,
  });
  
  factory AddressDetails.fromJson(Map<String, dynamic> json) {
    return AddressDetails(
      organisation: json['organisation'],
      buildingname: json['buildingname'],
      subbuildingname: json['subbuildingname'],
      number: json['number'],
      premise: json['premise'],
      street: json['street'],
      dependentlocality: json['dependentlocality'],
      posttown: json['posttown'],
      county: json['county'],
      postcode: json['postcode'],
      country: json['country'],
      line1: json['line1'],
      line2: json['line2'],
      line3: json['line3'],
    );
  }
  
  /// Get address line 1 (combines number and street or uses line1)
  String getAddressLine1() {
    if (line1 != null && line1!.isNotEmpty) {
      return line1!;
    }
    
    final parts = <String>[];
    if (number != null && number!.isNotEmpty) {
      parts.add(number!);
    }
    if (street != null && street!.isNotEmpty) {
      parts.add(street!);
    }
    return parts.join(' ');
  }
  
  /// Get address line 2 (combines building/sub-building or uses line2)
  String? getAddressLine2() {
    if (line2 != null && line2!.isNotEmpty) {
      return line2;
    }
    
    final parts = <String>[];
    if (subbuildingname != null && subbuildingname!.isNotEmpty) {
      parts.add(subbuildingname!);
    }
    if (buildingname != null && buildingname!.isNotEmpty) {
      parts.add(buildingname!);
    }
    if (organisation != null && organisation!.isNotEmpty) {
      parts.add(organisation!);
    }
    return parts.isEmpty ? null : parts.join(', ');
  }
  
  /// Get city/town
  String getCity() {
    return posttown ?? dependentlocality ?? '';
  }
  
  /// Get county/state
  String? getCounty() {
    return county;
  }
  
  /// Get postcode
  String? getPostcode() {
    return postcode;
  }
}
