import 'package:flutter/material.dart';

import '../theme/theme.dart';

extension ContextEnt on BuildContext {
  //Colors

  //MediaQuery
  double get width => MediaQuery.sizeOf(this).width;
  double get height => MediaQuery.sizeOf(this).height;
  Orientation get orientation => MediaQuery.orientationOf(this);
  EdgeInsets get padding => MediaQuery.paddingOf(this);

  //Theme
  ThemeData get lightTheme => YarisaTheme.lightThemeData(this);
  ThemeData get darkTheme => YarisaTheme.darkThemeData(this);
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  bool get isDarkMode => (theme.brightness == Brightness.dark);
  Color get primaryColor => theme.primaryColor;

  //Dimens
  EdgeInsets get paddingAll20 => const EdgeInsets.all(20);
  SizedBox get height5 => const SizedBox(height: 5);
  SizedBox get height10 => const SizedBox(height: 10);
  SizedBox get height15 => const SizedBox(height: 15);
  SizedBox get height20 => const SizedBox(height: 20);
  SizedBox get height50 => const SizedBox(height: 50);
  SizedBox get width10 => const SizedBox(width: 10);

  //Textstyles
  TextStyle? get bodyLarge => textTheme.bodyLarge;
  TextStyle? get bodyMedium => textTheme.bodyMedium;
  TextStyle? get bodySmall => textTheme.bodySmall;
  TextStyle? get labelLarge => textTheme.labelLarge;
  TextStyle? get labelMedium => textTheme.labelMedium;
  TextStyle? get labelSmall => textTheme.labelSmall;
  TextStyle? get headlineLarge => textTheme.headlineLarge;
  TextStyle? get headlineMedium => textTheme.headlineMedium;
  TextStyle? get headlineSmall => textTheme.headlineSmall;
  TextStyle? get displayLarge => textTheme.headlineLarge;
  TextStyle? get displayMedium => textTheme.headlineMedium;
  TextStyle? get displaySmall => textTheme.headlineSmall;
  TextStyle? get titleLarge => textTheme.headlineLarge;
  TextStyle? get titleMedium => textTheme.headlineMedium;
  TextStyle? get titleSmall => textTheme.headlineSmall;
}

extension WidgetPaddingX on Widget {
  Widget paddingAll(double padding) =>
      Padding(padding: EdgeInsets.all(padding), child: this);

  Widget paddingSymmetric({double horizontal = 0.0, double vertical = 0.0}) =>
      Padding(
          padding:
              EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
          child: this);

  Widget paddingOnly({
    double left = 0.0,
    double top = 0.0,
    double right = 0.0,
    double bottom = 0.0,
  }) =>
      Padding(
          padding: EdgeInsets.only(
              top: top, left: left, right: right, bottom: bottom),
          child: this);

  Widget get paddingZero => Padding(padding: EdgeInsets.zero, child: this);
}

extension WidgetMarginX on Widget {
  Widget marginAll(double margin) =>
      Container(margin: EdgeInsets.all(margin), child: this);

  Widget marginSymmetric({double horizontal = 0.0, double vertical = 0.0}) =>
      Container(
          margin:
              EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
          child: this);

  Widget marginOnly({
    double left = 0.0,
    double top = 0.0,
    double right = 0.0,
    double bottom = 0.0,
  }) =>
      Container(
          margin: EdgeInsets.only(
              top: top, left: left, right: right, bottom: bottom),
          child: this);

  Widget get marginZero => Container(margin: EdgeInsets.zero, child: this);
}

extension SizedBoxExtensions on num {
  SizedBox get hgap => SizedBox(height: toDouble());
  SizedBox get wgap => SizedBox(width: toDouble());
}

extension ListIntSumExtensions on List<int> {
  int get sumInt => fold(0, (a, b) => a + b);
}

extension ListDoubleSumExtensions on List<double> {
  double get sumInt => fold(0, (a, b) => a + b);
}

// extension NavigatorExtensions on Navigator {
//   Navigator get goto => Navigator.push(this, MaterialPageRoute(builder: (context)=> ));
// }
