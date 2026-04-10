import 'package:chromatic/chromatic.dart';

void main() {
  print('─── Hex parsing and conversions ───');
  final red = SRgbColor.fromHex('#ff0000');
  final lab = sRgbToLab(red);
  final lch = labToLchAb(lab);
  final hsl = sRgbToHsl(red);
  final hsv = sRgbToHsv(red);

  print('sRGB:  $red');
  print('hex:   ${red.hex}');
  print('Lab:   $lab');
  print('LCH:   $lch');
  print('HSL:   $hsl');
  print('HSV:   $hsv');

  print('\n─── Perceptual color distance ───');
  final a = sRgbToLab(SRgbColor.fromHex('#ff0000'));
  final b = sRgbToLab(SRgbColor.fromHex('#ff0500')); // tiny red shift
  final c = sRgbToLab(SRgbColor.fromHex('#00ff00')); // green

  print('red vs slightly-shifted red:');
  print('  CIE76:    ${deltaE76(a, b).toStringAsFixed(3)}');
  print('  CIEDE2000: ${deltaE00(a, b).toStringAsFixed(3)}');

  print('red vs green (clearly different):');
  print('  CIE76:    ${deltaE76(a, c).toStringAsFixed(3)}');
  print('  CIEDE2000: ${deltaE00(a, c).toStringAsFixed(3)}');

  print('\n─── Chromatic adaptation ───');
  // An XYZ value measured under illuminant C, converted to D65.
  final xyzC = XyzColor(0.5, 0.4, 0.1, illuminant: 'c');
  final xyzD65 = adaptXyzColor(xyzC, targetIlluminant: 'd65');
  print('XYZ under C:   $xyzC');
  print('XYZ under D65: $xyzD65');

  print('\n─── Delta E interpretation ───');
  final jnd = LabColor(50, 0, 0);
  final slightlyOff = LabColor(50.5, 0.3, -0.2);
  final obviously = LabColor(70, -20, 40);

  print('JND (Δ≈1):  ${deltaE00(jnd, slightlyOff).toStringAsFixed(3)}');
  print('Large diff: ${deltaE00(jnd, obviously).toStringAsFixed(3)}');

  print('\n─── Building a color palette with harmony ───');
  // Simple example: analogous palette (hue shifts in LCH).
  final base = sRgbToLchAb(SRgbColor.fromHex('#3498db'));
  print('Base:     $base');

  final variants = [-30.0, -15.0, 0.0, 15.0, 30.0];
  for (final dh in variants) {
    final shifted = LchAbColor(base.l, base.c, (base.h + dh) % 360);
    final rgb = lchAbToSRgb(shifted);
    print('  shift ${dh.toStringAsFixed(0).padLeft(4)}°: ${rgb.hex}');
  }
}
