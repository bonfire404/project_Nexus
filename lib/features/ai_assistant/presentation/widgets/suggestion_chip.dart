import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class SuggestionChip extends StatelessWidget {
  const SuggestionChip({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.isHugeIcon = true,
  });

  final String label;
  final dynamic icon;
  final VoidCallback onTap;
  final bool isHugeIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                isHugeIcon
                    ? HugeIcon(
                        icon: icon,
                        size: 16,
                        color: theme.colorScheme.primary,
                      )
                    : Icon(
                        icon,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}