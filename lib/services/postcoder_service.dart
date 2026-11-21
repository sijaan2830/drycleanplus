import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Postcoder (Allies Computing) address lookup + reverse geocoding
/// with high-reliability fallback to OpenStreetMap Nominatim and BigDataCloud
/// so real-time GPS location extraction NEVER fails, even when Postcoder
/// credits run out or when operating outside the UK.
class PostcoderService {
  static const String _apiKey = String.fromEnvironment(
    'POSTCODER_API_KEY',
    defaultValue: 'PCW77-79WWM-3NFEZ-PTNG9',
  );
  static const String _baseUrl = 'https://ws.postcoder.com/pcw';
  static const Duration _timeout = Duration(seconds: 10);
  static const String _userAgent = 'DrycleanPlusApp/1.0 (contact@drycleanplus.co.uk)';
  static final Map<String, LookupResult> _addressCache = {};

  /// Search by postcode or partial address text.
  /// Falls back to postcodes.io and Nominatim if Postcoder credits are exhausted.
  static Future<LookupResult> searchAddresses(
    String query, {
    String country = 'uk',
  }) async {
    final q = query.trim();
    if (q.isEmpty) return const LookupResult([]);

    final cacheKey = '${country.toUpperCase()}_${q.toUpperCase()}';
    if (_addressCache.containsKey(cacheKey)) {
      return _addressCache[cacheKey]!;
    }

    // 1) Try Postcoder
    try {
      final uri = Uri.parse('$_baseUrl/$_apiKey/address/$country/${Uri.encodeComponent(q)}')
          .replace(queryParameters: {'format': 'json', 'lines': '3', 'addtags': 'latitude,longitude,uprn,udprn'});
      final res = await _get(uri);
      if (res.items.isNotEmpty) {
        _addressCache[cacheKey] = res;
        return res;
      }
    } catch (e) {
      debugPrint('Postcoder search error: $e');
    }

    // 2) Try postcodes.io for UK postcodes (free, unlimited, instant)
    if (country.toLowerCase() == 'uk' || country.isEmpty) {
      final pio = await searchPostcodesIo(q);
      if (pio.items.isNotEmpty) return pio;
    }

    // 3) Try OpenStreetMap Nominatim search (free fallback)
    final osm = await searchNominatim(q, country: country);
    if (osm.items.isNotEmpty) return osm;

    return const LookupResult([]);
  }

  /// Turn GPS coordinates into nearby addresses in real time.
  /// Tier 1: Postcoder (if active and credits exist)
  /// Tier 2: OpenStreetMap Nominatim (Free, high accuracy, real-time, zero credits)
  /// Tier 3: BigDataCloud (Free client reverse geocoding fallback)
  static Future<LookupResult> reverseGeocode(
    double latitude,
    double longitude, {
    String country = 'uk',
    int distance = 60,
  }) async {
    // 1) Postcoder full addresses (house level)
    try {
      final full = Uri.parse('$_baseUrl/$_apiKey/reversegeo/$country/$latitude/$longitude').replace(
        queryParameters: {
          'distance': '$distance',
          'lines': '3',
          'format': 'json',
          'addtags': 'latitude,longitude',
        },
      );
      final fullResult = await _get(full);
      if (fullResult.items.isNotEmpty) return fullResult;

      // Street-level fallback
      final street = Uri.parse('$_baseUrl/$_apiKey/rgeo/$country/$latitude/$longitude').replace(
        queryParameters: {'distance': '${distance * 2}', 'format': 'json'},
      );
      final streetResult = await _get(street);
      if (streetResult.items.isNotEmpty) return streetResult;
    } catch (e) {
      debugPrint('Postcoder reverse geo exception: $e');
    }

    // 2) OpenStreetMap Nominatim fallback (Real-time, free, global)
    final osmResult = await reverseGeocodeNominatim(latitude, longitude);
    if (osmResult.items.isNotEmpty) return osmResult;

    // 3) BigDataCloud fallback (Real-time, free)
    final bdcResult = await reverseGeocodeBigDataCloud(latitude, longitude);
    if (bdcResult.items.isNotEmpty) return bdcResult;

    return const LookupResult([], error: 'Could not extract address from GPS location.');
  }

  /// OpenStreetMap Nominatim reverse geocode (Real-time, free, worldwide)
  static Future<LookupResult> reverseGeocodeNominatim(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&addressdetails=1&zoom=18&accept-language=en&lat=$lat&lon=$lon',
      );
      final response = await http
          .get(uri, headers: {
            'User-Agent': _userAgent,
            'Accept': 'application/json',
          })
          .timeout(const Duration(seconds: 9));

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          final addr = (decoded['address'] as Map<String, dynamic>?) ?? {};

          final houseNum = _s(addr['house_number'] ?? addr['house_name']);
          final road = _s(addr['road'] ?? addr['pedestrian'] ?? addr['footway'] ?? addr['residential'] ?? addr['street']);
          final building = _s(addr['amenity'] ?? addr['building'] ?? addr['historic'] ?? addr['shop']);

