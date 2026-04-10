/// Performance benchmarks for the chromatic package.
///
/// Run: `dart run benchmark/benchmark.dart`
///
/// Compare against Python colormath: `python3.11 benchmark/benchmark.py`
library;

import 'dart:math';

import 'package:chromatic/chromatic.dart';

const _iterations = 100000;

void main() {
  print('chromatic benchmarks — $_iterations iterations each\n');
  print(
    '${'operation'.padRight(40)}${'time (ms)'.padLeft(12)}${'ops/sec'.padLeft(16)}',
  );
  print('─' * 68);

  final rng = Random(42);

  // ── sRGB → Lab ──
  _bench('sRGB → Lab', () {
    final rgb = SRgbColor(rng.nextDouble(), rng.nextDouble(), rng.nextDouble());
    sRgbToLab(rgb);
  });

  // ── sRGB → XYZ ──
  _bench('sRGB → XYZ', () {
    final rgb = SRgbColor(rng.nextDouble(), rng.nextDouble(), rng.nextDouble());
    rgbToXyz(rgb);
  });

  // ── sRGB → HSL ──
  _bench('sRGB → HSL', () {
    final rgb = SRgbColor(rng.nextDouble(), rng.nextDouble(), rng.nextDouble());
    rgbToHsl(rgb);
  });

  // ── sRGB → HSV ──
  _bench('sRGB → HSV', () {
    final rgb = SRgbColor(rng.nextDouble(), rng.nextDouble(), rng.nextDouble());
    rgbToHsv(rgb);
  });

  // ── sRGB → LCH ──
  _bench('sRGB → LCH', () {
    final rgb = SRgbColor(rng.nextDouble(), rng.nextDouble(), rng.nextDouble());
    sRgbToLchAb(rgb);
  });

  // ── sRGB → Luv ──
  _bench('sRGB → Luv', () {
    final rgb = SRgbColor(rng.nextDouble(), rng.nextDouble(), rng.nextDouble());
    xyzToLuv(rgbToXyz(rgb));
  });

  // ── Lab → sRGB (round-trip) ──
  _bench('Lab → sRGB', () {
    final lab = LabColor(
      rng.nextDouble() * 100,
      (rng.nextDouble() - 0.5) * 200,
      (rng.nextDouble() - 0.5) * 200,
    );
    labToSRgb(lab);
  });

  // ── Delta E 1976 ──
  final labA = LabColor(50, 30, -20);
  final labB = LabColor(70, -10, 40);
  _bench('Delta E 1976', () {
    deltaE76(labA, labB);
  });

  _bench('Delta E 1994', () {
    deltaE94(labA, labB);
  });

  _bench('Delta E CIEDE2000', () {
    deltaE00(labA, labB);
  });

  _bench('Delta E CMC', () {
    deltaECmc(labA, labB);
  });

  // ── Chromatic adaptation ──
  _bench('Bradford adaptation', () {
    chromaticAdapt(
      0.5,
      0.4,
      0.1,
      sourceIlluminant: 'c',
      targetIlluminant: 'd65',
    );
  });

  // ── Hex parse + convert ──
  _bench('hex → Lab', () {
    sRgbToLab(SRgbColor.fromHex('#ff8040'));
  });

  // ── Batch: convert 1000 colors to Lab ──
  final batch = List.generate(
    1000,
    (_) => SRgbColor(rng.nextDouble(), rng.nextDouble(), rng.nextDouble()),
  );

  final sw = Stopwatch()..start();
  for (var i = 0; i < 100; i++) {
    for (final rgb in batch) {
      sRgbToLab(rgb);
    }
  }
  sw.stop();
  final batchMs = sw.elapsedMicroseconds / 1000.0;
  print('\nBatch (100K colors, sRGB→Lab): ${batchMs.toStringAsFixed(2)} ms');
  print('  → ${(100000 / (batchMs / 1000)).toStringAsFixed(0)} colors/sec');
}

void _bench(String name, void Function() fn) {
  // Warmup.
  for (var i = 0; i < 1000; i++) {
    fn();
  }

  final sw = Stopwatch()..start();
  for (var i = 0; i < _iterations; i++) {
    fn();
  }
  sw.stop();

  final ms = sw.elapsedMicroseconds / 1000.0;
  final opsPerSec = (_iterations / (ms / 1000)).toStringAsFixed(0);
  print(
    '${name.padRight(40)}${ms.toStringAsFixed(2).padLeft(12)}'
    '${opsPerSec.padLeft(16)}',
  );
}
