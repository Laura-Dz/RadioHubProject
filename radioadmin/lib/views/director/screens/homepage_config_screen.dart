import 'package:flutter/material.dart';
import '../../../core/models/director/homepage_config_model.dart';

class HomepageConfigScreen extends StatelessWidget {
  final HomepageConfig? config;
  final Future<void> Function(HomepageConfig) onSave;
  final Future<void> Function(String, Map<String, dynamic>) onUpdateSection;

  const HomepageConfigScreen({
    Key? key,
    this.config,
    required this.onSave,
    required this.onUpdateSection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (config == null) {
      return const Center(child: Text('No homepage configuration found.'));
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🏠 Homepage Configuration', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: config!.sections.length,
              itemBuilder: (context, index) {
                final section = config!.sections[index];
                return Card(
                  child: SwitchListTile(
                    title: Text(section.title),
                    subtitle: Text(section.type),
                    value: section.isVisible,
                    onChanged: (value) {
                      onUpdateSection(section.id, {'isVisible': value});
                    },
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
