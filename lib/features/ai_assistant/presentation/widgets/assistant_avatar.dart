import 'package:flutter/material.dart';

class AssistantAvatar extends StatelessWidget {
  const AssistantAvatar({
    super.key,
    this.radius = 20,
  });

  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: const Icon(
        Icons.smart_toy_rounded,
        color: Colors.white,
      ),
    );
  }
}