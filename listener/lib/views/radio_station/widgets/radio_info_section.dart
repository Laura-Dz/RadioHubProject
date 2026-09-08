import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../../core/models/radio_model.dart';
import '../../../core/theme/app_colors.dart';

class RadioInfoSection extends StatefulWidget {
  final RadioModel radio;
  final VoidCallback onViewSchedule;
  final VoidCallback onViewPrograms;
  final VoidCallback onRequestAnnouncement;

  const RadioInfoSection({
    Key? key,
    required this.radio,
    required this.onViewSchedule,
    required this.onViewPrograms,
    required this.onRequestAnnouncement,
  }) : super(key: key);

  @override
  State<RadioInfoSection> createState() => _RadioInfoSectionState();
}

class _RadioInfoSectionState extends State<RadioInfoSection> {
  int _currentImageIndex = 0;
  final CarouselSliderController _carouselController = CarouselSliderController();

  @override
  Widget build(BuildContext context) {
    final radio = widget.radio;
    final images = radio.bannerImageUrl != null ? [radio.bannerImageUrl!] : <String>[];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('About this Radio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: images.isEmpty
                    ? _buildPlaceholderBanner()
                    : CarouselSlider(
                        carouselController: _carouselController,
                        options: CarouselOptions(
                          height: 160,
                          autoPlay: true,
                          autoPlayInterval: const Duration(seconds: 4),
                          autoPlayAnimationDuration: const Duration(milliseconds: 800),
                          enlargeCenterPage: true,
                          viewportFraction: 0.9,
                          onPageChanged: (index, _) => setState(() => _currentImageIndex = index),
                        ),
                        items: images.map((url) => Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
                          ),
                        )).toList(),
                      ),
              ),
              if (images.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: images.asMap().entries.map((entry) {
                    return Container(
                      width: _currentImageIndex == entry.key ? 20 : 8,
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: _currentImageIndex == entry.key ? AppColors.primary : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Text(radio.description, style: TextStyle(fontSize: 14, height: 1.5)),
          const SizedBox(height: 12),
          if (radio.hosts.isNotEmpty) ...[
            const Text('🎙️ Hosts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: radio.hosts.map((host) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(host, style: TextStyle(fontSize: 13, color: AppColors.primary)),
              )).toList(),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              if (radio.foundedDate != null) ...[
                Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Founded ${radio.foundedDate!.year}', style: TextStyle(fontSize: 13, color: Colors.grey)),
                const SizedBox(width: 12),
              ],
              if (radio.location != null) ...[
                Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(radio.location!, style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (radio.tags.isNotEmpty) ...[
            Wrap(
              spacing: 4,
              children: radio.tags.map((tag) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('#$tag', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              )).toList(),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onViewSchedule,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: const Text('View Schedule'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onViewPrograms,
                  icon: const Icon(Icons.list_alt, size: 18),
                  label: const Text('View Programs'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onRequestAnnouncement,
              icon: const Icon(Icons.mic),
              label: const Text('📢 Request Announcement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderBanner() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.7), AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.radio, size: 48, color: Colors.white70),
      ),
    );
  }
}
