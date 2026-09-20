import 'package:flutter/material.dart';

class NeonCard extends StatelessWidget {
  const NeonCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final EdgeInsets padding;
  @override Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: const Color(0xE81B2435),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0x553B82F6)),
      boxShadow: const [BoxShadow(color: Color(0x332563EB), blurRadius: 22)],
    ),
    child: child,
  );
}

class CoinBadge extends StatelessWidget {
  const CoinBadge({super.key, required this.coins});
  final int coins;
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: const Color(0xFF202C42), borderRadius: BorderRadius.circular(18)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Image.asset('assets/images/ui/coin.png', width: 22, height: 22),
      const SizedBox(width: 6),
      Text(_fmt(coins), style: const TextStyle(fontWeight: FontWeight.w800)),
    ]),
  );
  String _fmt(int n) => n >= 1000000 ? '${(n/1000000).toStringAsFixed(1)}M' : n >= 1000 ? '${(n/1000).toStringAsFixed(n >= 100000 ? 0 : 1)}K' : '$n';
}

class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.label, required this.onPressed, this.icon, this.compact = false});
  final String label; final VoidCallback? onPressed; final IconData? icon; final bool compact;
  @override Widget build(BuildContext context) => Opacity(
    opacity: onPressed == null ? .45 : 1,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF7C3AED)]),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, color: Colors.white),
        label: Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 6 : 18, vertical: compact ? 8 : 13),
          child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: .5)),
        ),
      ),
    ),
  );
}
