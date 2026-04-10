#!/usr/bin/env python3
"""
Python colormath benchmarks for comparison against Dart chromatic.

Run: python3.11 benchmark/benchmark.py
"""

import random
import time

import numpy as np
from colormath.color_objects import (
    sRGBColor, LabColor, XYZColor, HSLColor, HSVColor, LCHabColor, LuvColor,
)
from colormath.color_conversions import convert_color
from colormath.chromatic_adaptation import apply_chromatic_adaptation
from colormath.color_diff_matrix import (
    delta_e_cie1976 as _de76,
    delta_e_cie1994 as _de94,
    delta_e_cie2000 as _de00,
    delta_e_cmc as _cmc,
)

ITERATIONS = 100_000
rng = random.Random(42)


def _as_vec(lab):
    return np.array([lab.lab_l, lab.lab_a, lab.lab_b])


def _as_mat(lab):
    return np.array([[lab.lab_l, lab.lab_a, lab.lab_b]])


def bench(name, fn):
    # Warmup
    for _ in range(1000):
        fn()

    start = time.perf_counter()
    for _ in range(ITERATIONS):
        fn()
    ms = (time.perf_counter() - start) * 1000
    ops = int(ITERATIONS / (ms / 1000))
    print(f'{name:<40}{ms:>12.2f}{ops:>16,}')


def main():
    print(f'Python colormath benchmarks — {ITERATIONS} iterations each\n')
    print(f'{"operation":<40}{"time (ms)":>12}{"ops/sec":>16}')
    print('─' * 68)

    def rgb_to_lab():
        rgb = sRGBColor(rng.random(), rng.random(), rng.random())
        convert_color(rgb, LabColor)
    bench('sRGB → Lab', rgb_to_lab)

    def rgb_to_xyz():
        rgb = sRGBColor(rng.random(), rng.random(), rng.random())
        convert_color(rgb, XYZColor)
    bench('sRGB → XYZ', rgb_to_xyz)

    def rgb_to_hsl():
        rgb = sRGBColor(rng.random(), rng.random(), rng.random())
        convert_color(rgb, HSLColor)
    bench('sRGB → HSL', rgb_to_hsl)

    def rgb_to_hsv():
        rgb = sRGBColor(rng.random(), rng.random(), rng.random())
        convert_color(rgb, HSVColor)
    bench('sRGB → HSV', rgb_to_hsv)

    def rgb_to_lch():
        rgb = sRGBColor(rng.random(), rng.random(), rng.random())
        convert_color(rgb, LCHabColor)
    bench('sRGB → LCH', rgb_to_lch)

    def rgb_to_luv():
        rgb = sRGBColor(rng.random(), rng.random(), rng.random())
        convert_color(rgb, LuvColor)
    bench('sRGB → Luv', rgb_to_luv)

    def lab_to_rgb():
        lab = LabColor(rng.random() * 100, (rng.random() - 0.5) * 200, (rng.random() - 0.5) * 200)
        convert_color(lab, sRGBColor)
    bench('Lab → sRGB', lab_to_rgb)

    lab_a = LabColor(50, 30, -20)
    lab_b = LabColor(70, -10, 40)
    vec_a = _as_vec(lab_a)
    mat_b = _as_mat(lab_b)

    bench('Delta E 1976', lambda: _de76(vec_a, mat_b))
    bench('Delta E 1994', lambda: _de94(vec_a, mat_b))
    bench('Delta E CIEDE2000', lambda: _de00(vec_a, mat_b))
    bench('Delta E CMC', lambda: _cmc(vec_a, mat_b))

    bench('Bradford adaptation',
          lambda: apply_chromatic_adaptation(0.5, 0.4, 0.1, 'c', 'd65'))

    def hex_to_lab():
        convert_color(sRGBColor.new_from_rgb_hex('#ff8040'), LabColor)
    bench('hex → Lab', hex_to_lab)

    # Batch: 100K colors to Lab
    batch = [sRGBColor(rng.random(), rng.random(), rng.random()) for _ in range(1000)]
    start = time.perf_counter()
    for _ in range(100):
        for rgb in batch:
            convert_color(rgb, LabColor)
    ms = (time.perf_counter() - start) * 1000
    print(f'\nBatch (100K colors, sRGB→Lab): {ms:.2f} ms')
    print(f'  → {int(100000 / (ms / 1000)):,} colors/sec')


if __name__ == '__main__':
    main()
