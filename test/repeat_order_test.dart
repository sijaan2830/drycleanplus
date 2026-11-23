import 'package:drycleanplus_app/models/booking_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// The website saves repeatOrder as text ('weekly' / ''), older app builds as true/false.
void main() {
  BookingData read(Object? v) => BookingData.fromJson({'repeatOrder': v});

  test('website text values', () {
    expect(read('weekly').repeatOrder, isTrue);
    expect(read('fortnightly').repeatOrder, isTrue);
    expect(read('').repeatOrder, isFalse);
    expect(read(null).repeatOrder, isFalse);
  });

  test('old app booleans', () {
    expect(read(true).repeatOrder, isTrue);
    expect(read(false).repeatOrder, isFalse);
  });

  test('app now writes the website format', () {
    expect(BookingData(repeatOrder: true).toJson()['repeatOrder'], 'weekly');
    expect(BookingData().toJson()['repeatOrder'], '');
  });
}