          String line1 = '';
          if (houseNum.isNotEmpty && road.isNotEmpty) {
            line1 = '$houseNum $road';
          } else if (road.isNotEmpty) {
            line1 = road;
          } else if (building.isNotEmpty) {
            line1 = building;
          } else {
            line1 = _s(addr['neighbourhood'] ?? addr['suburb'] ?? decoded['name']);
          }

          final line2 = _s(addr['suburb'] ?? addr['quarter'] ?? addr['neighbourhood']);
          final city = _s(addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['hamlet'] ?? addr['county'] ?? addr['municipality']);
          final county = _s(addr['county'] ?? addr['state']);
          final postcode = _s(addr['postcode']).toUpperCase();

          if (line1.isNotEmpty || city.isNotEmpty || postcode.isNotEmpty) {
            final summary = [line1, if (line2.isNotEmpty && line2 != line1) line2, city, postcode]
                .where((e) => e.isNotEmpty)
                .join(', ');

            final item = PostcoderAddress(
              line1: line1.isEmpty ? (line2.isNotEmpty ? line2 : city) : line1,
              line2: (line2 == line1) ? '' : line2,
              city: city.isEmpty ? county : city,
              county: county,
              postcode: postcode,
              summary: summary,
              buildingName: building,
              streetOnly: houseNum.isEmpty,
              latitude: lat,
              longitude: lon,
            );
            return LookupResult([item]);
          }
        }
      }
    } catch (e) {
      debugPrint('Nominatim reverse geocode error: $e');
    }
    return const LookupResult([]);
  }

  /// BigDataCloud reverse geocode (Free client API, secondary fallback)
  static Future<LookupResult> reverseGeocodeBigDataCloud(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=$lat&longitude=$lon&localityLanguage=en',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          final locality = _s(decoded['locality']);
          final city = _s(decoded['city'] ?? decoded['principalSubdivision']);
          final county = _s(decoded['principalSubdivision']);
          final postcode = _s(decoded['postcode']).toUpperCase();

          final line1 = locality.isNotEmpty ? locality : city;
          if (line1.isNotEmpty || postcode.isNotEmpty) {
            final summary = [line1, city, postcode].where((e) => e.isNotEmpty).join(', ');
            final item = PostcoderAddress(
              line1: line1,
              city: city.isEmpty ? county : city,
              county: county,
              postcode: postcode,
              summary: summary,
              streetOnly: true,
              latitude: lat,
              longitude: lon,
            );
            return LookupResult([item]);
          }
        }
      }
    } catch (e) {
      debugPrint('BigDataCloud reverse geocode error: $e');
    }
    return const LookupResult([]);
  }

  /// Postcodes.io (Free, unlimited UK postcode lookup)
  static Future<LookupResult> searchPostcodesIo(String query) async {
    final clean = query.replaceAll(' ', '').toUpperCase();
    if (clean.length < 5) return const LookupResult([]);

    try {
      final uri = Uri.parse('https://api.postcodes.io/postcodes/${Uri.encodeComponent(clean)}');
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic> && decoded['result'] is Map<String, dynamic>) {
          final r = decoded['result'] as Map<String, dynamic>;
          final district = _s(r['admin_district']);
          final ward = _s(r['admin_ward']);
          final region = _s(r['region']);
          final postcode = _s(r['postcode']);
          final lat = (r['latitude'] as num?)?.toDouble();
          final lng = (r['longitude'] as num?)?.toDouble();

          final line1 = ward.isNotEmpty ? ward : district;
          final city = district.isNotEmpty ? district : region;
          final summary = '$postcode, $district, England';

          final item = PostcoderAddress(
            line1: line1,
            city: city,
            county: region,
            postcode: postcode,
            summary: summary,
            streetOnly: true,
            latitude: lat,
            longitude: lng,
          );
          return LookupResult([item]);
        }
      }
    } catch (e) {
      debugPrint('Postcodes.io search error: $e');
    }
    return const LookupResult([]);
  }

  /// Nominatim search (Free postcode/place search)
  static Future<LookupResult> searchNominatim(String query, {String country = 'uk'}) async {
    try {
      final countryCode = country.toLowerCase() == 'ie' ? 'ie' : 'gb';
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=jsonv2&addressdetails=1&q=${Uri.encodeComponent(query)}&countrycodes=$countryCode&limit=10',
      );
      final response = await http
          .get(uri, headers: {
            'User-Agent': _userAgent,
            'Accept': 'application/json',
          })
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          final items = <PostcoderAddress>[];
          for (final raw in decoded) {
            if (raw is! Map<String, dynamic>) continue;
            final addr = (raw['address'] as Map<String, dynamic>?) ?? {};
            final houseNum = _s(addr['house_number'] ?? addr['house_name']);
            final road = _s(addr['road'] ?? addr['pedestrian'] ?? addr['footway'] ?? addr['street']);
            final building = _s(addr['amenity'] ?? addr['building'] ?? raw['name']);

            String line1 = '';
            if (houseNum.isNotEmpty && road.isNotEmpty) {
              line1 = '$houseNum $road';
            } else if (road.isNotEmpty) {
              line1 = road;
            } else if (building.isNotEmpty) {
              line1 = building;
            } else {
              line1 = _s(raw['display_name']).split(',').first.trim();
            }

            final city = _s(addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county']);
            final postcode = _s(addr['postcode']).toUpperCase();
            final summary = _s(raw['display_name']);

            if (line1.isNotEmpty || city.isNotEmpty || postcode.isNotEmpty) {
              items.add(
                PostcoderAddress(
                  line1: line1,
                  city: city,
                  county: _s(addr['county'] ?? addr['state']),
                  postcode: postcode,
                  summary: summary,
                  streetOnly: houseNum.isEmpty,
                  latitude: double.tryParse(_s(raw['lat'])),
                  longitude: double.tryParse(_s(raw['lon'])),
                ),
              );
            }
          }
          if (items.isNotEmpty) return LookupResult(items);
        }
      }
    } catch (e) {
      debugPrint('Nominatim search error: $e');
    }
    return const LookupResult([]);
  }

  static Future<LookupResult> _get(Uri uri) async {
    try {
      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = json.decode(utf8.decode(response.bodyBytes));
        if (decoded is List) {
          final items = decoded
              .whereType<Map>()
              .map((e) => PostcoderAddress.fromJson(Map<String, dynamic>.from(e)))
              .where((a) => a.postcode.isNotEmpty || a.line1.isNotEmpty)
              .toList();
          return LookupResult(items);
        }
        return const LookupResult([]);
      }

      if (response.statusCode == 404) return const LookupResult([]);
      if (response.statusCode == 401 || response.statusCode == 403) {
        return const LookupResult([], error: 'Address lookup is not enabled for this key.');
      }
      if (response.statusCode == 402) {
        return const LookupResult([], error: 'Address lookup credits are exhausted.');
      }
      return LookupResult(const [], error: 'Address lookup failed (${response.statusCode}).');
    } on TimeoutException {
      return const LookupResult([], error: 'Address lookup timed out. Check your connection.');
    } catch (e) {
      return const LookupResult([], error: 'Could not reach address lookup. Check your connection.');
    }
  }

  static String _s(dynamic v) => (v ?? '').toString().trim();
}

