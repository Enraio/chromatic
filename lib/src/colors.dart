/// Color space types.
///
/// Each class represents a color in a specific color space.
/// All color objects are immutable.
library;

import 'dart:math' as math;

import 'constants.dart';

// ── Base ────────────────────────────────────────────────────────────────────

/// Base class for all color types.
abstract class ColorBase {
  const ColorBase();

  /// Returns the color values as a list.
  List<double> get values;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ColorBase &&
          runtimeType == other.runtimeType &&
          _listEquals(values, other.values);

  @override
  int get hashCode => Object.hashAll(values);

  static bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ── CIE spaces ─────────────────────────────────────────────────────────────

/// CIE 1931 XYZ color.
class XyzColor extends ColorBase {
  const XyzColor(
    this.x,
    this.y,
    this.z, {
    this.observer = '2',
    this.illuminant = 'd50',
  });

  final double x;
  final double y;
  final double z;

  /// Observer angle: '2' (2°) or '10' (10°).
  final String observer;

  /// Reference illuminant (e.g., 'd50', 'd65').
  final String illuminant;

  /// The white point [X, Y, Z] for this color's illuminant and observer.
  List<double> get whitePoint =>
      illuminants[observer]?[illuminant] ??
      (throw ArgumentError('Unknown illuminant: $observer/$illuminant'));

  @override
  List<double> get values => [x, y, z];

  @override
  String toString() => 'XYZ($x, $y, $z)';
}

/// CIE 1931 xyY chromaticity color.
class XyyColor extends ColorBase {
  const XyyColor(
    this.x,
    this.y,
    this.bigY, {
    this.observer = '2',
    this.illuminant = 'd50',
  });

  /// Chromaticity x coordinate.
  final double x;

  /// Chromaticity y coordinate.
  final double y;

  /// Luminance Y.
  final double bigY;

  final String observer;
  final String illuminant;

  @override
  List<double> get values => [x, y, bigY];

  @override
  String toString() => 'xyY($x, $y, $bigY)';
}

/// CIE L*a*b* color.
class LabColor extends ColorBase {
  const LabColor(
    this.l,
    this.a,
    this.b, {
    this.observer = '2',
    this.illuminant = 'd50',
  });

  /// Lightness (0–100).
  final double l;

  /// Green–red axis.
  final double a;

  /// Blue–yellow axis.
  final double b;

  final String observer;
  final String illuminant;

  @override
  List<double> get values => [l, a, b];

  @override
  String toString() => 'Lab($l, $a, $b)';
}

/// CIE LCH(ab) color — cylindrical form of Lab.
class LchAbColor extends ColorBase {
  const LchAbColor(
    this.l,
    this.c,
    this.h, {
    this.observer = '2',
    this.illuminant = 'd50',
  });

  /// Lightness (0–100).
  final double l;

  /// Chroma.
  final double c;

  /// Hue angle in degrees (0–360).
  final double h;

  final String observer;
  final String illuminant;

  @override
  List<double> get values => [l, c, h];

  @override
  String toString() => 'LCHab($l, $c, $h)';
}

/// CIE L*u*v* color.
class LuvColor extends ColorBase {
  const LuvColor(
    this.l,
    this.u,
    this.v, {
    this.observer = '2',
    this.illuminant = 'd50',
  });

  /// Lightness (0–100).
  final double l;

  /// u* coordinate.
  final double u;

  /// v* coordinate.
  final double v;

  final String observer;
  final String illuminant;

  @override
  List<double> get values => [l, u, v];

  @override
  String toString() => 'Luv($l, $u, $v)';
}

/// CIE LCH(uv) color — cylindrical form of Luv.
class LchUvColor extends ColorBase {
  const LchUvColor(
    this.l,
    this.c,
    this.h, {
    this.observer = '2',
    this.illuminant = 'd50',
  });

  /// Lightness (0–100).
  final double l;

  /// Chroma.
  final double c;

  /// Hue angle in degrees (0–360).
  final double h;

  final String observer;
  final String illuminant;

