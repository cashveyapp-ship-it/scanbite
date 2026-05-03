import 'package:flutter/material.dart';

class AdBannerWidget extends StatelessWidget {
  const AdBannerWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Ads disabled - return empty widget
    return const SizedBox.shrink();
  }
}