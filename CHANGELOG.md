# Changelog

## 0.1.0

Initial release. Port of Python colormath with identical math.

### Added
- 10 color space types: sRGB, Adobe RGB, Apple RGB, BT.2020, XYZ, xyY,
  Lab, LCH(ab), Luv, LCH(uv), HSL, HSV, CMY, CMYK, IPT
- Color space conversions between all supported spaces
- Delta E formulas: CIE76, CIE94, CIEDE2000, CMC l:c
- Chromatic adaptation: Bradford, von Kries, XYZ scaling
- Proper sRGB EOTF (piecewise, not simple power gamma)
- Proper BT.2020 transfer function
- Hex parsing (6-digit, 3-digit shorthand, with or without `#`)
- 11 illuminants for 2° observer, 4 for 10°
- 690+ test fixtures validated against Python colormath output
- Sharma 2005 CIEDE2000 reference dataset (34 pairs) integration tests
- Benchmark suite comparing against Python colormath
