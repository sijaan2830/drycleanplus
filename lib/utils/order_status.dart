import 'package:flutter/material.dart';

/// Single source of truth for how an order status looks (orders list,
/// track order, past orders). 'completed' and 'delivered' are the same thing.
class OrderStatusInfo {
  final String label;
  final String description;
  final Color color;
  final IconData icon;

  /// 0 = placed … 4 = delivered, -1 = cancelled.
  final int step;

  const OrderStatusInfo({
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
    required this.step,
  });
}

const List<(String, String, IconData)> kOrderSteps = [
  ('Order placed', 'We have your booking and will collect in your slot', Icons.receipt_long_rounded),
  ('Collected', 'Your driver has your bags', Icons.inventory_2_rounded),
  ('Cleaning', 'Checked in and being cleaned at our facility', Icons.local_laundry_service_rounded),
  ('On the way', 'Your clean clothes are coming back', Icons.local_shipping_rounded),
  ('Delivered', 'Your order has been delivered', Icons.check_circle_rounded),
];

/// Old status names written by earlier app versions → the shared list
/// used by the website, this app, the driver app, the intake app and the admin panel.
String normalizeOrderStatus(String status) {
  final s = status.trim().toLowerCase();
  switch (s) {
    case 'processing':
    case 'in_progress':
      return 'cleaning';
    case 'ready':
      return 'ready_for_delivery';
    case 'in_transit':
      return 'out_for_delivery';
    case 'completed':
      return 'delivered';
    default:
      return s;
  }
}

/// The driver is on the road to this customer (live map is shown).
bool isLiveOrderStatus(String status) => const {
      'pickup_en_route',
      'pickup_arrived',
      'out_for_delivery',
      'delivery_arrived',
    }.contains(normalizeOrderStatus(status));

/// The order is still moving (not delivered, failed-and-closed or cancelled).
bool isActiveOrderStatus(String status) {
  final s = normalizeOrderStatus(status);
  return s != 'delivered' && s != 'cancelled';
}

OrderStatusInfo orderStatusInfo(String status) {
  const placed = Color(0xFFFFE58C), collected = Color(0xFFD6EAFF), cleaning = Color(0xFF9AD0FF), way = Color(0xFFB8E6FF);
  switch (normalizeOrderStatus(status)) {
    case 'pending':
      return const OrderStatusInfo(label: 'Order placed', description: 'Waiting for confirmation', color: placed, icon: Icons.hourglass_top_rounded, step: 0);
    case 'confirmed':
      return const OrderStatusInfo(label: 'Confirmed', description: 'Your collection slot is booked', color: placed, icon: Icons.event_available_rounded, step: 0);
    case 'pickup_assigned':
      return const OrderStatusInfo(label: 'Driver assigned', description: 'A driver will collect in your slot', color: placed, icon: Icons.person_pin_circle_rounded, step: 0);
    case 'pickup_en_route':
      return const OrderStatusInfo(label: 'Driver on the way', description: 'Follow your driver live on the map', color: placed, icon: Icons.local_shipping_rounded, step: 0);
    case 'pickup_arrived':
      return const OrderStatusInfo(label: 'Driver is outside', description: 'Your driver has arrived to collect', color: placed, icon: Icons.where_to_vote_rounded, step: 0);
    case 'pickup_failed':
      return const OrderStatusInfo(label: 'Collection missed', description: 'We couldn’t collect — please reschedule', color: Color(0xFFFFC2C6), icon: Icons.event_busy_rounded, step: 0);
    case 'collected':
      return const OrderStatusInfo(label: 'Collected', description: 'Your driver has your bags', color: collected, icon: Icons.inventory_2_rounded, step: 1);
    case 'at_facility':
      return const OrderStatusInfo(label: 'At our facility', description: 'Your bags have arrived at our facility', color: collected, icon: Icons.warehouse_rounded, step: 1);
    case 'inspecting':
      return const OrderStatusInfo(label: 'Checking items', description: 'We’re counting and checking every item', color: cleaning, icon: Icons.fact_check_rounded, step: 2);
    case 'awaiting_approval':
      return const OrderStatusInfo(label: 'Needs your OK', description: 'Please approve the updated total', color: Color(0xFFFFD7A8), icon: Icons.pending_actions_rounded, step: 2);
    case 'cleaning':
      return const OrderStatusInfo(label: 'Cleaning', description: 'Your items are being cleaned', color: cleaning, icon: Icons.local_laundry_service_rounded, step: 2);
    case 'quality_check':
      return const OrderStatusInfo(label: 'Quality check', description: 'Final checks and packing', color: cleaning, icon: Icons.verified_rounded, step: 2);
    case 'ready_for_delivery':
      return const OrderStatusInfo(label: 'Ready', description: 'Packed and ready for delivery', color: cleaning, icon: Icons.checkroom_rounded, step: 2);
    case 'delivery_assigned':
      return const OrderStatusInfo(label: 'Delivery booked', description: 'A driver will deliver in your slot', color: way, icon: Icons.person_pin_circle_rounded, step: 3);
    case 'out_for_delivery':
      return const OrderStatusInfo(label: 'Out for delivery', description: 'Follow your driver live on the map', color: way, icon: Icons.local_shipping_rounded, step: 3);
    case 'delivery_arrived':
      return const OrderStatusInfo(label: 'Driver is outside', description: 'Your driver has arrived with your order', color: way, icon: Icons.where_to_vote_rounded, step: 3);
    case 'delivery_failed':
      return const OrderStatusInfo(label: 'Delivery missed', description: 'We couldn’t deliver — please reschedule', color: Color(0xFFFFC2C6), icon: Icons.event_busy_rounded, step: 3);
    case 'delivered':
      return const OrderStatusInfo(label: 'Delivered', description: 'Your order has been delivered', color: Color(0xFF7CFFB0), icon: Icons.check_circle_rounded, step: 4);
    case 'cancelled':
      return const OrderStatusInfo(label: 'Cancelled', description: 'This order was cancelled', color: Color(0xFFFF8A80), icon: Icons.cancel_rounded, step: -1);
    default:
      return OrderStatusInfo(
        label: status.isEmpty ? 'Unknown' : status.replaceAll('_', ' '),
        description: '',
        color: const Color(0xFFCFD8DC),
        icon: Icons.help_outline_rounded,
        step: 0,
      );
  }
}

bool isOrderDelivered(String status) => normalizeOrderStatus(status) == 'delivered';

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String formatOrderDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

/// 'cod' → "Pay on delivery", 'sumup' → "Paid online", otherwise null.
String? paymentMethodLabel(String? method) {
  switch (method) {
    case 'cod':
      return 'Pay on delivery';
    case 'sumup':
      return 'Paid online';
    default:
      return null;
  }
}
