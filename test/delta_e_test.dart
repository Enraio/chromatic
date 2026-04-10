import 'dart:convert';
import 'dart:io';

import 'package:chromatic/chromatic.dart';
import 'package:test/test.dart';

const _tolerance = 1e-4;

void main() {
  group('Delta E vs Python colormath', () {
    final fixtures = json.decode(
      File('test/fixtures/delta_e.json').readAsStringSync(),
    ) as List;

    test('91 pairs validated against colormath', () {
      for (final f in fixtures) {
        final lab1 = _readLab(f['lab1'] as List);
        final lab2 = _readLab(f['lab2'] as List);

        expect(deltaE76(lab1, lab2),
            closeTo((f['de76'] as num).toDouble(), _tolerance),
            reason: 'CIE76 failed for $lab1 vs $lab2');

        expect(deltaE94(lab1, lab2),
            closeTo((f['de94'] as num).toDouble(), _tolerance),
            reason: 'CIE94 failed for $lab1 vs $lab2');

        expect(
            deltaE94(lab1, lab2, kL: 2, k1: 0.048, k2: 0.014),
            closeTo((f['de94_textiles'] as num).toDouble(), _tolerance),
            reason: 'CIE94 textiles failed for $lab1 vs $lab2');

        expect(deltaE00(lab1, lab2),
            closeTo((f['de2000'] as num).toDouble(), _tolerance),
            reason: 'CIEDE2000 failed for $lab1 vs $lab2');

        expect(deltaECmc(lab1, lab2, pl: 2, pc: 1),
            closeTo((f['cmc_21'] as num).toDouble(), _tolerance),
            reason: 'CMC 2:1 failed for $lab1 vs $lab2');

        expect(deltaECmc(lab1, lab2, pl: 1, pc: 1),
            closeTo((f['cmc_11'] as num).toDouble(), _tolerance),
            reason: 'CMC 1:1 failed for $lab1 vs $lab2');
      }
    });
  });

  group('Sharma 2005 CIEDE2000 reference dataset', () {
    final fixtures = json.decode(
      File('test/fixtures/sharma2005.json').readAsStringSync(),
    ) as List;

    test('34 reference pairs match published values (±0.0001)', () {
      var maxError = 0.0;
      for (final f in fixtures) {
        final lab1 = _readLab(f['lab1'] as List);
        final lab2 = _readLab(f['lab2'] as List);
        final expected = (f['expected_de2000'] as num).toDouble();

        final actual = deltaE00(lab1, lab2);
        final err = (actual - expected).abs();
        if (err > maxError) maxError = err;

        expect(actual, closeTo(expected, 1e-4),
            reason: 'Sharma pair $lab1 vs $lab2 expected $expected got $actual');
      }
      print('  → Max error against Sharma 2005 published values: $maxError');
    });
  });

  group('Delta E properties', () {
    test('self-distance is zero', () {
      final c = LabColor(50, 30, -20);
      expect(deltaE76(c, c), closeTo(0, 1e-10));
      expect(deltaE94(c, c), closeTo(0, 1e-10));
      expect(deltaE00(c, c), closeTo(0, 1e-10));
      expect(deltaECmc(c, c), closeTo(0, 1e-10));
    });

    test('CIE76 is symmetric', () {
      final a = LabColor(50, 30, -20);
      final b = LabColor(70, -10, 40);
      expect(deltaE76(a, b), closeTo(deltaE76(b, a), 1e-10));
    });

    test('CIEDE2000 is symmetric', () {
      final a = LabColor(50, 30, -20);
      final b = LabColor(70, -10, 40);
      expect(deltaE00(a, b), closeTo(deltaE00(b, a), 1e-10));
    });

    test('distance is non-negative', () {
      final a = LabColor(50, 30, -20);
      final b = LabColor(70, -10, 40);
      expect(deltaE76(a, b), greaterThanOrEqualTo(0));
      expect(deltaE00(a, b), greaterThanOrEqualTo(0));
    });

    test('CIEDE2000 domain edge case (Lab(50,0,0) vs Lab(50,-1,2))', () {
      final a = LabColor(50, 0, 0);
      final b = LabColor(50, -1, 2);
      // Should not throw (historical numerical domain error).
      expect(() => deltaE00(a, b), returnsNormally);
    });
  });
}

LabColor _readLab(List raw) =>
    LabColor((raw[0] as num).toDouble(), (raw[1] as num).toDouble(),
        (raw[2] as num).toDouble());
