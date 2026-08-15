import 'package:flutter/material.dart';

import '../screens/order_detail_screen.dart';

/// Yangi buyurtma banneridan buyurtma detail'ga o'tish.
class OrderDetailLauncher {
  OrderDetailLauncher._();

  static void open(BuildContext context, int orderId) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: orderId)),
    );
  }
}
