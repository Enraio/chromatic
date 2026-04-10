/// Color space conversion functions.
///
/// All conversions ported from Python colormath with identical math.
/// Conversion paths follow: RGB ↔ XYZ ↔ Lab ↔ LCH, etc.
library;

import 'dart:math' as math;

import 'colors.dart';
import 'constants.dart';
import 'chromatic_adaptation.dart';

// ── XYZ ↔ Lab ──────────────────────────────────────────────────────────────

/// Converts [XyzColor] to [LabColor].
LabColor xyzToLab(XyzColor xyz) {
  final wp = xyz.whitePoint;

  // colormath uses the 1994 CIE constant 7.787 (≈ cieK/116 but not exact).
  double f(double t) {
    if (t > cieE) return math.pow(t, 1.0 / 3.0).toDouble();
    return 7.787 * t + 16.0 / 116.0;
  }

  final fx = f(xyz.x / wp[0]);
  final fy = f(xyz.y / wp[1]);
  final fz = f(xyz.z / wp[2]);

  final l = 116.0 * fy - 16.0;
  final a = 500.0 * (fx - fy);
  final b = 200.0 * (fy - fz);

  return LabColor(l, a, b, observer: xyz.observer, illuminant: xyz.illuminant);
}

/// Converts [LabColor] to [XyzColor].
XyzColor labToXyz(LabColor lab) {
  final wp = illuminants[lab.observer]?[lab.illuminant];
  if (wp == null) {
    throw ArgumentError(
      'Unknown illuminant: ${lab.observer}/${lab.illuminant}',
    );
  }

  var fy = (lab.l + 16.0) / 116.0;
  var fx = lab.a / 500.0 + fy;
  var fz = fy - lab.b / 200.0;

  // colormath checks pow(t, 3) > CIE_E, not t > cbrt(CIE_E).
  final fy3 = fy * fy * fy;
  fy = fy3 > cieE ? fy3 : (fy - 16.0 / 116.0) / 7.787;

  final fx3 = fx * fx * fx;
  fx = fx3 > cieE ? fx3 : (fx - 16.0 / 116.0) / 7.787;

  final fz3 = fz * fz * fz;
  fz = fz3 > cieE ? fz3 : (fz - 16.0 / 116.0) / 7.787;

  return XyzColor(
    fx * wp[0],
    fy * wp[1],
    fz * wp[2],
    observer: lab.observer,
    illuminant: lab.illuminant,
  );
}

// ── Lab ↔ LCHab ────────────────────────────────────────────────────────────

/// Converts [LabColor] to [LchAbColor].
LchAbColor labToLchAb(LabColor lab) {
  final c = math.sqrt(lab.a * lab.a + lab.b * lab.b);
  final hRad = math.atan2(lab.b, lab.a);
  // Match colormath convention: h in (0, 360], not [0, 360).
  final h = hRad > 0
      ? hRad * (180.0 / math.pi)
      : 360.0 - hRad.abs() * (180.0 / math.pi);
  return LchAbColor(
    lab.l,
    c,
    h,
    observer: lab.observer,
    illuminant: lab.illuminant,
  );
}

/// Converts [LchAbColor] to [LabColor].
LabColor lchAbToLab(LchAbColor lch) {
  final hRad = lch.h * (math.pi / 180.0);
  final a = lch.c * math.cos(hRad);
  final b = lch.c * math.sin(hRad);
  return LabColor(
    lch.l,
    a,
    b,
    observer: lch.observer,
    illuminant: lch.illuminant,
  );
}

// ── XYZ ↔ Luv ──────────────────────────────────────────────────────────────

/// Converts [XyzColor] to [LuvColor].
///
/// Matches colormath's XYZ_to_Luv behavior exactly.
LuvColor xyzToLuv(XyzColor xyz) {
  final wp = xyz.whitePoint;

  // u'/v' from XYZ (colormath zeros them if denom == 0).
  final denom = xyz.x + 15.0 * xyz.y + 3.0 * xyz.z;
  final uP = denom == 0 ? 0.0 : (4.0 * xyz.x) / denom;
  final vP = denom == 0 ? 0.0 : (9.0 * xyz.y) / denom;

  var ty = xyz.y / wp[1];
  // colormath uses 7.787 * t + 16/116 for small values (not exact cieK/116).
  ty = ty > cieE
      ? math.pow(ty, 1.0 / 3.0).toDouble()
      : 7.787 * ty + 16.0 / 116.0;

  final refU = (4.0 * wp[0]) / (wp[0] + 15.0 * wp[1] + 3.0 * wp[2]);
  final refV = (9.0 * wp[1]) / (wp[0] + 15.0 * wp[1] + 3.0 * wp[2]);

  final l = 116.0 * ty - 16.0;
  final u = 13.0 * l * (uP - refU);
  final v = 13.0 * l * (vP - refV);

  return LuvColor(l, u, v, observer: xyz.observer, illuminant: xyz.illuminant);
}

