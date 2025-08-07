import 'package:flutter/material.dart';

extension ScreenSizeExtension on BuildContext {
  double heightPercent(double percent) =>
      MediaQuery.of(this).size.height * percent;

  double widthPercent(double percent) =>
      MediaQuery.of(this).size.width * percent;
}
