/// Color difference (Delta E) formulas.
///
/// All formulas operate on [LabColor] values. Ported from Python colormath
/// with identical math validated against the Sharma 2005 reference dataset.
library;

import 'dart:math' as math;

import 'colors.dart';

/// CIE76 color difference — simple Euclidean distance in Lab.
///
/// Fast but perceptually inaccurate, especially for saturated colors.
double deltaE76(LabColor c1, LabColor c2) {
  final dL = c1.l - c2.l;
  final da = c1.a - c2.a;
  final db = c1.b - c2.b;
  return math.sqrt(dL * dL + da * da + db * db);
}

/// CIE94 color difference.
///
/// Weighted formula with industry-specific parameters:
/// - Graphic arts (default): kL=1, k1=0.045, k2=0.015
/// - Textiles: kL=2, k1=0.048, k2=0.014
double deltaE94(
  LabColor c1,
  LabColor c2, {
  double kL = 1,
  double kC = 1,
  double kH = 1,
  double k1 = 0.045,
  double k2 = 0.015,
}) {
  final dL = c1.l - c2.l;

  final c1C = math.sqrt(c1.a * c1.a + c1.b * c1.b);
  final c2C = math.sqrt(c2.a * c2.a + c2.b * c2.b);
  final dC = c1C - c2C;

  final da = c1.a - c2.a;
  final db = c1.b - c2.b;
  final dHSq = da * da + db * db - dC * dC;
  // Clamp to avoid sqrt of negative due to floating point.
  final dH = math.sqrt(math.max(0.0, dHSq));

  final sL = 1.0;
  final sC = 1.0 + k1 * c1C;
  final sH = 1.0 + k2 * c1C;

  final lTerm = dL / (kL * sL);
  final cTerm = dC / (kC * sC);
  final hTerm = dH / (kH * sH);

  return math.sqrt(lTerm * lTerm + cTerm * cTerm + hTerm * hTerm);
}

/// CIEDE2000 color difference — the gold standard.
///
/// Includes five corrections for perceptual non-uniformity:
/// lightness, chroma, hue weighting, hue rotation (blue region fix),
/// and neutral color handling.
///
/// Reference: Sharma, Wu, Dalal (2005). "The CIEDE2000 Color-Difference Formula."
double deltaE00(
  LabColor c1,
  LabColor c2, {
  double kL = 1,
  double kC = 1,
  double kH = 1,
}) {
  final l1 = c1.l, a1 = c1.a, b1 = c1.b;
  final l2 = c2.l, a2 = c2.a, b2 = c2.b;

  // Step 1: Calculate Cab, hab.
  final avgLp = (l1 + l2) / 2.0;

  final c1ab = math.sqrt(a1 * a1 + b1 * b1);
  final c2ab = math.sqrt(a2 * a2 + b2 * b2);
  final avgCab = (c1ab + c2ab) / 2.0;

  final avgCab7 = math.pow(avgCab, 7);
  final g = 0.5 * (1 - math.sqrt(avgCab7 / (avgCab7 + math.pow(25, 7))));

  final a1p = (1 + g) * a1;
  final a2p = (1 + g) * a2;

  final c1p = math.sqrt(a1p * a1p + b1 * b1);
  final c2p = math.sqrt(a2p * a2p + b2 * b2);
  final avgCp = (c1p + c2p) / 2.0;

  var h1p = math.atan2(b1, a1p) * _rad2deg;
  if (h1p < 0) h1p += 360;

  var h2p = math.atan2(b2, a2p) * _rad2deg;
  if (h2p < 0) h2p += 360;

  final hDiff = (h1p - h2p).abs();
  final avgHp = hDiff > 180 ? (h1p + h2p + 360) / 2.0 : (h1p + h2p) / 2.0;

  final t =
      1 -
      0.17 * math.cos(_deg2rad(avgHp - 30)) +
      0.24 * math.cos(_deg2rad(2 * avgHp)) +
      0.32 * math.cos(_deg2rad(3 * avgHp + 6)) -
      0.20 * math.cos(_deg2rad(4 * avgHp - 63));

  var dhp = h2p - h1p;
  if (hDiff > 180) {
    if (h2p <= h1p) {
      dhp += 360;
    } else {
      dhp -= 360;
    }
  }

  final dLp = l2 - l1;
  final dCp = c2p - c1p;
  final dHp = 2 * math.sqrt(c1p * c2p) * math.sin(_deg2rad(dhp) / 2.0);

  final sL =
      1 +
      (0.015 * math.pow(avgLp - 50, 2)) /
          math.sqrt(20 + math.pow(avgLp - 50, 2));
  final sC = 1 + 0.045 * avgCp;
  final sH = 1 + 0.015 * avgCp * t;

  final dTheta = 30 * math.exp(-math.pow((avgHp - 275) / 25, 2));
  final avgCp7 = math.pow(avgCp, 7);
  final rC = math.sqrt(avgCp7 / (avgCp7 + math.pow(25, 7)));
  final rT = -2 * rC * math.sin(_deg2rad(2 * dTheta));

  final lComp = dLp / (sL * kL);
  final cComp = dCp / (sC * kC);
  final hComp = dHp / (sH * kH);

  return math.sqrt(
    lComp * lComp + cComp * cComp + hComp * hComp + rT * cComp * hComp,
  );
}

/// CMC l:c color difference.
///
/// Modes:
/// - Acceptability: pl=2, pc=1 (default)
/// - Perceptibility: pl=1, pc=1
double deltaECmc(LabColor c1, LabColor c2, {double pl = 2, double pc = 1}) {
  final l1 = c1.l, a1 = c1.a, b1 = c1.b;

  final c1C = math.sqrt(a1 * a1 + b1 * b1);
  final c2C = math.sqrt(c2.a * c2.a + c2.b * c2.b);

  final dL = c1.l - c2.l;
  final dC = c1C - c2C;
  final da = c1.a - c2.a;
  final db = c1.b - c2.b;
  final dHSq = da * da + db * db - dC * dC;
  final dH = math.sqrt(math.max(0.0, dHSq));

  var h1 = math.atan2(b1, a1) * _rad2deg;
  if (h1 < 0) h1 += 360;

  final f = math.sqrt(math.pow(c1C, 4) / (math.pow(c1C, 4) + 1900.0));

  final t = (h1 >= 164 && h1 <= 345)
      ? 0.56 + (0.2 * math.cos(_deg2rad(h1 + 168))).abs()
      : 0.36 + (0.4 * math.cos(_deg2rad(h1 + 35))).abs();

  final sL = l1 < 16 ? 0.511 : (0.040975 * l1) / (1 + 0.01765 * l1);
  final sC = (0.0638 * c1C) / (1 + 0.0131 * c1C) + 0.638;
  final sH = sC * (f * t + 1 - f);

  final lTerm = dL / (pl * sL);
  final cTerm = dC / (pc * sC);
  final hTerm = dH / sH;

  return math.sqrt(lTerm * lTerm + cTerm * cTerm + hTerm * hTerm);
}

// ── Helpers ────────────────────────────────────────────────────────────────

const double _rad2deg = 180.0 / math.pi;

double _deg2rad(double deg) => deg * math.pi / 180.0;