/// Converts [LuvColor] to [XyzColor].
XyzColor luvToXyz(LuvColor luv) {
  final wp = illuminants[luv.observer]?[luv.illuminant];
  if (wp == null) {
    throw ArgumentError(
      'Unknown illuminant: ${luv.observer}/${luv.illuminant}',
    );
  }

  // colormath short-circuits at L <= 0.
  if (luv.l <= 0) {
    return XyzColor(
      0,
      0,
      0,
      observer: luv.observer,
      illuminant: luv.illuminant,
    );
  }

  final uRef = (4.0 * wp[0]) / (wp[0] + 15.0 * wp[1] + 3.0 * wp[2]);
  final vRef = (9.0 * wp[1]) / (wp[0] + 15.0 * wp[1] + 3.0 * wp[2]);

  final u0 = luv.u / (13.0 * luv.l) + uRef;
  final v0 = luv.v / (13.0 * luv.l) + vRef;

  final y = luv.l > cieK * cieE
      ? math.pow((luv.l + 16.0) / 116.0, 3).toDouble()
      : luv.l / cieK;

  final x = y * 9.0 * u0 / (4.0 * v0);
  final z = y * (12.0 - 3.0 * u0 - 20.0 * v0) / (4.0 * v0);

  return XyzColor(x, y, z, observer: luv.observer, illuminant: luv.illuminant);
}

// ── Luv ↔ LCHuv ────────────────────────────────────────────────────────────

/// Converts [LuvColor] to [LchUvColor].
LchUvColor luvToLchUv(LuvColor luv) {
  final c = math.sqrt(luv.u * luv.u + luv.v * luv.v);
  final hRad = math.atan2(luv.v, luv.u);
  final h = hRad > 0
      ? hRad * (180.0 / math.pi)
      : 360.0 - hRad.abs() * (180.0 / math.pi);
  return LchUvColor(
    luv.l,
    c,
    h,
    observer: luv.observer,
    illuminant: luv.illuminant,
  );
}

/// Converts [LchUvColor] to [LuvColor].
LuvColor lchUvToLuv(LchUvColor lch) {
  final hRad = lch.h * (math.pi / 180.0);
  final u = lch.c * math.cos(hRad);
  final v = lch.c * math.sin(hRad);
  return LuvColor(
    lch.l,
    u,
    v,
    observer: lch.observer,
    illuminant: lch.illuminant,
  );
}

// ── XYZ ↔ xyY ──────────────────────────────────────────────────────────────

/// Converts [XyzColor] to [XyyColor].
XyyColor xyzToXyy(XyzColor xyz) {
  final denom = xyz.x + xyz.y + xyz.z;
  if (denom == 0) {
    return XyyColor(
      0.0,
      0.0,
      0.0,
      observer: xyz.observer,
      illuminant: xyz.illuminant,
    );
  }
  return XyyColor(
    xyz.x / denom,
    xyz.y / denom,
    xyz.y,
    observer: xyz.observer,
    illuminant: xyz.illuminant,
  );
}

/// Converts [XyyColor] to [XyzColor].
XyzColor xyyToXyz(XyyColor xyy) {
  if (xyy.y == 0) {
    return XyzColor(
      0,
      0,
      0,
      observer: xyy.observer,
      illuminant: xyy.illuminant,
    );
  }
  final x = xyy.x * xyy.bigY / xyy.y;
  final z = (1.0 - xyy.x - xyy.y) * xyy.bigY / xyy.y;
  return XyzColor(
    x,
    xyy.bigY,
    z,
    observer: xyy.observer,
    illuminant: xyy.illuminant,
  );
}

// ── XYZ ↔ IPT ──────────────────────────────────────────────────────────────

