import 'package:chromatic/chromatic.dart' as c;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shared/app_scaffold.dart';
import '../shared/color_utils.dart';

class GradientPage extends StatefulWidget {
  const GradientPage({super.key});

  @override
  State<GradientPage> createState() => _GradientPageState();
}

class _GradientPageState extends State<GradientPage> {
  Color _colorA = const Color(0xFFE63946); // vivid red
  Color _colorB = const Color(0xFF2EC4B6); // teal

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Headline(),
          const SizedBox(height: 36),
          _GradientComparison(colorA: _colorA, colorB: _colorB),
          const SizedBox(height: 36),
          _ColorPickers(
            colorA: _colorA,
            colorB: _colorB,
            onChangedA: (v) => setState(() => _colorA = v),
            onChangedB: (v) => setState(() => _colorB = v),
          ),
          const SizedBox(height: 36),
          _CodeSnippet(),
          const SizedBox(height: 36),
          _Explainer(),
        ],
      ),
    );
  }
}

// ── Headline ────────────────────────────────────────────────────────────────

class _Headline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Your Flutter gradients are lying to you.',
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
          'Color.lerp interpolates in RGB space. That means gradients between '
          'vivid colors pass through muddy greys — because RGB treats color '
          'channels as perceptually equal, which they are not. '
          'chromatic interpolates in Lab space, which mirrors human perception.',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF475569),
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

// ── Gradient comparison ────────────────────────────────────────────────────

class _GradientComparison extends StatelessWidget {
  const _GradientComparison({required this.colorA, required this.colorB});

  final Color colorA;
  final Color colorB;

  static const int _steps = 20;

  @override
  Widget build(BuildContext context) {
    final labA = c.sRgbToLab(toChromatic(colorA));
    final labB = c.sRgbToLab(toChromatic(colorB));

    final rgbGradient = <Color>[];
    final labGradient = <Color>[];

    for (var i = 0; i < _steps; i++) {
      final t = i / (_steps - 1);

      // Linear RGB — the Flutter default.
      rgbGradient.add(
        Color.fromARGB(
          255,
          (lerp(colorA.r * 255, colorB.r * 255, t)).round().clamp(0, 255),
          (lerp(colorA.g * 255, colorB.g * 255, t)).round().clamp(0, 255),
          (lerp(colorA.b * 255, colorB.b * 255, t)).round().clamp(0, 255),
        ),
      );

      // Lab — perceptually uniform.
      final lab = c.LabColor(
        lerp(labA.l, labB.l, t),
        lerp(labA.a, labB.a, t),
        lerp(labA.b, labB.b, t),
      );
      labGradient.add(toFlutterColor(c.labToSRgb(lab)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _GradientStrip(
          label: 'Color.lerp',
          sublabel: 'Flutter default — linear RGB',
          colors: rgbGradient,
          accent: const Color(0xFFEF4444),
        ),
        const SizedBox(height: 22),
        _GradientStrip(
          label: 'lerpLab',
          sublabel: 'chromatic — perceptual Lab space',
          colors: labGradient,
          accent: const Color(0xFF10B981),
        ),
      ],
    );
  }
}

class _GradientStrip extends StatelessWidget {
  const _GradientStrip({
    required this.label,
    required this.sublabel,
    required this.colors,
    required this.accent,
  });

  final String label;
  final String sublabel;
  final List<Color> colors;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Menlo',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              sublabel,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 80,
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

// ── Color pickers ──────────────────────────────────────────────────────────

class _ColorPickers extends StatelessWidget {
  const _ColorPickers({
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
      final a = _MiniPicker(
        label: 'start color',
        color: colorA,
        onChanged: onChangedA,
      );
      final b = _MiniPicker(
        label: 'end color',
        color: colorB,
        onChanged: onChangedB,
      );
      if (isWide) {
        return Row(children: [
          Expanded(child: a),
          const SizedBox(width: 16),
          Expanded(child: b),
        ]);
      }
      return Column(children: [a, const SizedBox(height: 16), b]);
    });
  }
}

class _MiniPicker extends StatefulWidget {
  const _MiniPicker({
    required this.label,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  State<_MiniPicker> createState() => _MiniPickerState();
}

class _MiniPickerState extends State<_MiniPicker> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: hexOf(widget.color));
  }

  @override
  void didUpdateWidget(covariant _MiniPicker old) {
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
          ),
          const SizedBox(width: 16),
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
                const SizedBox(height: 4),
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
                    fontSize: 15,
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

// ── Code snippet ───────────────────────────────────────────────────────────

class _CodeSnippet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'The fix',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 14),
          _CodeLine(
            marker: '//',
            comment: ' Before: muddy greys in the middle',
            commentColor: Color(0xFF64748B),
          ),
          _CodeLine(
            text: 'Color.lerp(red, teal, 0.5);',
          ),
          SizedBox(height: 16),
          _CodeLine(
            marker: '//',
            comment: ' After: vivid across the whole range',
            commentColor: Color(0xFF34D399),
          ),
          _CodeLine(
            text: "import 'package:chromatic/chromatic.dart';",
          ),
          _CodeLine(
            text: 'lerpLab(red, teal, 0.5);',
          ),
        ],
      ),
    );
  }
}

class _CodeLine extends StatelessWidget {
  const _CodeLine({
    this.text,
    this.marker,
    this.comment,
    this.commentColor,
  });

  final String? text;
  final String? marker;
  final String? comment;
  final Color? commentColor;

  @override
  Widget build(BuildContext context) {
    if (marker != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text.rich(
          TextSpan(children: [
            TextSpan(
              text: marker!,
              style: TextStyle(
                fontFamily: 'Menlo',
                fontSize: 14,
                color: commentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: comment ?? '',
              style: TextStyle(
                fontFamily: 'Menlo',
                fontSize: 14,
                color: commentColor,
              ),
            ),
          ]),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Text(
        text ?? '',
        style: const TextStyle(
          fontFamily: 'Menlo',
          fontSize: 14,
          color: Color(0xFFE2E8F0),
        ),
      ),
    );
  }
}

// ── Explainer ──────────────────────────────────────────────────────────────

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
            'WHY THIS HAPPENS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'RGB is a hardware representation, not a perceptual one. '
            'Averaging the red, green, and blue channels between two vivid '
            'colors produces something in the middle of the RGB cube — often '
            'a desaturated grey. Lab space is designed so that Euclidean '
            'distance approximates how different two colors look to humans. '
            'Interpolating there keeps saturation high across the transition.',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF475569),
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}
