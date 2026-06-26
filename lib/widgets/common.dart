import 'package:flutter/material.dart';

// ── Colors ──────────────────────────────────
const kBg       = Color(0xFF0B1020);
const kPanel    = Color(0xFF111827);
const kPanel2   = Color(0xFF0F172A);
const kBorder   = Color(0xFF1E2D45);
const kText     = Color(0xFFE2E8F0);
const kMuted    = Color(0xFF64748B);
const kAccent   = Color(0xFF7C3AED);
const kAccent2  = Color(0xFF38BDF8);
const kSuccess  = Color(0xFF22C55E);
const kDanger   = Color(0xFFEF4444);
const kWarning  = Color(0xFFF59E0B);

// ── GSection ────────────────────────────────
class GSection extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  const GSection({super.key, required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
      if (subtitle != null) ...[
        const SizedBox(height: 3),
        Text(subtitle!, style: const TextStyle(fontSize: 11, color: kMuted)),
      ],
      const SizedBox(height: 14),
      child,
    ]);
  }
}

// ── GCard ───────────────────────────────────
class GCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const GCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: child,
    );
  }
}

// ── GCardTitle ──────────────────────────────
class GCardTitle extends StatelessWidget {
  final String text;
  const GCardTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
          letterSpacing: 1.5, color: kMuted)),
    );
  }
}

// ── GBtn ────────────────────────────────────
class GBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final Color textColor;
  final bool fullWidth;
  final IconData? icon;

  const GBtn({
    super.key,
    required this.label,
    required this.onTap,
    this.color = kAccent,
    this.textColor = Colors.white,
    this.fullWidth = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 15, color: textColor), const SizedBox(width: 6)],
              Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w700, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

// ── GInput ──────────────────────────────────
class GInput extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscure;
  final VoidCallback? onBrowse;
  const GInput({super.key, required this.label, this.hint, this.controller, this.obscure = false, this.onBrowse});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 11, color: kMuted, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Row(children: [
        Expanded(
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(color: kText, fontSize: 12),
            decoration: InputDecoration(hintText: hint, isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
          ),
        ),
        if (onBrowse != null) ...[
          const SizedBox(width: 8),
          GBtn(label: 'Browse', onTap: onBrowse!, color: kPanel2),
        ],
      ]),
      const SizedBox(height: 12),
    ]);
  }
}

// ── GLogBox ─────────────────────────────────
class GLogBox extends StatelessWidget {
  final String log;
  const GLogBox(this.log, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kPanel2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: SelectableText(
        log.isEmpty ? 'No output yet.' : log,
        style: const TextStyle(fontFamily: 'Consolas', fontSize: 11,
          color: kText, height: 1.7),
      ),
    );
  }
}

// ── GPathBox ────────────────────────────────
class GPathBox extends StatelessWidget {
  final String path;
  const GPathBox(this.path, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kPanel2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorder),
      ),
      child: Text(path,
        style: const TextStyle(fontFamily: 'Consolas', fontSize: 10, color: kAccent2)),
    );
  }
}

// ── GDivider ────────────────────────────────
class GDivider extends StatelessWidget {
  const GDivider({super.key});
  @override
  Widget build(BuildContext context) =>
    const Divider(color: kBorder, height: 28);
}

// ── GBadge ──────────────────────────────────
class GBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  const GBadge(this.text, {super.key, this.color = kBorder, this.textColor = kMuted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: textColor)),
    );
  }
}

// ── Screen wrapper ──────────────────────────
class GScreen extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;

  const GScreen({super.key, required this.title, this.subtitle, required this.child, this.actions});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF080D19),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: kMuted),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 16)),
          if (subtitle != null)
            Text(subtitle!, style: const TextStyle(color: kMuted, fontSize: 10)),
        ]),
        actions: actions,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kBorder),
        ),
      ),
      body: child,
    );
  }
}