// IPT conversion matrices (Hunt-Pointer-Estevez adapted for D65).
const _xyzToLms = [
  0.4002, 0.7076, -0.0808, //
  -0.2263, 1.1653, 0.0457,
  0.0000, 0.0000, 0.9182,
];

const _lmsToIpt = [
  0.4000, 0.4000, 0.2000, //
  4.4550, -4.8510, 0.3960,
  0.8056, 0.3572, -1.1628,
];

const _iptToLms = [
  1.0000, 0.0976, 0.2052, //
  1.0000, -0.1139, 0.1332,
  1.0000, 0.0326, -0.6769,
];

const _lmsToXyz = [
  1.8502, -1.1383, 0.2384, //
  0.3668, 0.6439, -0.0107,
  0.0000, 0.0000, 1.0889,
];

/// Converts [XyzColor] to [IptColor]. Requires D65 illuminant.
IptColor xyzToIpt(XyzColor xyz) {
  // Adapt to D65 if needed.
  final adapted = xyz.illuminant == 'd65'
      ? xyz
      : adaptXyzColor(xyz, targetIlluminant: 'd65');

  final (l, m, s) = _mul3(_xyzToLms, adapted.x, adapted.y, adapted.z);

  // Non-linear compression.
  double compress(double v) {
    if (v >= 0) return math.pow(v, 0.43).toDouble();
    return -math.pow(-v, 0.43).toDouble();
  }

  final lp = compress(l);
  final mp = compress(m);
  final sp = compress(s);

  final (i, p, t) = _mul3(_lmsToIpt, lp, mp, sp);
  return IptColor(i, p, t);
}

/// Converts [IptColor] to [XyzColor].
XyzColor iptToXyz(IptColor ipt) {
  final (lp, mp, sp) = _mul3(_iptToLms, ipt.i, ipt.p, ipt.t);

  double decompress(double v) {
    if (v >= 0) return math.pow(v, 1.0 / 0.43).toDouble();
    return -math.pow(-v, 1.0 / 0.43).toDouble();
  }

  final l = decompress(lp);
  final m = decompress(mp);
  final s = decompress(sp);

  final (x, y, z) = _mul3(_lmsToXyz, l, m, s);
  return XyzColor(x, y, z, illuminant: 'd65');
}

// ── RGB ↔ XYZ ──────────────────────────────────────────────────────────────

/// Converts an [BaseRgbColor] to [XyzColor].
///
/// Applies inverse gamma (linearization), then the RGB→XYZ matrix.
/// By default, the resulting XYZ is in the RGB's native illuminant
/// (e.g., D65 for sRGB). Pass [targetIlluminant] to force adaptation.
XyzColor rgbToXyz(
  BaseRgbColor rgb, {
  String? targetIlluminant,
  String observer = '2',
}) {
  final def = rgb.spaceDef;

  // Linearize using the RGB space's transfer function.
  final lr = rgb.linearize(rgb.r);
  final lg = rgb.linearize(rgb.g);
  final lb = rgb.linearize(rgb.b);

  // Apply RGB→XYZ matrix.
  final (x, y, z) = _mul3(def.rgbToXyz, lr, lg, lb);

  // If no target specified, stay in native illuminant.
  final effective = targetIlluminant ?? def.nativeIlluminant;

  if (def.nativeIlluminant != effective) {
    final (ax, ay, az) = chromaticAdapt(
      x,
      y,
      z,
      sourceIlluminant: def.nativeIlluminant,
      targetIlluminant: effective,
      observer: observer,
    );
    return XyzColor(ax, ay, az, observer: observer, illuminant: effective);
  }

  return XyzColor(
    x,
    y,
    z,
    observer: observer,
    illuminant: def.nativeIlluminant,
  );
}

/// Converts [XyzColor] to [SRgbColor].
SRgbColor xyzToSRgb(XyzColor xyz) => _xyzToRgb<SRgbColor>(
  xyz,
  sRgbDef,
  (r, g, b) => SRgbColor(r, g, b),
  _srgbPrototype,
);

/// Converts [XyzColor] to [AdobeRgbColor].
AdobeRgbColor xyzToAdobeRgb(XyzColor xyz) => _xyzToRgb<AdobeRgbColor>(
  xyz,
  adobeRgbDef,
  (r, g, b) => AdobeRgbColor(r, g, b),
  _adobeRgbPrototype,
);

