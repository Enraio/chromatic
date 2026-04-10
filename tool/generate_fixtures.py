#!/usr/bin/env python3
"""
Generate test fixtures from Python colormath.

Outputs JSON files that the Dart test suite loads to validate
that our port produces identical results.

Install: pip3.11 install colormath
Run:     python3.11 tool/generate_fixtures.py
"""

import json
import math
import os

from colormath.color_objects import (
    sRGBColor, AdobeRGBColor, LabColor, XYZColor, HSLColor, HSVColor,
    LCHabColor, LCHuvColor, LuvColor, CMYColor, CMYKColor, xyYColor, IPTColor,
)
from colormath.color_conversions import convert_color
import numpy as np
from colormath.color_diff_matrix import (
    delta_e_cie1976 as _de76_mat,
    delta_e_cie1994 as _de94_mat,
    delta_e_cie2000 as _de00_mat,
    delta_e_cmc as _cmc_mat,
)

# Wrap matrix-based delta-e to take two LabColor objects.
# (colormath's high-level wrappers use numpy.asscalar which is removed.)

def _as_vec(lab):
    return np.array([lab.lab_l, lab.lab_a, lab.lab_b])

def _as_mat(lab):
    return np.array([[lab.lab_l, lab.lab_a, lab.lab_b]])

def delta_e_cie1976(c1, c2):
    return float(_de76_mat(_as_vec(c1), _as_mat(c2))[0])

def delta_e_cie1994(c1, c2, K_L=1, K_C=1, K_H=1, K_1=0.045, K_2=0.015):
    return float(_de94_mat(_as_vec(c1), _as_mat(c2),
                            K_L=K_L, K_C=K_C, K_H=K_H, K_1=K_1, K_2=K_2)[0])

def delta_e_cie2000(c1, c2, Kl=1, Kc=1, Kh=1):
    return float(_de00_mat(_as_vec(c1), _as_mat(c2), Kl=Kl, Kc=Kc, Kh=Kh)[0])

def delta_e_cmc(c1, c2, pl=2, pc=1):
    return float(_cmc_mat(_as_vec(c1), _as_mat(c2), pl=pl, pc=pc)[0])

OUT_DIR = os.path.join(os.path.dirname(__file__), '..', 'test', 'fixtures')
os.makedirs(OUT_DIR, exist_ok=True)


def _round(v, n=10):
    """Round to n decimal places, handling NaN/Inf."""
    if math.isnan(v) or math.isinf(v):
        return 0.0
    return round(v, n)


# ── 1. Conversion fixtures ──────────────────────────────────────────────────

def generate_conversion_fixtures():
    """Sweep RGB space and record conversions to all target spaces."""
    fixtures = []
    steps = [0.0, 0.1, 0.25, 0.5, 0.75, 0.9, 1.0]

    for r in steps:
        for g in steps:
            for b in steps:
                rgb = sRGBColor(r, g, b)

                try:
                    lab = convert_color(rgb, LabColor)
                except:
                    continue
                try:
                    xyz = convert_color(rgb, XYZColor)
                except:
                    continue
                try:
                    hsl = convert_color(rgb, HSLColor)
                except:
                    continue
                try:
                    hsv = convert_color(rgb, HSVColor)
                except:
                    continue
                try:
                    lch = convert_color(rgb, LCHabColor)
                except:
                    continue
                try:
                    luv = convert_color(rgb, LuvColor)
                except:
                    continue
                try:
                    lchuv = convert_color(rgb, LCHuvColor)
                except:
                    continue
                try:
                    xyy = convert_color(rgb, xyYColor)
                except:
                    continue
                try:
                    cmy = convert_color(rgb, CMYColor)
                except:
                    continue
                try:
                    cmyk = convert_color(rgb, CMYKColor)
                except:
                    continue

                fixtures.append({
                    'rgb': [_round(r), _round(g), _round(b)],
                    'lab': [_round(lab.lab_l), _round(lab.lab_a), _round(lab.lab_b)],
                    'xyz': [_round(xyz.xyz_x), _round(xyz.xyz_y), _round(xyz.xyz_z)],
                    'hsl': [_round(hsl.hsl_h), _round(hsl.hsl_s), _round(hsl.hsl_l)],
                    'hsv': [_round(hsv.hsv_h), _round(hsv.hsv_s), _round(hsv.hsv_v)],
                    'lch': [_round(lch.lch_l), _round(lch.lch_c), _round(lch.lch_h)],
                    'luv': [_round(luv.luv_l), _round(luv.luv_u), _round(luv.luv_v)],
                    'lchuv': [_round(lchuv.lch_l), _round(lchuv.lch_c), _round(lchuv.lch_h)],
                    'xyy': [_round(xyy.xyy_x), _round(xyy.xyy_y), _round(xyy.xyy_Y)],
                    'cmy': [_round(cmy.cmy_c), _round(cmy.cmy_m), _round(cmy.cmy_y)],
                    'cmyk': [_round(cmyk.cmyk_c), _round(cmyk.cmyk_m), _round(cmyk.cmyk_y), _round(cmyk.cmyk_k)],
                })

    path = os.path.join(OUT_DIR, 'conversions.json')
    with open(path, 'w') as f:
        json.dump(fixtures, f, indent=2)
    print(f'Wrote {len(fixtures)} conversion fixtures to {path}')


