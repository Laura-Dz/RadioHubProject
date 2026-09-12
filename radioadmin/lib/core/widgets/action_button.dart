import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? foregroundColor;
  final String? tooltip;
  final bool isLoading;
  final bool outlined;

  const ActionButton({
    Key? key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.color,
    this.foregroundColor,
    this.tooltip,
    this.isLoading = false,
    this.outlined = false,
  }) : super(key: key);

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final btn = MouseRegion(
      cursor: widget.onPressed != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered && widget.onPressed != null ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: widget.outlined
            ? OutlinedButton.icon(
                onPressed: widget.isLoading ? null : widget.onPressed,
                icon: widget.isLoading
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: widget.color ?? AppColors.primary,
                        ),
                      )
                    : Icon(widget.icon, size: 16),
                label: Text(widget.label),
                style: OutlinedButton.styleFrom(
                  foregroundColor: widget.color ?? AppColors.primary,
                  side: BorderSide(color: widget.color ?? AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )
            : ElevatedButton.icon(
                onPressed: widget.isLoading ? null : widget.onPressed,
                icon: widget.isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(widget.icon, size: 16),
                label: Text(widget.label),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color ?? AppColors.primary,
                  foregroundColor: widget.foregroundColor ?? Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
      ),
    );
    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: btn);
    }
    return btn;
  }
}
