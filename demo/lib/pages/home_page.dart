import 'package:flutter/material.dart';

import '../shared/app_scaffold.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      showBack: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),
          _Hero(),
          const SizedBox(height: 56),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              if (isWide) {
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: const [
                      Expanded(child: _DemoCard.gradient()),
                      SizedBox(width: 20),
                      Expanded(child: _DemoCard.quiz()),
                    ],
                  ),
                );
              }
              return Column(
                children: const [
                  _DemoCard.gradient(),
                  SizedBox(height: 20),
                  _DemoCard.quiz(),
                ],
              );
            },
          ),
          const SizedBox(height: 56),
          const _Footer(),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFE63946),
                    Color(0xFFF1FAEE),
                    Color(0xFF457B9D),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'chromatic',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'v0.1.1',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'color science for Dart',
                  style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          'Most color code in Flutter uses RGB math, which doesn\'t match '
          'how humans see color. chromatic ports Python\'s colormath to '
          'Dart so you can do color work the right way — perceptual distance, '
          'Lab / LCH conversions, chromatic adaptation, and more.',
          style: TextStyle(
            fontSize: 17,
            color: Color(0xFF334155),
            height: 1.55,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Two interactive demos show why it matters.',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF64748B),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _DemoCard extends StatelessWidget {
  const _DemoCard.gradient()
    : title = 'The gradient bug',
      subtitle = 'Why your Flutter gradients look muddy',
      body =
          'Color.lerp interpolates in RGB, which passes through grey on the '
          'way between vivid colors. Lab interpolation keeps them vivid. '
          'Move the sliders and see the difference.',
      route = '/gradient',
      accent = const Color(0xFFEF4444);

  const _DemoCard.quiz()
    : title = 'The distance test',
      subtitle = 'When naive RGB math gets it wrong',
      body =
          'Preset pairs where Euclidean RGB distance says "close" but your '
          'eyes see "completely different." Side-by-side comparison '
          'with CIEDE2000 — the same formula the CIE designed to fix '
          'this.',
      route = '/quiz',
      accent = const Color(0xFF3B82F6);

  final String title;
  final String subtitle;
  final String body;
  final String route;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pushNamed(route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              body,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.55,
              ),
            ),
            const Spacer(),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(
                  'Open demo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16, color: accent),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'BSD-3 licensed · port of Python colormath',
        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
      ),
    );
  }
}
