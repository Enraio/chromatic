import 'package:chromatic/chromatic.dart' as c;
import 'package:flutter/material.dart';

/// Convert Flutter [Color] to chromatic [c.SRgbColor].
c.SRgbColor toChromatic(Color color) =>
    c.SRgbColor(color.r, color.g, color.b);

/// Convert chromatic [c.SRgbColor] back to Flutter [Color].
Color toFlutterColor(c.SRgbColor srgb) => Color.from(
      alpha: 1.0,
      red: srgb.r.clamp(0.0, 1.0),
      green: srgb.g.clamp(0.0, 1.0),
      blue: srgb.b.clamp(0.0, 1.0),
    );

/// Format a Flutter [Color] as `#rrggbb`.
String hexOf(Color color) {
  String two(double v) =>
      (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '#${two(color.r)}${two(color.g)}${two(color.b)}';
}

/// Linear interpolation helper.
double lerp(double a, double b, double t) => a + (b - a) * t;

/// Perceptually-uniform color interpolation in Lab space.
Color lerpLab(Color a, Color b, double t) {
  final labA = c.sRgbToLab(toChromatic(a));
  final labB = c.sRgbToLab(toChromatic(b));
  final lab = c.LabColor(
    lerp(labA.l, labB.l, t),
    lerp(labA.a, labB.a, t),
    lerp(labA.b, labB.b, t),
  );
  return toFlutterColor(c.labToSRgb(lab));
}
