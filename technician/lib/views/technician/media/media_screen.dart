import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/technician/media_item_model.dart';
import '../../../view_models/technician_view_model.dart';

class MediaScreen extends StatefulWidget {
  const MediaScreen({Key? key}) : super(key: key);

  @override
  State<MediaScreen> createState() => _MediaScreenState();
}

class _MediaScreenState extends State<MediaScreen> {
  String _search = '';
  MediaType? _filterType;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TechnicianViewModel>();
    final items = vm.mediaItems.where((m) {
      if (_filterType != null && m.type != _filterType) return false;
      if (_search.isNotEmpty && !m.name.toLowerCase().contains(_search.toLowerCase())) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Media Library',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Upload media functionality ready.')),
                    );
                  },
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Upload Media'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Filter row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 20),
                      hintText: 'Search audio, podcasts, videos...',
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<MediaType?>(
                  value: _filterType,
                  hint: const Text('All Types'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Types')),
                    ...MediaType.values.map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.name[0].toUpperCase() + t.name.substring(1)),
                        )),
                  ],
                  onChanged: (v) => setState(() => _filterType = v),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.perm_media_outlined, size: 48, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text('No media items found',
                              style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) {
                        final m = items[i];
                        return Card(
                          color: AppColors.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      m.type == MediaType.video
                                          ? Icons.videocam
                                          : m.type == MediaType.podcast
                                              ? Icons.podcasts
                                              : Icons.audiotrack,
                                      color: AppColors.primary,
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceAlt,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(m.typeLabel,
                                          style: const TextStyle(
                                              fontSize: 11, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                                const Spacer(),
                                Text(
                                  m.name,
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  m.durationDisplay,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
