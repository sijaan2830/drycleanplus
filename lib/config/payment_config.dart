/// Payment settings.
///
/// Change the SumUp payment link here, or pass it at build time:
///   flutter run --dart-define=SUMUP_PAY_URL=https://pay.sumup.com/b2c/XXXXXXX
class PaymentConfig {
  static const String sumupPayUrl = String.fromEnvironment(
    'SUMUP_PAY_URL',
    defaultValue: 'https://pay.sumup.com/b2c/Q3MO3NEP',
  );

  /// Order.paymentMethod values stored in Firestore.
  static const String methodSumUp = 'sumup';
  static const String methodCod = 'cod';

  /// Order.paymentStatus values stored in Firestore.
  /// `paid_unverified`: customer finished the SumUp page; staff should confirm
  /// the payment in the SumUp dashboard (a static pay link cannot call back).
  static const String statusPaidUnverified = 'paid_unverified';
  static const String statusPayOnDelivery = 'pay_on_delivery';

  /// Customer says they paid but the app could not see the success page
  /// (manual fallback). Staff should check these first in the SumUp dashboard.
  static const String statusPaidManualCheck = 'paid_manual_check';

  /// The "Mark payment as completed" button stays locked until the payment is
  /// detected. If detection fails the customer would be stuck after paying, so a
  /// small "paid but still locked?" link appears after [fallbackAfterSeconds].
  /// Set [allowManualFallback] to false to remove that escape hatch completely.
  static const bool allowManualFallback = true;
  static const int fallbackAfterSeconds = 90;
}
