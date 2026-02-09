import 'package:flutter/widgets.dart';

class Breakpoints {
  const Breakpoints._();

  static const double tabletMin = 768;
  static const double desktopMin = 1024;
}

extension ResponsiveContext on BuildContext {
  bool get isMobile => MediaQuery.of(this).size.width < Breakpoints.tabletMin;
  bool get isTablet {
    final width = MediaQuery.of(this).size.width;
    return width >= Breakpoints.tabletMin && width <= Breakpoints.desktopMin;
  }

  bool get isDesktop => MediaQuery.of(this).size.width > Breakpoints.desktopMin;
}

class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    if (context.isDesktop) {
      return desktop ?? tablet ?? mobile;
    }
    if (context.isTablet) {
      return tablet ?? mobile;
    }
    return mobile;
  }
}
