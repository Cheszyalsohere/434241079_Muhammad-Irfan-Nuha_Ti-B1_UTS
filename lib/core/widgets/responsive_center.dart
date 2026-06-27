/// Constrains page content to a comfortable reading width and centers it.
///
/// This app is mobile-first, but it also runs on web (Chrome) and Windows
/// desktop where the window can be very wide. Without a cap, cards and
/// lists stretch edge-to-edge and look sparse. Wrapping a screen's
/// scrollable body in [ResponsiveCenter] keeps the layout feeling like a
/// tidy single column on any window size.
library;

import 'package:flutter/material.dart';

class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 560,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
