import 'package:flutter/material.dart';

// Graystone palette.
const kBg = Color(0xFF0B1020);
const kSurface = Color(0xFF111827);
const kSurface2 = Color(0xFF0F172A);
const kBorder = Color(0xFF1E2D45);
const kPrimary = Color(0xFF7C3AED);
const kAccent = Color(0xFF38BDF8);
const kText = Color(0xFFE2E8F0);
const kMuted = Color(0xFF64748B);
const kWarning = Color(0xFFF59E0B);
const kError = Color(0xFFF87171);
const kSuccess = Color(0xFF34D399);

/// Wide layouts (tablet/desktop) vs narrow (phone). Used everywhere for
/// responsive behaviour so the UI adapts to any screen size.
bool isWide(BuildContext context) => MediaQuery.sizeOf(context).width >= 800;

/// A centered message with an icon and optional action — used for empty and
/// error states.
class GMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color? color;

  const GMessage({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: color ?? kMuted),
              const SizedBox(height: 16),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(subtitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: kMuted, height: 1.4)),
              ],
              if (action != null) ...[
                const SizedBox(height: 20),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
