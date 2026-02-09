import 'package:flutter/widgets.dart';

extension ContextSpacing on BuildContext {
  EdgeInsets get screenPadding =>
      const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
}
