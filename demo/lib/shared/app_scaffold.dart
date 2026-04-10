import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared page scaffold: top bar with logo + external links, max-width
/// content area, consistent background.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.showBack = true,
  });

  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(showBack: showBack),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 48),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 960),
                    child: child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.showBack});
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FB),
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEF2F7), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Logo → home
          InkWell(
            onTap: () => Navigator.of(context).pushReplacementNamed('/'),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFE63946),
                          Color(0xFFF1FAEE),
                          Color(0xFF457B9D),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'chromatic',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showBack) ...[
            const SizedBox(width: 10),
            Container(
              width: 1,
              height: 18,
              color: const Color(0xFFE2E8F0),
            ),
            const SizedBox(width: 10),
            TextButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushReplacementNamed('/'),
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('home'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 32),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const Spacer(),
          _LinkButton(
            icon: Icons.inventory_2_outlined,
            label: 'pub.dev',
            url: 'https://pub.dev/packages/chromatic',
          ),
          const SizedBox(width: 4),
          _LinkButton(
            icon: Icons.code,
            label: 'GitHub',
            url: 'https://github.com/Enraio/chromatic',
          ),
        ],
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.icon,
    required this.label,
    required this.url,
  });

  final IconData icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => launchUrl(Uri.parse(url)),
      icon: Icon(icon, size: 15),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF334155),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 36),
        textStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
