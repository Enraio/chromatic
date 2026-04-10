import 'package:chromatic/chromatic.dart' as c;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const ChromaticDemoApp());

class ChromaticDemoApp extends StatelessWidget {
  const ChromaticDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'chromatic — color science demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.light,
        ),
      ),
      home: const DemoHomePage(),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key});

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  Color _colorA = const Color(0xFFE63946);
  Color _colorB = const Color(0xFF457B9D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Header(),
                  const SizedBox(height: 32),
                  _ColorInputs(
                    colorA: _colorA,
                    colorB: _colorB,
                    onChangedA: (c) => setState(() => _colorA = c),
                    onChangedB: (c) => setState(() => _colorB = c),
                  ),
                  const SizedBox(height: 32),
                  _DeltaEPanel(colorA: _colorA, colorB: _colorB),
                  const SizedBox(height: 32),
                  _GradientComparison(colorA: _colorA, colorB: _colorB),
                  const SizedBox(height: 32),
                  const _Footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE63946),
                    Color(0xFFF1FAEE),
                    Color(0xFF457B9D),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'chromatic',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'v0.1.1',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF059669),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Color science for Dart — ported from Python colormath',
          style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}

// ── Color inputs ────────────────────────────────────────────────────────────

class _ColorInputs extends StatelessWidget {
  const _ColorInputs({
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
    return Row(
      children: [
        Expanded(
          child: _ColorCard(
            label: 'Color A',
            color: colorA,
            onChanged: onChangedA,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ColorCard(
            label: 'Color B',
            color: colorB,
            onChanged: onChangedB,
          ),
        ),
      ],
    );
  }
}

class _ColorCard extends StatefulWidget {
  const _ColorCard({
    required this.label,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  State<_ColorCard> createState() => _ColorCardState();
}

class _ColorCardState extends State<_ColorCard> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _hexOf(widget.color));
  }

  @override
  void didUpdateWidget(covariant _ColorCard old) {
    super.didUpdateWidget(old);
    final newHex = _hexOf(widget.color);
    if (_controller.text.toLowerCase() != newHex.toLowerCase()) {
      _controller.text = newHex;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHexSubmitted(String raw) {
    try {
      final srgb = c.SRgbColor.fromHex(raw.trim());
      widget.onChanged(_toFlutterColor(srgb));
    } catch (_) {
      _controller.text = _hexOf(widget.color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lab = c.sRgbToLab(_toChromatic(widget.color));
    final lch = c.labToLchAb(lab);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 88,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            onSubmitted: _onHexSubmitted,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F#]')),
              LengthLimitingTextInputFormatter(7),
            ],
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            style: const TextStyle(
              fontFamily: 'Menlo',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          _LabRow('L*', lab.l),
          _LabRow('a*', lab.a),
          _LabRow('b*', lab.b),
          const SizedBox(height: 2),
          _LabRow('C*', lch.c),
          _LabRow('h°', lch.h),
        ],
      ),
    );
  }
}

class _LabRow extends StatelessWidget {
  const _LabRow(this.label, this.value);
  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(
              fontFamily: 'Menlo',
              fontSize: 12,
              color: Color(0xFF334155),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Delta E panel ───────────────────────────────────────────────────────────

class _DeltaEPanel extends StatelessWidget {
  const _DeltaEPanel({required this.colorA, required this.colorB});

  final Color colorA;
  final Color colorB;

  @override
  Widget build(BuildContext context) {
    final labA = c.sRgbToLab(_toChromatic(colorA));
    final labB = c.sRgbToLab(_toChromatic(colorB));

    final de76 = c.deltaE76(labA, labB);
    final de94 = c.deltaE94(labA, labB);
    final de00 = c.deltaE00(labA, labB);
    final cmc = c.deltaECmc(labA, labB);

    final verdict = _verdict(de00);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CIEDE2000',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  de00.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: verdict.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    verdict.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: verdict.color,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  verdict.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'COMPARISON',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 16),
                _MetricRow('CIE76', de76),
                _MetricRow('CIE94', de94),
                _MetricRow('CIEDE2000', de00, highlight: true),
                _MetricRow('CMC 2:1', cmc),
                const SizedBox(height: 14),
                const Text(
                  'CIE76 uses naive Euclidean distance — fast but '
                  'perceptually inaccurate, especially for blues.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    height: 1.5,
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

class _MetricRow extends StatelessWidget {
  const _MetricRow(this.label, this.value, {this.highlight = false});
  final String label;
  final double value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
                color: highlight
                    ? const Color(0xFF0F172A)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              fontFamily: 'Menlo',
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color: highlight
                  ? const Color(0xFF0F172A)
                  : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _Verdict {
  const _Verdict(this.label, this.description, this.color);
  final String label;
  final String description;
  final Color color;
}

_Verdict _verdict(double de) {
  if (de < 1.0) {
    return const _Verdict(
        'IMPERCEPTIBLE',
        'Indistinguishable to most humans',
        Color(0xFF10B981));
  }
  if (de < 2.0) {
    return const _Verdict(
        'BARELY NOTICEABLE',
        'Perceptible only on close inspection',
        Color(0xFF10B981));
  }
  if (de < 3.5) {
    return const _Verdict(
        'NOTICEABLE', 'Perceptible at a glance', Color(0xFFF59E0B));
  }
  if (de < 5.0) {
    return const _Verdict(
        'CLEARLY DIFFERENT', 'Obvious color difference', Color(0xFFF97316));
  }
  return const _Verdict(
      'VERY DIFFERENT', 'Completely distinct colors', Color(0xFFEF4444));
}

// ── Gradient comparison ─────────────────────────────────────────────────────

class _GradientComparison extends StatelessWidget {
  const _GradientComparison({required this.colorA, required this.colorB});

  final Color colorA;
  final Color colorB;

  static const int _steps = 14;

  @override
  Widget build(BuildContext context) {
    final labA = c.sRgbToLab(_toChromatic(colorA));
    final labB = c.sRgbToLab(_toChromatic(colorB));

    final rgbGradient = <Color>[];
    final labGradient = <Color>[];

    for (var i = 0; i < _steps; i++) {
      final t = i / (_steps - 1);

      // Linear RGB interpolation — passes through muddy greys.
      rgbGradient.add(
        Color.fromARGB(
          255,
          _lerp(colorA.r * 255, colorB.r * 255, t).round().clamp(0, 255),
          _lerp(colorA.g * 255, colorB.g * 255, t).round().clamp(0, 255),
          _lerp(colorA.b * 255, colorB.b * 255, t).round().clamp(0, 255),
        ),
      );

      // Lab interpolation — perceptually uniform.
      final lab = c.LabColor(
        _lerp(labA.l, labB.l, t),
        _lerp(labA.a, labB.a, t),
        _lerp(labA.b, labB.b, t),
      );
      labGradient.add(_toFlutterColor(c.labToSRgb(lab)));
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WHY PERCEPTUAL COLOR SPACES MATTER',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Same endpoints, different color spaces. RGB interpolation passes '
            'through muddy greys because it treats channels as perceptually '
            'equal. Lab interpolation stays vibrant because it mirrors how '
            'humans actually see color.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          _GradientStrip(
              label: 'Linear RGB interpolation', colors: rgbGradient),
          const SizedBox(height: 18),
          _GradientStrip(
            label: 'Lab interpolation (perceptual)',
            colors: labGradient,
            highlight: true,
          ),
        ],
      ),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;
}

class _GradientStrip extends StatelessWidget {
  const _GradientStrip({
    required this.label,
    required this.colors,
    this.highlight = false,
  });

  final String label;
  final List<Color> colors;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: highlight
                    ? const Color(0xFF059669)
                    : const Color(0xFF64748B),
              ),
            ),
            if (highlight) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'chromatic',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF059669),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 56,
            child: Row(
              children: [
                for (final color in colors)
                  Expanded(child: Container(color: color)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ── Footer ──────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'pub.dev/packages/chromatic  ·  github.com/Enraio/chromatic',
        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      ),
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

c.SRgbColor _toChromatic(Color color) =>
    c.SRgbColor(color.r, color.g, color.b);

Color _toFlutterColor(c.SRgbColor srgb) => Color.from(
      alpha: 1.0,
      red: srgb.r.clamp(0.0, 1.0),
      green: srgb.g.clamp(0.0, 1.0),
      blue: srgb.b.clamp(0.0, 1.0),
    );

String _hexOf(Color color) {
  String two(double v) =>
      (v * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '#${two(color.r)}${two(color.g)}${two(color.b)}';
}
