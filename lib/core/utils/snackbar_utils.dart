import 'dart:ui';
import 'package:flutter/material.dart';

enum SnackbarType { info, success, error, warning }

void showGlassSnackbar(
  BuildContext context,
  String message, {
  SnackbarType type = SnackbarType.info,
}) {
  final overlay = Overlay.of(context);
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (context) {
      final theme = Theme.of(context);
      final isLight = theme.brightness == Brightness.light;
      final blurSigma = isLight ? 6.0 : 12.0;
      final bgAlpha = isLight ? 0.4 : 0.6;

      IconData iconData;
      Color iconColor;

      switch (type) {
        case SnackbarType.success:
          iconData = Icons.check_circle_outline;
          iconColor = Colors.green.shade600;
          break;
        case SnackbarType.error:
          iconData = Icons.error_outline;
          iconColor = Colors.redAccent;
          break;
        case SnackbarType.warning:
          iconData = Icons.warning_amber_rounded;
          iconColor = Colors.orange.shade600;
          break;
        case SnackbarType.info:
        default:
          iconData = Icons.info_outline;
          iconColor = theme.colorScheme.primary;
          break;
      }

      return Positioned(
        top: MediaQuery.of(context).padding.top + 4,
        left: 24,
        right: 24,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -150 * (1 - value)),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: bgAlpha),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(iconData, size: 18, color: iconColor),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  overlay.insert(entry);

  Future.delayed(const Duration(seconds: 3), () {
    if (entry.mounted) {
      entry.remove();
    }
  });
}
