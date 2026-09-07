import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/technician_view_model.dart';

class MediaSection extends StatelessWidget {
  const MediaSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<TechnicianViewModel>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('📁 Media Library',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => viewModel.refreshData(),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: viewModel.media.isEmpty
                ? const Center(child: Text('No media items yet. Upload audio/video content here.'))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: viewModel.media.length,
                    itemBuilder: (context, index) {
                      final m = viewModel.media[index];
                      IconData icon;
                      switch (m.mediaType) {
                        case 'video':
                          icon = Icons.movie;
                          break;
                        case 'podcast':
                          icon = Icons.podcasts;
                          break;
                        default:
                          icon = Icons.audiotrack;
                      }
                      return Card(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, size: 48, color: Colors.blue),
                            const SizedBox(height: 8),
                            Text(
                              m.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(m.mediaType, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                            Text('${m.playCount} plays', style: const TextStyle(fontSize: 11)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                              onPressed: () => viewModel.deleteMedia(m.id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
