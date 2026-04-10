import 'dart:convert';
import 'dart:io';

import 'package:chromatic/chromatic.dart';
import 'package:test/test.dart';

void main() {
  final fixtures = json.decode(
    File('test/fixtures/adaptation.json').readAsStringSync(),
  ) as List;

  group('Chromatic adaptation vs Python colormath', () {
    test('${fixtures.length} transforms match exactly', () {
      for (final f in fixtures) {
        final xyz = f['xyz'] as List;
        final source = f['source'] as String;
        final target = f['target'] as String;
        final method = f['method'] as String;
        final expected = f['result'] as List;

        final (rx, ry, rz) = chromaticAdapt(
          (xyz[0] as num).toDouble(),
          (xyz[1] as num).toDouble(),
          (xyz[2] as num).toDouble(),
          sourceIlluminant: source,
          targetIlluminant: target,
          method: method,
        );

        expect(rx, closeTo((expected[0] as num).toDouble(), 1e-4),
            reason: '$source→$target ($method) X');
        expect(ry, closeTo((expected[1] as num).toDouble(), 1e-4),
            reason: '$source→$target ($method) Y');
        expect(rz, closeTo((expected[2] as num).toDouble(), 1e-4),
            reason: '$source→$target ($method) Z');
      }
    });

    test('round-trip: D65 → D50 → D65 returns original', () {
      final (ax, ay, az) = chromaticAdapt(
        0.5, 0.4, 0.1,
        sourceIlluminant: 'd65',
        targetIlluminant: 'd50',
      );
      final (bx, by, bz) = chromaticAdapt(
        ax, ay, az,
        sourceIlluminant: 'd50',
        targetIlluminant: 'd65',
      );
      expect(bx, closeTo(0.5, 1e-10));
      expect(by, closeTo(0.4, 1e-10));
      expect(bz, closeTo(0.1, 1e-10));
    });

    test('same illuminant is identity', () {
      final (rx, ry, rz) = chromaticAdapt(
        0.5, 0.4, 0.1,
        sourceIlluminant: 'd65',
        targetIlluminant: 'd65',
      );
      expect(rx, equals(0.5));
      expect(ry, equals(0.4));
      expect(rz, equals(0.1));
    });
  });
}
