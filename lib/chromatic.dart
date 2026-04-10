/// A comprehensive color science library for Dart.
///
/// Provides color space conversions, perceptual color difference (Delta E),
/// chromatic adaptation, and more.
///
/// ```dart
/// import 'package:chromatic/chromatic.dart';
///
/// final red = SRgbColor(1.0, 0.0, 0.0);
/// final lab = red.toLab();
/// print(lab); // Lab(53.23, 80.11, 67.22)
///
/// final other = LabColor(50, 30, -20);
/// print(deltaE00(lab, other)); // perceptual distance
/// ```
library;

export 'src/colors.dart';
export 'src/constants.dart';
export 'src/conversions.dart';
export 'src/chromatic_adaptation.dart';
export 'src/delta_e.dart';
