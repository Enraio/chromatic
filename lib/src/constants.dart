/// Color science constants: illuminants, adaptation matrices, CIE constants.
///
/// Data sourced from CIE standards and the Python colormath library.
library;

// ── CIE constants ──────────────────────────────────────────────────────────

/// CIE epsilon: 216/24389 ≈ 0.008856
const double cieE = 216.0 / 24389.0;

/// CIE kappa: 24389/27 ≈ 903.3
const double cieK = 24389.0 / 27.0;

// ── Illuminant white points ────────────────────────────────────────────────

/// Standard illuminant white-point XYZ values.
///
/// Indexed by observer angle ('2' or '10') and illuminant name.
/// Values are [X, Y, Z] tristimulus coordinates (Y normalized to 1.0).
const Map<String, Map<String, List<double>>> illuminants = {
  '2': {
    'a': [1.09850, 1.0, 0.35585],
    'b': [0.99072, 1.0, 0.85223],
    'c': [0.98074, 1.0, 1.18232],
    'd50': [0.96422, 1.0, 0.82521],
    'd55': [0.95682, 1.0, 0.92149],
    'd65': [0.95047, 1.0, 1.08883],
    'd75': [0.94972, 1.0, 1.22638],
    'e': [1.0, 1.0, 1.0],
    'f2': [0.99186, 1.0, 0.67393],
    'f7': [0.95041, 1.0, 1.08747],
    'f11': [1.00962, 1.0, 0.64350],
  },
  '10': {
    'd50': [0.96720, 1.0, 0.81427],
    'd55': [0.95799, 1.0, 0.90926],
    'd65': [0.94811, 1.0, 1.07304],
    'd75': [0.94416, 1.0, 1.20641],
  },
};

// ── Chromatic adaptation matrices ──────────────────────────────────────────

/// 3x3 adaptation matrices as flat row-major lists.
///
/// Used in chromatic adaptation transforms to convert between
/// different illuminant white points.
const Map<String, List<double>> adaptationMatrices = {
  'xyz_scaling': [
    1.0, 0.0, 0.0, //
    0.0, 1.0, 0.0,
    0.0, 0.0, 1.0,
  ],
  'bradford': [
    0.8951, 0.2664, -0.1614, //
    -0.7502, 1.7135, 0.0367,
    0.0389, -0.0685, 1.0296,
  ],
  'von_kries': [
    0.40024, 0.70760, -0.08081, //
    -0.22630, 1.16532, 0.04570,
    0.00000, 0.00000, 0.91822,
  ],
};

// ── RGB color space definitions ────────────────────────────────────────────

/// Defines the properties of an RGB color space.
class RgbColorSpaceDef {
  const RgbColorSpaceDef({
    required this.gamma,
    required this.nativeIlluminant,
    required this.xyzToRgb,
    required this.rgbToXyz,
  });

  /// Gamma value for transfer function.
  final double gamma;

  /// Native illuminant (e.g., 'd65').
  final String nativeIlluminant;

  /// 3x3 row-major matrix: XYZ → linear RGB.
  final List<double> xyzToRgb;

  /// 3x3 row-major matrix: linear RGB → XYZ.
  final List<double> rgbToXyz;
}

/// sRGB color space (IEC 61966-2-1).
const sRgbDef = RgbColorSpaceDef(
  gamma: 2.2,
  nativeIlluminant: 'd65',
  xyzToRgb: [
    3.24071, -1.53726, -0.498571, //
    -0.969258, 1.87599, 0.0415557,
    0.0556352, -0.203996, 1.05707,
  ],
  rgbToXyz: [
    0.412424, 0.357579, 0.180464, //
    0.212656, 0.715158, 0.0721856,
    0.0193324, 0.119193, 0.950444,
  ],
);

/// Adobe RGB (1998).
const adobeRgbDef = RgbColorSpaceDef(
  gamma: 2.2,
  nativeIlluminant: 'd65',
  xyzToRgb: [
    2.04148, -0.564977, -0.344713, //
    -0.969258, 1.87599, 0.0415557,
    0.0134455, -0.118373, 1.01527,
  ],
  rgbToXyz: [
    0.5767, 0.185556, 0.188212, //
    0.297361, 0.627355, 0.0752847,
    0.0270328, 0.0706879, 0.991248,
  ],
);

/// Apple RGB.
const appleRgbDef = RgbColorSpaceDef(
  gamma: 1.8,
  nativeIlluminant: 'd65',
  xyzToRgb: [
    2.9515373, -1.2894116, -0.4738445, //
    -1.0851093, 1.9908566, 0.0372026,
    0.0854934, -0.2694964, 1.0912975,
  ],
  rgbToXyz: [
    0.4497288, 0.3162486, 0.1844926, //
    0.2446525, 0.6720283, 0.0833192,
    0.0251848, 0.1411824, 0.9224628,
  ],
);

/// ITU-R BT.2020.
const bt2020Def = RgbColorSpaceDef(
  gamma: 2.4,
  nativeIlluminant: 'd65',
  xyzToRgb: [
    1.71665, -0.35567, -0.25337, //
    -0.66668, 1.61648, 0.01576,
    0.01764, -0.04278, 0.94210,
  ],
  rgbToXyz: [
    0.63695, 0.14462, 0.16888, //
    0.26270, 0.67800, 0.05930,
    0.00000, 0.02807, 1.06098,
  ],
);