# ── 2. Delta E fixtures ────────────────────────────────────────────────────

def generate_delta_e_fixtures():
    """Generate Delta E test pairs."""
    pairs = []

    # Basic pair from colormath tests.
    test_colors = [
        (0.9, 16.3, -2.22),
        (0.7, 14.2, -1.80),
        (50.0, 0.0, 0.0),
        (50.0, -1.0, 2.0),
        (69.417, -12.612, -11.271),
        (83.386, 39.426, -17.525),
        (32.8911, -53.0107, -43.3182),
        (77.1797, 25.5928, 17.9412),
        (50.0, 25.0, -10.0),
        (50.0, -25.0, 10.0),
        (0.0, 0.0, 0.0),
        (100.0, 0.0, 0.0),
        (50.0, 50.0, 50.0),
        (50.0, -50.0, -50.0),
    ]

    for i in range(len(test_colors)):
        for j in range(i + 1, len(test_colors)):
            l1, a1, b1 = test_colors[i]
            l2, a2, b2 = test_colors[j]
            c1 = LabColor(l1, a1, b1)
            c2 = LabColor(l2, a2, b2)

            pairs.append({
                'lab1': [l1, a1, b1],
                'lab2': [l2, a2, b2],
                'de76': _round(delta_e_cie1976(c1, c2), 6),
                'de94': _round(delta_e_cie1994(c1, c2), 6),
                'de94_textiles': _round(delta_e_cie1994(c1, c2, K_L=2, K_1=0.048, K_2=0.014), 6),
                'de2000': _round(delta_e_cie2000(c1, c2), 6),
                'cmc_21': _round(delta_e_cmc(c1, c2, pl=2, pc=1), 6),
                'cmc_11': _round(delta_e_cmc(c1, c2, pl=1, pc=1), 6),
            })

    path = os.path.join(OUT_DIR, 'delta_e.json')
    with open(path, 'w') as f:
        json.dump(pairs, f, indent=2)
    print(f'Wrote {len(pairs)} Delta E fixtures to {path}')


# ── 3. Sharma 2005 CIEDE2000 reference dataset ─────────────────────────────

def generate_sharma_fixtures():
    """The 34 reference pairs from Sharma, Wu, Dalal (2005)."""
    # Pairs from Table 1 of the paper.
    sharma = [
        # (L1, a1, b1, L2, a2, b2, expected_dE)
        (50.0000, 2.6772, -79.7751, 50.0000, 0.0000, -82.7485, 2.0425),
        (50.0000, 3.1571, -77.2803, 50.0000, 0.0000, -82.7485, 2.8615),
        (50.0000, 2.8361, -74.0200, 50.0000, 0.0000, -82.7485, 3.4412),
        (50.0000, -1.3802, -84.2814, 50.0000, 0.0000, -82.7485, 1.0000),
        (50.0000, -1.1848, -84.8006, 50.0000, 0.0000, -82.7485, 1.0000),
        (50.0000, -0.9009, -85.5211, 50.0000, 0.0000, -82.7485, 1.0000),
        (50.0000, 0.0000, 0.0000, 50.0000, -1.0000, 2.0000, 2.3669),
        (50.0000, -1.0000, 2.0000, 50.0000, 0.0000, 0.0000, 2.3669),
        (50.0000, 2.4900, -0.0010, 50.0000, -2.4900, 0.0009, 7.1792),
        (50.0000, 2.4900, -0.0010, 50.0000, -2.4900, 0.0010, 7.1792),
        (50.0000, 2.4900, -0.0010, 50.0000, -2.4900, 0.0011, 7.2195),
        (50.0000, 2.4900, -0.0010, 50.0000, -2.4900, 0.0012, 7.2195),
        (50.0000, -0.0010, 2.4900, 50.0000, 0.0009, -2.4900, 4.8045),
        (50.0000, -0.0010, 2.4900, 50.0000, 0.0010, -2.4900, 4.8045),
        (50.0000, -0.0010, 2.4900, 50.0000, 0.0011, -2.4900, 4.7461),
        (50.0000, 2.5000, 0.0000, 50.0000, 0.0000, -2.5000, 4.3065),
        (50.0000, 2.5000, 0.0000, 73.0000, 25.0000, -18.0000, 27.1492),
        (50.0000, 2.5000, 0.0000, 61.0000, -5.0000, 29.0000, 22.8977),
        (50.0000, 2.5000, 0.0000, 56.0000, -27.0000, -3.0000, 31.9030),
        (50.0000, 2.5000, 0.0000, 58.0000, 24.0000, 15.0000, 19.4535),
        (50.0000, 2.5000, 0.0000, 50.0000, 3.1736, 0.5854, 1.0000),
        (50.0000, 2.5000, 0.0000, 50.0000, 3.2972, 0.0000, 1.0000),
        (50.0000, 2.5000, 0.0000, 50.0000, 1.8634, 0.5757, 1.0000),
        (50.0000, 2.5000, 0.0000, 50.0000, 3.2592, 0.3350, 1.0000),
        (60.2574, -34.0099, 36.2677, 60.4626, -34.1751, 39.4387, 1.2644),
        (63.0109, -31.0961, -5.8663, 62.8187, -29.7946, -4.0864, 1.2630),
        (61.2901, 3.7196, -5.3901, 61.4292, 2.2480, -4.9620, 1.8731),
        (35.0831, -44.1164, 3.7933, 35.0232, -40.0716, 1.5901, 1.8645),
        (22.7233, 20.0904, -46.6940, 23.0331, 14.9730, -42.5619, 2.0373),
        (36.4612, 47.8580, 18.3852, 36.2715, 50.5065, 21.2231, 1.4146),
        (90.8027, -2.0831, 1.4410, 91.1528, -1.6435, 0.0447, 1.4441),
        (90.9257, -0.5406, -0.9208, 88.6381, -0.8985, -0.7239, 1.5381),
        (6.7747, -0.2908, -2.4247, 5.8714, -0.0985, -2.2286, 0.6377),
        (2.0776, 0.0795, -1.1350, 0.9033, -0.0636, -0.5514, 0.9082),
    ]

    fixtures = []
    for row in sharma:
        l1, a1, b1, l2, a2, b2, expected = row
        fixtures.append({
            'lab1': [l1, a1, b1],
            'lab2': [l2, a2, b2],
            'expected_de2000': expected,
        })

    path = os.path.join(OUT_DIR, 'sharma2005.json')
    with open(path, 'w') as f:
        json.dump(fixtures, f, indent=2)
    print(f'Wrote {len(fixtures)} Sharma 2005 fixtures to {path}')