class LookupResult {
  final List<PostcoderAddress> items;
  final String? error;
  const LookupResult(this.items, {this.error});
}

/// One address returned by Postcoder or OpenStreetMap fallback
class PostcoderAddress {
  final String line1;
  final String line2;
  final String city;
  final String county;
  final String postcode;
  final String summary;
  final String buildingName;
  final bool streetOnly;
  final double? latitude;
  final double? longitude;

  const PostcoderAddress({
    required this.line1,
    this.line2 = '',
    required this.city,
    this.county = '',
    required this.postcode,
    required this.summary,
    this.buildingName = '',
    this.streetOnly = false,
    this.latitude,
    this.longitude,
  });

  static String _s(dynamic v) => (v ?? '').toString().trim();

  factory PostcoderAddress.fromJson(Map<String, dynamic> j) {
    final number = _s(j['number']);
    final street = _s(j['street']);
    final premise = _s(j['premise']);
    final building = _s(j['buildingname']);
    final subBuilding = _s(j['subbuildingname']);
    final org = _s(j['organisation']);

    var line1 = _s(j['addressline1']);
    var line2 = _s(j['addressline2']);
    final line3 = _s(j['addressline3']);

    if (line1.isEmpty) line1 = _s(j['line1']);
    if (line1.isEmpty) {
      line1 = [
        if (premise.isNotEmpty) premise else if (number.isNotEmpty) number,
        street,
      ].where((e) => e.isNotEmpty).join(' ');
    }
    if (line2.isEmpty) line2 = _s(j['line2']);
    if (line2.isEmpty) {
      line2 = [subBuilding, building, org].where((e) => e.isNotEmpty).join(', ');
    }
    if (line3.isNotEmpty) {
      line2 = line2.isEmpty ? line3 : '$line2, $line3';
    }

    final city = _s(j['posttown']).isNotEmpty ? _s(j['posttown']) : _s(j['dependentlocality']);
    final postcode = _s(j['postcode']);
    final summary = _s(j['summaryline']).isNotEmpty
        ? _s(j['summaryline'])
        : [line1, line2, city, postcode].where((e) => e.isNotEmpty).join(', ');

    final streetOnly = _s(j['addressline1']).isEmpty && number.isEmpty && premise.isEmpty && building.isEmpty;

    return PostcoderAddress(
      line1: line1,
      line2: line2,
      city: city,
      county: _s(j['county']),
      postcode: postcode,
      summary: summary,
      buildingName: building,
      streetOnly: streetOnly,
      latitude: double.tryParse(_s(j['latitude'])),
      longitude: double.tryParse(_s(j['longitude'])),
    );
  }

  String get displayLine {
    final parts = [line1, if (line2.isNotEmpty) line2, city, postcode].where((e) => e.isNotEmpty);
    return parts.join(', ');
  }
}
