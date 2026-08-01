import 'package:flutter/material.dart';

class AssistantAvatar extends StatelessWidget {
  const AssistantAvatar({
    super.key,
    this.radius = 18,
    this.showOnlineBadge = true,
  });

  final double radius;
  final bool showOnlineBadge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = radius * 2;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Image.asset(
              'assets/icons/app_logo.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          ),
        ),
        if (showOnlineBadge)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: radius * 0.55,
              height: radius * 0.55,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.colorScheme.surface,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}