import 'dart:math' as math;

import 'package:chromatic/chromatic.dart' as c;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shared/app_scaffold.dart';
import '../shared/color_utils.dart';

/// "Gotcha" preset pairs — each curated to dramatically demonstrate
/// the gap between naive Euclidean RGB distance and CIEDE2000.
class _Preset {
  const _Preset({
    required this.name,
    required this.tagline,
    required this.a,
    required this.b,
  });
  final String name;
  final String tagline;
  final Color a;
  final Color b;
}

const _presets = <_Preset>[
  _Preset(
    name: 'Tiny RGB, huge perceptual gap',
    tagline: 'warm beige vs cool lavender-grey',
    a: Color(0xFFB2B09C),
    b: Color(0xFFA697B4),
  ),
  _Preset(
    name: 'Navy vs dark teal',
    tagline: 'RGB says close — your eyes know better',
    a: Color(0xFF0D2250),
    b: Color(0xFF18413B),
  ),
  _Preset(
    name: 'Muted mauve vs olive',
    tagline: 'wildly different moods, similar RGB numbers',
    a: Color(0xFF99585B),
    b: Color(0xFF947E55),
  ),
  _Preset(
    name: 'Two neutrals that clash',
    tagline: 'dark olive vs warm dark grey',
    a: Color(0xFF5D6650),
    b: Color(0xFF6D615E),
  ),
  _Preset(
    name: 'Bright greens',
    tagline: 'RGB overstates the difference',
    a: Color(0xFF6BFD4F),
    b: Color(0xFF08FF3C),
  ),
];

class QuizPage extends StatefulWidget {
  const QuizPage({super.key});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  Color _colorA = _presets[0].a;
  Color _colorB = _presets[0].b;
  int? _activePreset = 0;

  void _loadPreset(int i) {
    setState(() {
      _colorA = _presets[i].a;
      _colorB = _presets[i].b;
      _activePreset = i;
    });
  }

  @override
  Widget build(BuildContext context) {
    final labA = c.sRgbToLab(toChromatic(_colorA));
    final labB = c.sRgbToLab(toChromatic(_colorB));
    final de = c.deltaE00(labA, labB);
    final rgbDist = _euclideanRgb(_colorA, _colorB);

    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Headline(),
          const SizedBox(height: 36),
          _ComparisonBoard(colorA: _colorA, colorB: _colorB),
          const SizedBox(height: 28),
          _Metrics(rgb: rgbDist, de: de),
          const SizedBox(height: 32),
          _Pickers(
            colorA: _colorA,
            colorB: _colorB,
            onChangedA: (v) => setState(() {
              _colorA = v;
              _activePreset = null;
            }),
            onChangedB: (v) => setState(() {
              _colorB = v;
              _activePreset = null;
            }),
          ),
          const SizedBox(height: 32),
          _PresetChips(
            activeIndex: _activePreset,
            onSelect: _loadPreset,
          ),
          const SizedBox(height: 32),
          _Explainer(),
        ],
      ),
    );
  }

  static double _euclideanRgb(Color a, Color b) {
    final dr = (a.r - b.r) * 255;
    final dg = (a.g - b.g) * 255;
    final db = (a.b - b.b) * 255;
    return math.sqrt(dr * dr + dg * dg + db * db);
  }
}

// ── Headline ──────────────────────────────────────────────────────────────

class _Headline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'RGB distance is lying.',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            height: 1.1,
            color: Color(0xFF0F172A),
          ),
        ),
        SizedBox(height: 14),
        Text(
          'Most code computes color similarity with Euclidean distance in RGB. '
          'It\'s fast, intuitive, and wrong. The pairs below look very '
          'different to human eyes, but RGB thinks they\'re basically the same.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF475569),
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

// ── Comparison board ─────────────────────────────────────────────────────

class _ComparisonBoard extends StatelessWidget {
  const _ComparisonBoard({required this.colorA, required this.colorB});
  final Color colorA;
  final Color colorB;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Expanded(child: _HalfSwatch(color: colorA, label: 'A')),
          Container(width: 1, color: const Color(0xFFE2E8F0)),
          Expanded(child: _HalfSwatch(color: colorB, label: 'B')),
        ],
      ),
    );
  }
}

