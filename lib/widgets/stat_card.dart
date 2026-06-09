import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String  label;
  final String  value;
  final IconData icon;
  final Color   iconColor;
  final Color   borderColor;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.borderColor,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF162032) : Colors.white;
    final border  = isDark ? const Color(0xFF1E3048) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0,4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 14),
          Text(value, style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A),
          )),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(
            fontSize: 12, color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          )),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(Icons.circle, size: 7, color: borderColor),
              const SizedBox(width: 5),
              Text(subtitle!, style: TextStyle(fontSize: 11, color: borderColor)),
            ]),
          ],
          const SizedBox(height: 4),
          Container(height: 3, decoration: BoxDecoration(
            color: borderColor,
            borderRadius: BorderRadius.circular(10),
          )),
        ],
      ),
    );
  }
}