/// Converts [XyzColor] to [AppleRgbColor].
AppleRgbColor xyzToAppleRgb(XyzColor xyz) => _xyzToRgb<AppleRgbColor>(
  xyz,
  appleRgbDef,
  (r, g, b) => AppleRgbColor(r, g, b),
  _appleRgbPrototype,
);

/// Converts [XyzColor] to [Bt2020Color].
Bt2020Color xyzToBt2020(XyzColor xyz) => _xyzToRgb<Bt2020Color>(
  xyz,
  bt2020Def,
  (r, g, b) => Bt2020Color(r, g, b),
  _bt2020Prototype,
);

// Prototype instances used only to look up the per-space transfer function.
final _srgbPrototype = SRgbColor(0, 0, 0);
final _adobeRgbPrototype = AdobeRgbColor(0, 0, 0);
final _appleRgbPrototype = AppleRgbColor(0, 0, 0);
final _bt2020Prototype = Bt2020Color(0, 0, 0);

T _xyzToRgb<T extends BaseRgbColor>(
  XyzColor xyz,
  RgbColorSpaceDef def,
  T Function(double, double, double) ctor,
  BaseRgbColor prototype,
) {
  // Adapt to RGB native illuminant if needed.
  final adapted = xyz.illuminant == def.nativeIlluminant
      ? xyz
      : adaptXyzColor(xyz, targetIlluminant: def.nativeIlluminant);

  // Apply XYZ→linear RGB matrix.
  final (lr, lg, lb) = _mul3(def.xyzToRgb, adapted.x, adapted.y, adapted.z);

  // Apply the space-specific inverse transfer function.
  return ctor(
    prototype.encodeGamma(lr),
    prototype.encodeGamma(lg),
    prototype.encodeGamma(lb),
  );
}

// ── RGB ↔ HSV ──────────────────────────────────────────────────────────────

/// Converts [SRgbColor] to [HsvColor].
HsvColor rgbToHsv(BaseRgbColor rgb) {
  final r = rgb.clampedR;
  final g = rgb.clampedG;
  final b = rgb.clampedB;

  final cMax = math.max(r, math.max(g, b));
  final cMin = math.min(r, math.min(g, b));
  final delta = cMax - cMin;

  // Hue.
  double h;
  if (delta == 0) {
    h = 0;
  } else if (cMax == r) {
    h = 60.0 * (((g - b) / delta) % 6);
  } else if (cMax == g) {
    h = 60.0 * (((b - r) / delta) + 2);
  } else {
    h = 60.0 * (((r - g) / delta) + 4);
  }
  if (h < 0) h += 360.0;

  // Saturation.
  final s = cMax == 0 ? 0.0 : delta / cMax;

  return HsvColor(h, s, cMax);
}

/// Converts [HsvColor] to [SRgbColor].
SRgbColor hsvToRgb(HsvColor hsv) {
  final h = hsv.h;
  final s = hsv.s;
  final v = hsv.v;

  final c = v * s;
  final x = c * (1 - ((h / 60) % 2 - 1).abs());
  final m = v - c;

  double r, g, b;
  if (h < 60) {
    (r, g, b) = (c, x, 0.0);
  } else if (h < 120) {
    (r, g, b) = (x, c, 0.0);
  } else if (h < 180) {
    (r, g, b) = (0.0, c, x);
  } else if (h < 240) {
    (r, g, b) = (0.0, x, c);
  } else if (h < 300) {
    (r, g, b) = (x, 0.0, c);
  } else {
    (r, g, b) = (c, 0.0, x);
  }

  return SRgbColor(r + m, g + m, b + m);
}

// ── RGB ↔ HSL ──────────────────────────────────────────────────────────────

/// Converts [SRgbColor] to [HslColor].
HslColor rgbToHsl(BaseRgbColor rgb) {
  final r = rgb.clampedR;
  final g = rgb.clampedG;
  final b = rgb.clampedB;

  final cMax = math.max(r, math.max(g, b));
  final cMin = math.min(r, math.min(g, b));
  final delta = cMax - cMin;
  final l = (cMax + cMin) / 2;

  if (delta == 0) return HslColor(0, 0, l);

  final s = l > 0.5 ? delta / (2.0 - cMax - cMin) : delta / (cMax + cMin);

  double h;
  if (cMax == r) {
    h = 60.0 * (((g - b) / delta) % 6);
  } else if (cMax == g) {
    h = 60.0 * (((b - r) / delta) + 2);
  } else {
    h = 60.0 * (((r - g) / delta) + 4);
  }
  if (h < 0) h += 360.0;

  return HslColor(h, s, l);
}

