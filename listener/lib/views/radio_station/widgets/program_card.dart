import 'package:flutter/material.dart';
import '../../../core/models/program.dart';
import '../../../core/constants/app_colors.dart';

class ProgramCard extends StatefulWidget {
  final Program program;
  final bool isFavourite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavourite;

  const ProgramCard({
    Key? key,
    required this.program,
    required this.isFavourite,
    required this.onTap,
    required this.onToggleFavourite,
  }) : super(key: key);

  @override
  State<ProgramCard> createState() => _ProgramCardState();
}

class _ProgramCardState extends State<ProgramCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.program;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 120,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _hover
                  ? AppColors.primary.withOpacity(0.35)
                  : AppColors.border,
            ),
            boxShadow: _hover
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster image
              Stack(
                children: [
                  Container(
                    height: 70,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(9)),
                      image: p.imageUrl != null && p.imageUrl!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(p.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (p.imageUrl == null || p.imageUrl!.isEmpty)
                        ? Center(
                            child: Icon(Icons.radio,
                                size: 22,
                                color: AppColors.primary.withOpacity(0.4)),
                          )
                        : null,
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: widget.onToggleFavourite,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isFavourite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          size: 13,
                          color: widget.isFavourite
                              ? AppColors.error
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (p.hostNames.isNotEmpty)
                      Text(
                        p.hostNames.join(', '),
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    if (p.categories.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          p.categories.first,
                          style: const TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
