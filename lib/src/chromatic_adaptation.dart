/// Chromatic adaptation transforms.
///
/// Converts colors between different illuminant white points using
/// Bradford, von Kries, or XYZ scaling methods.
library;

import 'constants.dart';
import 'colors.dart';

/// Applies chromatic adaptation to XYZ values.
///
/// Transforms color from [sourceIlluminant] to [targetIlluminant]
/// using the specified [method] ('bradford', 'von_kries', or 'xyz_scaling').
///
/// ```dart
/// final adapted = chromaticAdapt(
///   0.5, 0.4, 0.1,
///   sourceIlluminant: 'c',
///   targetIlluminant: 'd65',
/// );
/// ```
(double x, double y, double z) chromaticAdapt(
  double x,
  double y,
  double z, {
  required String sourceIlluminant,
  required String targetIlluminant,
  String observer = '2',
  String method = 'bradford',
}) {
  if (sourceIlluminant == targetIlluminant) return (x, y, z);

  final wpSrc = _resolveWhitePoint(sourceIlluminant, observer);
  final wpDst = _resolveWhitePoint(targetIlluminant, observer);
  final matrix = _getAdaptationMatrix(wpSrc, wpDst, method);

  return _mulMatrix3x3(matrix, x, y, z);
}

/// Adapts an [XyzColor] to a new illuminant, returning a new [XyzColor].
XyzColor adaptXyzColor(
  XyzColor color, {
  required String targetIlluminant,
  String method = 'bradford',
}) {
  final (nx, ny, nz) = chromaticAdapt(
    color.x,
    color.y,
    color.z,
    sourceIlluminant: color.illuminant,
    targetIlluminant: targetIlluminant,
    observer: color.observer,
    method: method,
  );
  return XyzColor(
    nx,
    ny,
    nz,
    observer: color.observer,
    illuminant: targetIlluminant,
  );
}

// ── Internal ───────────────────────────────────────────────────────────────

List<double> _resolveWhitePoint(String illuminant, String observer) {
  final wp = illuminants[observer]?[illuminant];
  if (wp == null) {
    throw ArgumentError(
      'Unknown illuminant "$illuminant" for observer "$observer"',
    );
  }
  return wp;
}

/// Computes the full adaptation transform matrix.
///
/// M_adapt = M_sharp^-1 * diag(rgb_dst / rgb_src) * M_sharp
List<double> _getAdaptationMatrix(
  List<double> wpSrc,
  List<double> wpDst,
  String method,
) {
  final mSharp = adaptationMatrices[method] ?? adaptationMatrices['bradford']!;
  final mSharpInv = _invert3x3(mSharp);

  // Cone response of source and destination white points.
  final (srcR, srcG, srcB) = _mulMatrix3x3(
    mSharp,
    wpSrc[0],
    wpSrc[1],
    wpSrc[2],
  );
  final (dstR, dstG, dstB) = _mulMatrix3x3(
    mSharp,
    wpDst[0],
    wpDst[1],
    wpDst[2],
  );

  // Diagonal scaling matrix (as flat 3x3).
  final mRat = [
    dstR / srcR, 0.0, 0.0, //
    0.0, dstG / srcG, 0.0,
    0.0, 0.0, dstB / srcB,
  ];

  // M_adapt = M_sharp^-1 * M_rat * M_sharp
  final temp = _mulMatrix3x3ByMatrix3x3(mRat, mSharp);
  return _mulMatrix3x3ByMatrix3x3(mSharpInv, temp);
}

// ── 3x3 matrix math (row-major flat lists) ─────────────────────────────────

(double, double, double) _mulMatrix3x3(
  List<double> m,
  double x,
  double y,
  double z,
) {
  return (
    m[0] * x + m[1] * y + m[2] * z,
    m[3] * x + m[4] * y + m[5] * z,
    m[6] * x + m[7] * y + m[8] * z,
  );
}

List<double> _mulMatrix3x3ByMatrix3x3(List<double> a, List<double> b) {
  return [
    for (var row = 0; row < 3; row++)
      for (var col = 0; col < 3; col++)
        a[row * 3 + 0] * b[0 * 3 + col] +
            a[row * 3 + 1] * b[1 * 3 + col] +
            a[row * 3 + 2] * b[2 * 3 + col],
  ];
}

List<double> _invert3x3(List<double> m) {
  final a = m[0], b = m[1], c = m[2];
  final d = m[3], e = m[4], f = m[5];
  final g = m[6], h = m[7], i = m[8];

  final det = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);

  if (det.abs() < 1e-15) {
    throw StateError('Singular matrix cannot be inverted');
  }

  final invDet = 1.0 / det;
  return [
    (e * i - f * h) * invDet,
    (c * h - b * i) * invDet,
    (b * f - c * e) * invDet,
    (f * g - d * i) * invDet,
    (a * i - c * g) * invDet,
    (c * d - a * f) * invDet,
    (d * h - e * g) * invDet,
    (b * g - a * h) * invDet,
    (a * e - b * d) * invDet,
  ];
}