/// Converts [HslColor] to [SRgbColor].
SRgbColor hslToRgb(HslColor hsl) {
  if (hsl.s == 0) return SRgbColor(hsl.l, hsl.l, hsl.l);

  final c = (1 - (2 * hsl.l - 1).abs()) * hsl.s;
  final x = c * (1 - ((hsl.h / 60) % 2 - 1).abs());
  final m = hsl.l - c / 2;

  double r, g, b;
  final h = hsl.h;
  if (h < 60) {
    (r, g, b) = (c, x, 0.0);
  } else if (h < 120) {
    (r, g, b) = (x, c, 0.0);
  } else if (h < 180) {
    (r, g, b) = (0.0, c, x);
  } else if (h < 240) {
    (r, g, b) = (0.0, x, c);
  } else if (h < 300) {
    (r, g, b) = (x, 0.0, c);
  } else {
    (r, g, b) = (c, 0.0, x);
  }

  return SRgbColor(r + m, g + m, b + m);
}

// ── RGB ↔ CMY ↔ CMYK ──────────────────────────────────────────────────────

/// Converts [BaseRgbColor] to [CmyColor].
CmyColor rgbToCmy(BaseRgbColor rgb) =>
    CmyColor(1.0 - rgb.r, 1.0 - rgb.g, 1.0 - rgb.b);

/// Converts [CmyColor] to [SRgbColor].
SRgbColor cmyToRgb(CmyColor cmy) =>
    SRgbColor(1.0 - cmy.c, 1.0 - cmy.m, 1.0 - cmy.y);

/// Converts [CmyColor] to [CmykColor].
CmykColor cmyToCmyk(CmyColor cmy) {
  final k = math.min(cmy.c, math.min(cmy.m, cmy.y));
  if (k >= 1.0) return const CmykColor(0, 0, 0, 1);
  final invK = 1.0 - k;
  return CmykColor(
    (cmy.c - k) / invK,
    (cmy.m - k) / invK,
    (cmy.y - k) / invK,
    k,
  );
}

/// Converts [CmykColor] to [CmyColor].
CmyColor cmykToCmy(CmykColor cmyk) {
  return CmyColor(
    cmyk.c * (1.0 - cmyk.k) + cmyk.k,
    cmyk.m * (1.0 - cmyk.k) + cmyk.k,
    cmyk.y * (1.0 - cmyk.k) + cmyk.k,
  );
}

// ── Convenience conversions ────────────────────────────────────────────────

/// Converts [SRgbColor] directly to [LabColor].
///
/// By default, Lab is computed in sRGB's native illuminant (D65),
/// matching Python colormath's behavior.
LabColor sRgbToLab(
  SRgbColor rgb, {
  String? illuminant,
  String observer = '2',
}) => xyzToLab(rgbToXyz(rgb, targetIlluminant: illuminant, observer: observer));

/// Converts [LabColor] directly to [SRgbColor].
SRgbColor labToSRgb(LabColor lab) => xyzToSRgb(labToXyz(lab));

/// Converts [SRgbColor] directly to [LchAbColor].
LchAbColor sRgbToLchAb(
  SRgbColor rgb, {
  String? illuminant,
  String observer = '2',
}) => labToLchAb(sRgbToLab(rgb, illuminant: illuminant, observer: observer));

/// Converts [LchAbColor] directly to [SRgbColor].
SRgbColor lchAbToSRgb(LchAbColor lch) => labToSRgb(lchAbToLab(lch));

/// Converts [SRgbColor] directly to [HsvColor].
HsvColor sRgbToHsv(SRgbColor rgb) => rgbToHsv(rgb);

/// Converts [SRgbColor] directly to [HslColor].
HslColor sRgbToHsl(SRgbColor rgb) => rgbToHsl(rgb);

// ── Internal helper ────────────────────────────────────────────────────────

(double, double, double) _mul3(List<double> m, double a, double b, double c) {
  return (
    m[0] * a + m[1] * b + m[2] * c,
    m[3] * a + m[4] * b + m[5] * c,
    m[6] * a + m[7] * b + m[8] * c,
  );
}
