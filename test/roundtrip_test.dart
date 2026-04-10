import 'dart:convert';
import 'dart:io';

import 'package:chromatic/chromatic.dart';
import 'package:test/test.dart';

void main() {
  group('Round-trip conversions', () {
    test('sRGB → Lab → sRGB (vs Python colormath)', () {
      final fixtures = json.decode(
        File('test/fixtures/roundtrip.json').readAsStringSync(),
      ) as List;

      for (final f in fixtures) {
        final original = f['original'] as List;
        final expectedLab = f['lab'] as List;
        final expectedBack = f['roundtrip'] as List;

        final rgb = SRgbColor(
          (original[0] as num).toDouble(),
          (original[1] as num).toDouble(),
          (original[2] as num).toDouble(),
        );

        final lab = sRgbToLab(rgb);
        expect(lab.l, closeTo((expectedLab[0] as num).toDouble(), 1e-3));
        expect(lab.a, closeTo((expectedLab[1] as num).toDouble(), 1e-3));
        expect(lab.b, closeTo((expectedLab[2] as num).toDouble(), 1e-3));

        final back = labToSRgb(lab);
        expect(back.r, closeTo((expectedBack[0] as num).toDouble(), 1e-3));
        expect(back.g, closeTo((expectedBack[1] as num).toDouble(), 1e-3));
        expect(back.b, closeTo((expectedBack[2] as num).toDouble(), 1e-3));
      }
    });

    test('Lab ↔ LCH round-trip', () {
      final lab = LabColor(50, 30, -20);
      final lch = labToLchAb(lab);
      final back = lchAbToLab(lch);
      expect(back.l, closeTo(lab.l, 1e-10));
      expect(back.a, closeTo(lab.a, 1e-10));
      expect(back.b, closeTo(lab.b, 1e-10));
    });

    test('Luv ↔ LCHuv round-trip', () {
      final luv = LuvColor(50, 30, -20);
      final lch = luvToLchUv(luv);
      final back = lchUvToLuv(lch);
      expect(back.l, closeTo(luv.l, 1e-10));
      expect(back.u, closeTo(luv.u, 1e-10));
      expect(back.v, closeTo(luv.v, 1e-10));
    });

    test('XYZ ↔ xyY round-trip', () {
      final xyz = XyzColor(0.5, 0.4, 0.1);
      final xyy = xyzToXyy(xyz);
      final back = xyyToXyz(xyy);
      expect(back.x, closeTo(xyz.x, 1e-10));
      expect(back.y, closeTo(xyz.y, 1e-10));
      expect(back.z, closeTo(xyz.z, 1e-10));
    });

    test('CMY ↔ CMYK round-trip', () {
      final cmy = CmyColor(0.8, 0.2, 0.5);
      final cmyk = cmyToCmyk(cmy);
      final back = cmykToCmy(cmyk);
      expect(back.c, closeTo(cmy.c, 1e-10));
      expect(back.m, closeTo(cmy.m, 1e-10));
      expect(back.y, closeTo(cmy.y, 1e-10));
    });

    test('HSL → RGB → HSL round-trip', () {
      final hsl = HslColor(240, 0.75, 0.5);
      final rgb = hslToRgb(hsl);
      final back = rgbToHsl(rgb);
      expect(back.h, closeTo(hsl.h, 1e-3));
      expect(back.s, closeTo(hsl.s, 1e-3));
      expect(back.l, closeTo(hsl.l, 1e-3));
    });
  });
}
