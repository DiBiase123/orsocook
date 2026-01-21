import 'package:flutter/material.dart';

/// Bottone menu azioni con ombra ed animazioni eleganti
class ActionMenuButton extends StatefulWidget {
  final List<PopupMenuEntry<String>> menuItems;
  final void Function(String)? onSelected;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const ActionMenuButton({
    super.key,
    required this.menuItems,
    this.onSelected,
    this.backgroundColor,
    this.iconColor,
    this.size = 32,
  });

  @override
  State<ActionMenuButton> createState() => _ActionMenuButtonState();
}

class _ActionMenuButtonState extends State<ActionMenuButton> {
  double _scale = 1.0;

  void _onTapDown() {
    setState(() => _scale = 0.95);
  }

  void _onTapUp() {
    setState(() => _scale = 1.0);
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundColor =
        widget.backgroundColor ?? colorScheme.secondaryContainer;
    final iconColor = widget.iconColor ?? colorScheme.onSecondaryContainer;

    return GestureDetector(
      onTapDown: (_) => _onTapDown(),
      onTapUp: (_) => _onTapUp(),
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(
                  (colorScheme.primary.r * 255.0).round().clamp(0, 255),
                  (colorScheme.primary.g * 255.0).round().clamp(0, 255),
                  (colorScheme.primary.b * 255.0).round().clamp(0, 255),
                  0.15,
                ),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Color.fromRGBO(
                  (colorScheme.secondary.r * 255.0).round().clamp(0, 255),
                  (colorScheme.secondary.g * 255.0).round().clamp(0, 255),
                  (colorScheme.secondary.b * 255.0).round().clamp(0, 255),
                  0.1,
                ),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: PopupMenuButton<String>(
            icon: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Color.fromRGBO(
                    (colorScheme.outline.r * 255.0).round().clamp(0, 255),
                    (colorScheme.outline.g * 255.0).round().clamp(0, 255),
                    (colorScheme.outline.b * 255.0).round().clamp(0, 255),
                    0.3,
                  ),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.more_vert_rounded,
                size: widget.size * 0.56, // 18 per size=32
                color: iconColor,
              ),
            ),
            onSelected: widget.onSelected,
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            itemBuilder: (context) => widget.menuItems,
          ),
        ),
      ),
    );
  }
}
