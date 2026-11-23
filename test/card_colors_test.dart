import 'package:drycleanplus_app/widgets/service_price_card.dart';
import 'package:flutter_test/flutter_test.dart';

/// Admin, website and app must give a section the same card colour.
void main() {
  test('automatic colour matches the website (same palette index)', () {
    // indexes computed with the website's autoCardColors()
    const web = {'Shoe care': 8, 'Alterations': 4, 'Curtains': 9, 'Wedding dresses': 5};
    web.forEach((name, i) => expect(autoCardColors(name), kCardPalette[i], reason: name));
  });

  test('a colour picked in the admin wins', () {
    final c = serviceCardColors({'title': 'Dry Clean', 'cardColors': ['#AFC8FF', '#6C9BFF']});
    expect(c, kCardPalette[8]);
  });

  test('our own sections keep their look, new ones are not all pink', () {
    expect(serviceCardColors({'title': 'Dry Clean'}), kCardPalette[0]);
    expect(serviceCardColors({'title': 'Shoe care'}), kCardPalette[8]);
    expect(serviceCardColors({'title': 'Shoe care', 'cardColors': ['bad']}), kCardPalette[8]);
  });
}