# ── 4. Chromatic adaptation fixtures ────────────────────────────────────────

def generate_adaptation_fixtures():
    """Test chromatic adaptation transforms."""
    from colormath.chromatic_adaptation import apply_chromatic_adaptation

    fixtures = []

    test_cases = [
        # (x, y, z, source_illuminant, target_illuminant, method)
        (0.5, 0.4, 0.1, 'c', 'd65', 'bradford'),
        (0.5, 0.4, 0.1, 'd50', 'd65', 'bradford'),
        (0.5, 0.4, 0.1, 'd65', 'd50', 'bradford'),
        (0.5, 0.4, 0.1, 'a', 'd65', 'bradford'),
        (0.3, 0.6, 0.2, 'c', 'd65', 'von_kries'),
        (0.3, 0.6, 0.2, 'd50', 'd65', 'von_kries'),
        (0.8, 0.2, 0.5, 'd65', 'd50', 'bradford'),
        (0.1, 0.1, 0.1, 'a', 'd65', 'bradford'),
    ]

    for x, y, z, src, tgt, method in test_cases:
        rx, ry, rz = apply_chromatic_adaptation(
            x, y, z, src, tgt, observer='2', adaptation=method
        )
        fixtures.append({
            'xyz': [x, y, z],
            'source': src,
            'target': tgt,
            'method': method,
            'result': [_round(float(rx)), _round(float(ry)), _round(float(rz))],
        })

    path = os.path.join(OUT_DIR, 'adaptation.json')
    with open(path, 'w') as f:
        json.dump(fixtures, f, indent=2)
    print(f'Wrote {len(fixtures)} adaptation fixtures to {path}')


# ── 5. Round-trip fixtures ──────────────────────────────────────────────────

def generate_roundtrip_fixtures():
    """Verify RGB → Lab → RGB produces original values."""
    fixtures = []
    steps = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]

    for r in steps:
        for g in steps:
            for b in steps:
                rgb = sRGBColor(r, g, b)
                lab = convert_color(rgb, LabColor)
                back = convert_color(lab, sRGBColor)

                fixtures.append({
                    'original': [_round(r), _round(g), _round(b)],
                    'lab': [_round(lab.lab_l), _round(lab.lab_a), _round(lab.lab_b)],
                    'roundtrip': [
                        _round(back.rgb_r),
                        _round(back.rgb_g),
                        _round(back.rgb_b),
                    ],
                })

    path = os.path.join(OUT_DIR, 'roundtrip.json')
    with open(path, 'w') as f:
        json.dump(fixtures, f, indent=2)
    print(f'Wrote {len(fixtures)} round-trip fixtures to {path}')


# ── Main ────────────────────────────────────────────────────────────────────

if __name__ == '__main__':
    generate_conversion_fixtures()
    generate_delta_e_fixtures()
    generate_sharma_fixtures()
    generate_adaptation_fixtures()
    generate_roundtrip_fixtures()
    print('\nDone! All fixtures written to test/fixtures/')
