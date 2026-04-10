# chromatic

[![pub package](https://img.shields.io/pub/v/chromatic.svg)](https://pub.dev/packages/chromatic)

A comprehensive **color science library for Dart**. Color space conversions,
perceptual color difference (Delta E), chromatic adaptation, and more.

Port of Python's [`colormath`](https://github.com/gtaylor/python-colormath)
with identical math, validated against 690+ Python-generated test fixtures
and the Sharma 2005 CIEDE2000 reference dataset.

## Features

- **10 color spaces**: sRGB, Adobe RGB, Apple RGB, BT.2020, XYZ, xyY, Lab,
  LCH(ab), Luv, LCH(uv), HSL, HSV, CMY, CMYK, IPT
- **4 Delta E formulas**: CIE76, CIE94 (graphic arts + textiles),
  CIEDE2000 (the gold standard), CMC l:c
- **Chromatic adaptation**: Bradford, von Kries, XYZ scaling — convert
  between any illuminant (D50, D65, A, C, F-series, etc.)
- **Proper sRGB EOTF**: piecewise transfer function (not simple power gamma)
- **Proper BT.2020 transfer**: ITU-R BT.2020 piecewise OETF
- **Hex parsing**: `#ff8040`, `ff8040`, `#f84` shorthand
- **All immutable**: every color type is a pure value class

## Validated against Python colormath

Every conversion and Delta E formula is tested against **690+ fixtures
generated from Python colormath**, plus the **34-pair Sharma 2005 reference
dataset** for CIEDE2000. Max error against Sharma's published values:
`4.9e-5`.

## Usage

```dart
import 'package:chromatic/chromatic.dart';

// Parse and convert
final red = SRgbColor.fromHex('#ff0000');
final lab = sRgbToLab(red);         // Lab(53.24, 80.09, 67.20)
final lch = labToLchAb(lab);        // LCH(53.24, 104.55, 39.99)
print(red.hex);                      // #ff0000

// Perceptual distance — use CIEDE2000
final blue = sRgbToLab(SRgbColor(0.0, 0.0, 1.0));
print(deltaE00(lab, blue));          // ~52.88 (clearly different)
print(deltaE00(lab, lab));           // 0.0

// Chromatic adaptation between illuminants
final xyzC = XyzColor(0.5, 0.4, 0.1, illuminant: 'c');
final xyzD65 = adaptXyzColor(xyzC, targetIlluminant: 'd65');

// Or directly
final (x, y, z) = chromaticAdapt(
  0.5, 0.4, 0.1,
  sourceIlluminant: 'c',
  targetIlluminant: 'd65',
  method: 'bradford',      // or 'von_kries', 'xyz_scaling'
);
```

## Performance vs Python colormath

Benchmarks on M-series Mac, 100K iterations each:

| Operation          | chromatic (Dart) | colormath (Python) | Speedup |
|--------------------|-----------------:|-------------------:|--------:|
| sRGB → Lab         |    4,072,988 ops/s |        87,224 ops/s |  **46.7×** |
| sRGB → XYZ         |    6,002,041 ops/s |       130,585 ops/s |  **46.0×** |
| sRGB → HSL         |    5,448,700 ops/s |       201,759 ops/s |  **27.0×** |
| sRGB → HSV         |    6,059,504 ops/s |       200,664 ops/s |  **30.2×** |
| sRGB → LCH         |    3,432,651 ops/s |        70,992 ops/s |  **48.4×** |
| sRGB → Luv         |    5,288,207 ops/s |        80,895 ops/s |  **65.4×** |
| Lab → sRGB         |    1,502,720 ops/s |        28,874 ops/s |  **52.0×** |
| Delta E 1976       |   99,304,866 ops/s |       272,325 ops/s | **364.7×** |
| Delta E 1994       |   27,173,913 ops/s |        43,891 ops/s | **619.1×** |
| **Delta E CIEDE2000** | **4,507,144 ops/s** | **10,700 ops/s** | **421.2×** |
| Delta E CMC        |   16,784,156 ops/s |        33,854 ops/s | **495.7×** |
| Bradford adaptation |  2,950,027 ops/s |        48,610 ops/s |  **60.7×** |
| Batch (100K colors → Lab) |    16.3 ms  |            1036.3 ms |  **63.6×** |

Reproduce:

```bash
dart run benchmark/benchmark.dart
python3.11 benchmark/benchmark.py
```

## Supported color spaces

| Space          | Forward                 | Inverse                 |
|----------------|-------------------------|-------------------------|
| sRGB           | `rgbToXyz`              | `xyzToSRgb`             |
| Adobe RGB      | `rgbToXyz`              | `xyzToAdobeRgb`         |
| Apple RGB      | `rgbToXyz`              | `xyzToAppleRgb`         |
| BT.2020        | `rgbToXyz`              | `xyzToBt2020`           |
| XYZ            | `xyzToLab`, `xyzToLuv`, `xyzToXyy`, `xyzToIpt` | ← |
| xyY            | `xyyToXyz`              | `xyzToXyy`              |
| Lab            | `labToLchAb`, `labToXyz` | ← |
| LCH(ab)        | `lchAbToLab`            | `labToLchAb`            |
| Luv            | `luvToLchUv`, `luvToXyz` | ← |
| LCH(uv)        | `lchUvToLuv`            | `luvToLchUv`            |
| HSL            | `rgbToHsl`              | `hslToRgb`              |
| HSV            | `rgbToHsv`              | `hsvToRgb`              |
| CMY            | `rgbToCmy`              | `cmyToRgb`              |
| CMYK           | `cmyToCmyk`             | `cmykToCmy`             |
| IPT            | `xyzToIpt`              | `iptToXyz`              |

Convenience shortcuts: `sRgbToLab`, `sRgbToLchAb`, `sRgbToHsl`,
`sRgbToHsv`, `labToSRgb`, `lchAbToSRgb`.

## Delta E reference

| Delta E < 1.0 | Imperceptible to humans |
| Delta E 1–2   | Perceptible on close inspection |
| Delta E 2–3.5 | Perceptible at a glance |
| Delta E 5+    | Clearly different colors |

## Illuminants supported

| Observer | Illuminants |
|----------|-------------|
| 2°       | A, B, C, D50, D55, D65, D75, E, F2, F7, F11 |
| 10°      | D50, D55, D65, D75 |

## Running tests

```bash
# Regenerate fixtures from Python colormath (one-time)
pip3.11 install colormath numpy
python3.11 tool/generate_fixtures.py

# Run all Dart tests
dart test
```

## License

BSD-3-Clause (matches Python colormath).