  @override
  List<double> get values => [l, c, h];

  @override
  String toString() => 'LCHuv($l, $c, $h)';
}

/// IPT color space (Image Processing Transform).
class IptColor extends ColorBase {
  const IptColor(
    this.i,
    this.p,
    this.t, {
    this.observer = '2',
    this.illuminant = 'd65',
  });

  /// Intensity.
  final double i;

  /// Protan (red-green).
  final double p;

  /// Tritan (blue-yellow).
  final double t;

  final String observer;
  final String illuminant;

  /// Hue angle in degrees.
  double get hueAngle {
    final angle = math.atan2(t, p) * (180.0 / math.pi);
    return angle < 0 ? angle + 360.0 : angle;
  }

  @override
  List<double> get values => [i, p, t];

  @override
  String toString() => 'IPT($i, $p, $t)';
}

// ── RGB spaces ─────────────────────────────────────────────────────────────

/// Base class for RGB color spaces.
abstract class BaseRgbColor extends ColorBase {
  const BaseRgbColor(this.r, this.g, this.b);

  /// Red channel (0.0–1.0).
  final double r;

  /// Green channel (0.0–1.0).
  final double g;

  /// Blue channel (0.0–1.0).
  final double b;

  /// The [RgbColorSpaceDef] for this RGB space.
  RgbColorSpaceDef get spaceDef;

  /// Linearize a gamma-encoded channel value.
  ///
  /// Default: simple power gamma (`v^gamma`). Subclasses override
  /// for space-specific transfer functions (e.g., sRGB EOTF).
  double linearize(double v) {
    if (v < 0) return -math.pow(-v, spaceDef.gamma).toDouble();
    return math.pow(v, spaceDef.gamma).toDouble();
  }

  /// Apply gamma encoding to a linear channel value.
  ///
  /// Default: simple power gamma (`v^(1/gamma)`). Subclasses override
  /// for space-specific transfer functions.
  double encodeGamma(double v) {
    if (v < 0) return -math.pow(-v, 1.0 / spaceDef.gamma).toDouble();
    return math.pow(v, 1.0 / spaceDef.gamma).toDouble();
  }

  /// Returns clamped [r] value (0.0–1.0).
  double get clampedR => r.clamp(0.0, 1.0);

  /// Returns clamped [g] value (0.0–1.0).
  double get clampedG => g.clamp(0.0, 1.0);

  /// Returns clamped [b] value (0.0–1.0).
  double get clampedB => b.clamp(0.0, 1.0);

  /// Returns upscaled 0–255 integer values.
  (int, int, int) get upscaled => (
    (clampedR * 255).round(),
    (clampedG * 255).round(),
    (clampedB * 255).round(),
  );

  /// Returns the hex string (e.g., '#ff0000').
  String get hex {
    final (ri, gi, bi) = upscaled;
    return '#${ri.toRadixString(16).padLeft(2, '0')}'
        '${gi.toRadixString(16).padLeft(2, '0')}'
        '${bi.toRadixString(16).padLeft(2, '0')}';
  }

  @override
  List<double> get values => [r, g, b];
}

/// sRGB color (IEC 61966-2-1).
class SRgbColor extends BaseRgbColor {
  const SRgbColor(super.r, super.g, super.b);

  /// Create from 0–255 integer values.
  factory SRgbColor.fromUpscaled(int r, int g, int b) =>
      SRgbColor(r / 255.0, g / 255.0, b / 255.0);

  /// Parse a hex string like '#ff0000' or 'ff0000'.
  factory SRgbColor.fromHex(String hex) {
    var h = hex.replaceFirst('#', '');
    if (h.length == 3) {
      h = '${h[0]}${h[0]}${h[1]}${h[1]}${h[2]}${h[2]}';
    }
    if (h.length != 6) throw FormatException('Invalid hex color: $hex');
    final value = int.parse(h, radix: 16);
    return SRgbColor(
      ((value >> 16) & 0xFF) / 255.0,
      ((value >> 8) & 0xFF) / 255.0,
      (value & 0xFF) / 255.0,
    );
  }

