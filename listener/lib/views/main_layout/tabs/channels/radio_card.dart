import 'package:flutter/material.dart';
import '../../../../core/models/radio_model.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/safe_image.dart';

class RadioCard extends StatefulWidget {
  final RadioModel radio;
  final VoidCallback onTap;
  final VoidCallback onToggleFollow;
  final bool compact;
  final String? reason;

  const RadioCard({
    Key? key,
    required this.radio,
    required this.onTap,
    required this.onToggleFollow,
    this.compact = false,
    this.reason,
  }) : super(key: key);

  @override
  State<RadioCard> createState() => _State();
}

class _State extends State<RadioCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.radio;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: widget.compact
              ? const EdgeInsets.all(12)
              : const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(widget.compact ? 16 : 12),
            border: Border.all(
              color: r.isLive
                  ? AppColors.error.withOpacity(0.5)
                  : (_hover
                      ? AppColors.primary.withOpacity(0.35)
                      : AppColors.border),
              width: r.isLive ? 1.5 : 1,
            ),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: widget.compact ? _compact(r) : _full(r),
        ),
      ),
    );
  }

  // ============ COMPACT (carousels) ============

  Widget _compact(RadioModel r) {
    return Row(
      children: [
        _logo(size: 64, radius: 14),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (r.isVerified)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.verified,
                          size: 14, color: AppColors.primary),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                r.description,
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (r.isLive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          _LiveDot(),
                          SizedBox(width: 4),
                          Text('LIVE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Icon(Icons.headphones,
                      size: 11, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Text(_fmt(r.listenerCount),
                      style: const TextStyle(
                          fontSize: 10.5, color: AppColors.textMuted)),
                ],
              ),
              if (widget.reason != null && widget.reason!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 10, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          widget.reason!,
                          style: const TextStyle(
                            fontSize: 10.5,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Follow heart
        IconButton(
          onPressed: widget.onToggleFollow,
          icon: Icon(
            r.isFollowed ? Icons.favorite : Icons.favorite_border,
            size: 18,
            color: r.isFollowed ? AppColors.error : AppColors.textMuted,
          ),
          tooltip: r.isFollowed ? 'Unfollow' : 'Follow',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  // ============ FULL (grid) ============

  Widget _full(RadioModel r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo — centered, compact
        Stack(
          clipBehavior: Clip.none,
          children: [
            _logo(size: 46, radius: 10),
            // Live badge
            if (r.isLive)
              Positioned(
                top: -3,
                right: -3,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      _LiveDot(),
                      SizedBox(width: 3),
                      Text('LIVE',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3)),
                    ],
                  ),
                ),
              ),
            // Verified check
            if (r.isVerified)
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 1.5),
                  ),
                  child: const Icon(Icons.check,
                      size: 8, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Name
        Text(
          r.name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),

        // Description
        Text(
          r.description,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 9.5, color: AppColors.textSecondary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),

        // Bottom row: listeners + category
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.headphones,
                size: 9, color: AppColors.textMuted),
            const SizedBox(width: 2),
            Text(_fmt(r.listenerCount),
                style: const TextStyle(
                    fontSize: 9, color: AppColors.textMuted)),
            if (r.categories.isNotEmpty) ...[
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  r.primaryCategory[0].toUpperCase() +
                      r.primaryCategory.substring(1),
                  style: const TextStyle(
                      fontSize: 8,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),

        if (widget.reason != null && widget.reason!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, size: 8, color: AppColors.primary),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    widget.reason!,
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],

        const Spacer(),

        // Follow button
        SizedBox(
          width: double.infinity,
          child: _followButton(r, compact: true),
        ),
      ],
    );
  }

  // ============ LOGO WIDGET ============

  Widget _logo({required double size, required double radius}) {
    final r = widget.radio;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeImage(
        imageUrl: r.logoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        fallback: _logoFallback(r, size),
      ),
    );
  }

  Widget _logoFallback(RadioModel r, [double size = 64]) {
    final initial = r.name.trim().isNotEmpty ? r.name.trim()[0].toUpperCase() : '📻';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: (size * 0.42).clamp(16.0, 36.0),
          fontWeight: FontWeight.w800,
          color: AppColors.primary,
        ),
      ),
    );
  }

  // ============ FOLLOW BUTTON ============

  Widget _followButton(RadioModel r, {bool compact = false}) {
    if (compact) {
      return SizedBox(
        height: 24,
        child: r.isFollowed
            ? OutlinedButton(
                onPressed: widget.onToggleFollow,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary, width: 1),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Following',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600)),
              )
            : ElevatedButton(
                onPressed: widget.onToggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('Follow',
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600)),
              ),
      );
    }
    return r.isFollowed
        ? OutlinedButton.icon(
            onPressed: widget.onToggleFollow,
            icon: const Icon(Icons.check, size: 14),
            label: const Text('Following'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          )
        : ElevatedButton.icon(
            onPressed: widget.onToggleFollow,
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Follow'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_c),
        child: Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      );
}