class _HalfSwatch extends StatelessWidget {
  const _HalfSwatch({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final lum = 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b;
    final fg = lum > 0.55 ? const Color(0xFF0F172A) : Colors.white;

    return Container(
      height: 180,
      color: color,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: fg,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            hexOf(color),
            style: TextStyle(
              fontFamily: 'Menlo',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Metrics ───────────────────────────────────────────────────────────────

class _Metrics extends StatelessWidget {
  const _Metrics({required this.rgb, required this.de});
  final double rgb;
  final double de;

  @override
  Widget build(BuildContext context) {
    // Normalize RGB distance to 0-1 scale where 441 is max (black↔white).
    final rgbNormalized = rgb / 441.67;
    // Rough "perceptual" normalization: ΔE00 of ~30 is "completely different".
    final deNormalized = (de / 30).clamp(0.0, 1.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _MetricCard(
            title: 'EUCLIDEAN RGB',
            subtitle: 'what most code does',
            value: rgb,
            normalized: rgbNormalized,
            accent: const Color(0xFFEF4444),
            interpretation: _interpretRgb(rgb),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _MetricCard(
            title: 'CIEDE2000',
            subtitle: 'chromatic package',
            value: de,
            normalized: deNormalized,
            accent: const Color(0xFF10B981),
            interpretation: _interpretDe(de),
          ),
        ),
      ],
    );
  }

  String _interpretRgb(double v) {
    if (v < 20) return 'identical';
    if (v < 50) return 'very similar';
    if (v < 100) return 'similar';
    if (v < 200) return 'different';
    return 'very different';
  }

  String _interpretDe(double v) {
    if (v < 1.0) return 'imperceptible';
    if (v < 2.0) return 'barely noticeable';
    if (v < 3.5) return 'noticeable';
    if (v < 5.0) return 'clearly different';
    if (v < 10.0) return 'very different';
    return 'completely different';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.normalized,
    required this.accent,
    required this.interpretation,
  });

  final String title;
  final String subtitle;
  final double value;
  final double normalized;
  final Color accent;
  final String interpretation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value.toStringAsFixed(value < 10 ? 2 : 1),
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              height: 1,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: normalized.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation(accent),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            interpretation,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pickers ───────────────────────────────────────────────────────────────

class _Pickers extends StatelessWidget {
  const _Pickers({
    required this.colorA,
    required this.colorB,
    required this.onChangedA,
    required this.onChangedB,
  });

  final Color colorA;
  final Color colorB;
  final ValueChanged<Color> onChangedA;
  final ValueChanged<Color> onChangedB;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 600;
      final a =
          _HexField(label: 'color A', color: colorA, onChanged: onChangedA);
      final b =
          _HexField(label: 'color B', color: colorB, onChanged: onChangedB);
      if (isWide) {
        return Row(
            children: [Expanded(child: a), const SizedBox(width: 16), Expanded(child: b)]);
      }
      return Column(children: [a, const SizedBox(height: 16), b]);
    });
  }
}

class _HexField extends StatefulWidget {
  const _HexField({
    required this.label,
    required this.color,
    required this.onChanged,
  });
  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  State<_HexField> createState() => _HexFieldState();
}

class _HexFieldState extends State<_HexField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: hexOf(widget.color));
  }

  @override
  void didUpdateWidget(covariant _HexField old) {
    super.didUpdateWidget(old);
    final h = hexOf(widget.color);
    if (_controller.text.toLowerCase() != h.toLowerCase()) {
      _controller.text = h;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    try {
      final srgb = c.SRgbColor.fromHex(raw.trim());
      widget.onChanged(toFlutterColor(srgb));
    } catch (_) {
      _controller.text = hexOf(widget.color);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF94A3B8),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                TextField(
                  controller: _controller,
                  onSubmitted: _submit,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9a-fA-F#]')),
                    LengthLimitingTextInputFormatter(7),
                  ],
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                    fontFamily: 'Menlo',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Preset chips ─────────────────────────────────────────────────────────

class _PresetChips extends StatelessWidget {
  const _PresetChips({required this.activeIndex, required this.onSelect});
  final int? activeIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PRESET PAIRS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < _presets.length; i++)
              _PresetChip(
                preset: _presets[i],
                active: activeIndex == i,
                onTap: () => onSelect(i),
              ),
          ],
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.preset,
    required this.active,
    required this.onTap,
  });
  final _Preset preset;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? const Color(0xFF0F172A)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: preset.a,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: preset.b,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              preset.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Explainer ────────────────────────────────────────────────────────────

class _Explainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'WHEN THIS MATTERS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 12),
          _BulletLine(
            text: 'Color matching and search — "find items with similar colors"',
          ),
          _BulletLine(
            text: 'Quality control — verifying print or screen output matches a target',
          ),
          _BulletLine(
            text: 'Brand consistency — "is this logo variant within tolerance?"',
          ),
          _BulletLine(
            text: 'Accessibility — grouping colors that look similar to humans',
          ),
          _BulletLine(
            text: 'Image clustering — extracting dominant colors from photos',
          ),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 5, color: Color(0xFF10B981)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF475569),
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
