import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carousel_slider/carousel_slider.dart';

import '../../../view_models/radio_station_view_model.dart';
import '../../../core/constants/app_colors.dart';

class AboutSection extends StatefulWidget {
  const AboutSection({Key? key}) : super(key: key);

  @override
  State<AboutSection> createState() => _State();
}

class _State extends State<AboutSection> {
  int _carouselIndex = 0;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioStationViewModel>();
    final r = vm.radio!;

    final images = <String>[
      if (r.bannerUrl != null && r.bannerUrl!.isNotEmpty) r.bannerUrl!,
      if (r.logoUrl != null && r.logoUrl!.isNotEmpty) r.logoUrl!,
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: const [
              Icon(Icons.info_outline,
                  size: 18, color: AppColors.primary),
              SizedBox(width: 8),
              Text('About this radio',
                  style: TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),

          // Image carousel
          if (images.isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 160,
                  autoPlay: true,
                  autoPlayInterval: const Duration(seconds: 4),
                  autoPlayAnimationDuration:
                      const Duration(milliseconds: 800),
                  enlargeCenterPage: true,
                  viewportFraction: 0.9,
                  onPageChanged: (i, _) =>
                      setState(() => _carouselIndex = i),
                ),
                items: images.map((url) {
                  return Builder(
                    builder: (_) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(url),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: images.asMap().entries.map((e) {
                final active = _carouselIndex == e.key;
                return Container(
                  width: active ? 20 : 6,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.primary
                        : AppColors.textMuted.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
          ],

          // Description
          Text(r.description,
              style: const TextStyle(
                  fontSize: 13.5, color: AppColors.textPrimary, height: 1.5)),
          const SizedBox(height: 16),

          // Meta chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (r.categories.isNotEmpty)
                ...r.categories.map((c) => _chip(
                      icon: Icons.local_offer_outlined,
                      label: c[0].toUpperCase() + c.substring(1),
                    )),
              if (r.language.isNotEmpty)
                _chip(
                    icon: Icons.translate,
                    label: r.language.toUpperCase()),
              if (r.city != null && r.city!.isNotEmpty)
                _chip(icon: Icons.location_on_outlined, label: r.city!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