  @override
  RgbColorSpaceDef get spaceDef => sRgbDef;

  /// sRGB EOTF (IEC 61966-2-1) — piecewise transfer function.
  @override
  double linearize(double v) {
    if (v < 0) return -linearize(-v);
    if (v <= 0.04045) return v / 12.92;
    return math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  }

  /// sRGB OETF — piecewise inverse transfer function.
  @override
  double encodeGamma(double v) {
    if (v < 0) return -encodeGamma(-v);
    if (v <= 0.0031308) return v * 12.92;
    return 1.055 * math.pow(v, 1.0 / 2.4).toDouble() - 0.055;
  }

  @override
  String toString() => 'sRGB($r, $g, $b)';
}

/// Adobe RGB (1998) color.
class AdobeRgbColor extends BaseRgbColor {
  const AdobeRgbColor(super.r, super.g, super.b);

  @override
  RgbColorSpaceDef get spaceDef => adobeRgbDef;

  @override
  String toString() => 'AdobeRGB($r, $g, $b)';
}

/// Apple RGB color.
class AppleRgbColor extends BaseRgbColor {
  const AppleRgbColor(super.r, super.g, super.b);

  @override
  RgbColorSpaceDef get spaceDef => appleRgbDef;

  @override
  String toString() => 'AppleRGB($r, $g, $b)';
}

/// ITU-R BT.2020 color.
class Bt2020Color extends BaseRgbColor {
  const Bt2020Color(super.r, super.g, super.b);

  @override
  RgbColorSpaceDef get spaceDef => bt2020Def;

  /// BT.2020 transfer function (10-bit system).
  @override
  double linearize(double v) {
    if (v < 0) return -linearize(-v);
    const a = 1.099;
    const c = 0.08124794403514049;
    if (v <= c) return v / 4.5;
    return math.pow((v + (a - 1)) / a, 1.0 / 0.45).toDouble();
  }

  @override
  double encodeGamma(double v) {
    if (v < 0) return -encodeGamma(-v);
    const a = 1.099;
    const b = 0.018;
    if (v < b) return v * 4.5;
    return a * math.pow(v, 0.45).toDouble() - (a - 1);
  }

  @override
  String toString() => 'BT2020($r, $g, $b)';
}

// ── HSL / HSV ──────────────────────────────────────────────────────────────

/// HSL (Hue, Saturation, Lightness) color.
class HslColor extends ColorBase {
  const HslColor(this.h, this.s, this.l);

  /// Hue in degrees (0–360).
  final double h;

  /// Saturation (0.0–1.0).
  final double s;

  /// Lightness (0.0–1.0).
  final double l;

  @override
  List<double> get values => [h, s, l];

  @override
  String toString() => 'HSL($h, $s, $l)';
}

/// HSV (Hue, Saturation, Value) color.
class HsvColor extends ColorBase {
  const HsvColor(this.h, this.s, this.v);

  /// Hue in degrees (0–360).
  final double h;

  /// Saturation (0.0–1.0).
  final double s;

  /// Value (0.0–1.0).
  final double v;

  @override
  List<double> get values => [h, s, v];

  @override
  String toString() => 'HSV($h, $s, $v)';
}

// ── CMY / CMYK ─────────────────────────────────────────────────────────────

/// CMY (Cyan, Magenta, Yellow) color.
class CmyColor extends ColorBase {
  const CmyColor(this.c, this.m, this.y);

  final double c;
  final double m;
  final double y;

  @override
  List<double> get values => [c, m, y];

  @override
  String toString() => 'CMY($c, $m, $y)';
}

/// CMYK (Cyan, Magenta, Yellow, Key/Black) color.
class CmykColor extends ColorBase {
  const CmykColor(this.c, this.m, this.y, this.k);

  final double c;
  final double m;
  final double y;
  final double k;

  @override
  List<double> get values => [c, m, y, k];

  @override
  String toString() => 'CMYK($c, $m, $y, $k)';
}
