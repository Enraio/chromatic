import 'dart:convert';
import 'dart:io';

import 'package:chromatic/chromatic.dart';
import 'package:test/test.dart';

const _tolerance = 1e-6;

void main() {
  final fixtures =
      json.decode(File('test/fixtures/conversions.json').readAsStringSync())
          as List;

  group('Color conversions vs Python colormath', () {
    test('sRGB → Lab (${fixtures.length} fixtures)', () {
      for (final f in fixtures) {
        final rgb = _readRgb(f['rgb'] as List);
        final expected = f['lab'] as List;

        final lab = sRgbToLab(rgb);
        _expectVec3(lab.values, expected, 'sRGB→Lab $rgb');
      }
    });

    test('sRGB → XYZ (${fixtures.length} fixtures)', () {
      for (final f in fixtures) {
        final rgb = _readRgb(f['rgb'] as List);
        final expected = f['xyz'] as List;

        final xyz = rgbToXyz(rgb);
        _expectVec3(xyz.values, expected, 'sRGB→XYZ $rgb');
      }
    });

    test('sRGB → HSL (${fixtures.length} fixtures)', () {
      for (final f in fixtures) {
        final rgb = _readRgb(f['rgb'] as List);
        final expected = f['hsl'] as List;

        final hsl = rgbToHsl(rgb);
        _expectVec3(hsl.values, expected, 'sRGB→HSL $rgb');
      }
    });

    test('sRGB → HSV (${fixtures.length} fixtures)', () {
      for (final f in fixtures) {
        final rgb = _readRgb(f['rgb'] as List);
        final expected = f['hsv'] as List;

        final hsv = rgbToHsv(rgb);
        _expectVec3(hsv.values, expected, 'sRGB→HSV $rgb');
      }
    });

    test('sRGB → LCHab (${fixtures.length} fixtures)', () {
      for (final f in fixtures) {
        final rgb = _readRgb(f['rgb'] as List);
        final expected = f['lch'] as List;

        final lch = sRgbToLchAb(rgb);
        _expectVec3(lch.values, expected, 'sRGB→LCH $rgb');
      }
    });

    test('sRGB → Luv (${fixtures.length} fixtures)', () {
      for (final f in fixtures) {
        final rgb = _readRgb(f['rgb'] as List);
        final expected = f['luv'] as List;

        final xyz = rgbToXyz(rgb);
        final luv = xyzToLuv(xyz);
        _expectVec3(luv.values, expected, 'sRGB→Luv $rgb');
      }
    });

    test('sRGB → LCHuv (${fixtures.length} fixtures)', () {
      for (final f in fixtures) {
        final rgb = _readRgb(f['rgb'] as List);
        final expected = f['lchuv'] as List;

        final xyz = rgbToXyz(rgb);
        final luv = xyzToLuv(xyz);
        final lchuv = luvToLchUv(luv);
        _expectVec3(lchuv.values, expected, 'sRGB→LCHuv $rgb');
      }
    });

    test('sRGB → xyY (${fixtures.length} fixtures)', () {
      for (final f in fixtures) {
        final rgb = _readRgb(f['rgb'] as List);
        final expected = f['xyy'] as List;

        final xyz = rgbToXyz(rgb);
        final xyy = xyzToXyy(xyz);
        _expectVec3(xyy.values, expected, 'sRGB→xyY $rgb');
      }
    });

    test('sRGB → CMY (${fixtures.length} fixtures)', () {
      for (final f in fixtures) {
        final rgb = _readRgb(f['rgb'] as List);
        final expected = f['cmy'] as List;

        final cmy = rgbToCmy(rgb);
        _expectVec3(cmy.values, expected, 'sRGB→CMY $rgb');
      }
    });

    test('sRGB → CMYK (${fixtures.length} fixtures)', () {
      for (final f in fixtures) {
        final rgb = _readRgb(f['rgb'] as List);
        final expected = f['cmyk'] as List;

        final cmyk = cmyToCmyk(rgbToCmy(rgb));
        expect(cmyk.c, closeTo((expected[0] as num).toDouble(), _tolerance));
        expect(cmyk.m, closeTo((expected[1] as num).toDouble(), _tolerance));
        expect(cmyk.y, closeTo((expected[2] as num).toDouble(), _tolerance));
        expect(cmyk.k, closeTo((expected[3] as num).toDouble(), _tolerance));
      }
    });
  });

  group('Hex parsing', () {
    test('6-digit hex with hash', () {
      final c = SRgbColor.fromHex('#ff8040');
      expect(c.hex, equals('#ff8040'));
    });

    test('6-digit hex without hash', () {
      final c = SRgbColor.fromHex('ff8040');
      expect(c.hex, equals('#ff8040'));
    });

    test('3-digit shorthand', () {
      final c = SRgbColor.fromHex('#f84');
      expect(c.hex, equals('#ff8844'));
    });

    test('invalid hex throws', () {
      expect(() => SRgbColor.fromHex('invalid'), throwsFormatException);
    });
  });
}

SRgbColor _readRgb(List raw) => SRgbColor(
  (raw[0] as num).toDouble(),
  (raw[1] as num).toDouble(),
  (raw[2] as num).toDouble(),
);

void _expectVec3(List<double> actual, List expected, String reason) {
  expect(
    actual[0],
    closeTo((expected[0] as num).toDouble(), _tolerance),
    reason: '$reason [0]',
  );
  expect(
    actual[1],
    closeTo((expected[1] as num).toDouble(), _tolerance),
    reason: '$reason [1]',
  );
  expect(
    actual[2],
    closeTo((expected[2] as num).toDouble(), _tolerance),
    reason: '$reason [2]',
  );
}
