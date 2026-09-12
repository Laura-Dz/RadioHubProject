import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/widgets/common_widgets.dart';

class SettingsTab extends StatelessWidget {
  final String radioId;

  const SettingsTab({Key? key, required this.radioId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: RadioAdminColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Configure your radio station',
            style: TextStyle(
              fontSize: 14,
              color: RadioAdminColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    'Station Details',
                    Icons.radio,
                    [
                      _buildTextField('Station Name', 'Enter station name', 'Radio Station'),
                      _buildTextField('Description', 'Enter station description', 'Your radio station description'),
                      _buildTextField('Website', 'https://', 'https://yourstation.com'),
                      _buildTextField('Contact Email', 'contact@station.com', 'contact@station.com'),
                      _buildTextField('Phone', '+1 (555) 000-0000', '+1 (555) 000-0000'),
                      _buildTextField('Location', 'City, Country', 'New York, USA'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildSection(
                    'Branding',
                    Icons.palette,
                    [
                      _buildImageUpload('Logo', 'Upload station logo'),
                      const SizedBox(height: 12),
                      _buildImageUpload('Cover Image', 'Upload cover image'),
                      const SizedBox(height: 12),
                      _buildImageUpload('Banner Image', 'Upload banner image'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildSection(
                    'Stream Settings',
                    Icons.stream,
                    [
                      _buildTextField('Stream URL', 'https://stream.station.com/live', 'https://stream.station.com/live.m3u8'),
                      _buildDropdown('Stream Format', ['HLS', 'MP3', 'AAC'], 'HLS'),
                      _buildDropdown('Bitrate', ['128 kbps', '192 kbps', '256 kbps', '320 kbps'], '128 kbps'),
                      _buildSwitch('Enable Auto-Play', true, 'Automatically play stream when listener visits'),
                      _buildSwitch('Enable Recording', false, 'Automatically record live sessions'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildSection(
                    'Social Links',
                    Icons.link,
                    [
                      _buildTextField('Facebook', 'https://facebook.com', 'https://facebook.com/yourstation'),
                      _buildTextField('Twitter/X', 'https://x.com', 'https://x.com/yourstation'),
                      _buildTextField('Instagram', 'https://instagram.com', 'https://instagram.com/yourstation'),
                      _buildTextField('YouTube', 'https://youtube.com', 'https://youtube.com/yourstation'),
                      _buildTextField('Website', 'https://yourstation.com', 'https://yourstation.com'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildSection(
                    'Categories & Tags',
                    Icons.tag,
                    [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Music', 'Talk', 'News', 'Sports', 'Comedy', 'Education', 'Religious'
                        ].map((tag) => FilterChip(
                          label: Text(tag),
                          selected: false,
                          onSelected: (_) {},
                          backgroundColor: RadioAdminColors.primary.withOpacity(0.1),
                        )).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildSection(
                    'Notifications',
                    Icons.notifications,
                    [
                      _buildSwitch('Email Notifications', true, 'Receive email notifications'),
                      _buildSwitch('Push Notifications', true, 'Receive push notifications'),
                      _buildSwitch('Live Alerts', true, 'Notify when session goes live'),
                      _buildSwitch('New Session Reminders', true, 'Remind before scheduled sessions'),
                      _buildSwitch('Weekly Reports', false, 'Send weekly analytics report'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildSection(
                    'Privacy & Security',
                    Icons.security,
                    [
                      _buildSwitch('Public Profile', true, 'Station visible in public directory'),
                      _buildSwitch('Allow Comments', true, 'Allow listeners to comment on sessions'),
                      _buildSwitch('Analytics Sharing', false, 'Share anonymized analytics with platform'),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RadioAdminColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Save Changes'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                 ],
               ),
             ),
           ),
         ],
       ),
     );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: RadioAdminColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RadioAdminColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: RadioAdminColors.primary, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: RadioAdminColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(children: children),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String hint, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: RadioAdminColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: RadioAdminColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: RadioAdminColors.primary, width: 2),
          ),
          filled: true,
          fillColor: RadioAdminColors.cardBackground,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: RadioAdminColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: RadioAdminColors.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: RadioAdminColors.primary, width: 2),
          ),
          filled: true,
          fillColor: RadioAdminColors.cardBackground,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        items: options.map((option) {
          return DropdownMenuItem(value: option, child: Text(option));
        }).toList(),
        onChanged: (_) {},
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: RadioAdminColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11,
            color: RadioAdminColors.textSecondary,
          ),
        ),
        value: value,
        onChanged: (_) {},
        activeColor: RadioAdminColors.primary,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildImageUpload(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: RadioAdminColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: RadioAdminColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: RadioAdminColors.divider,
              style: BorderStyle.solid,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload, size: 32, color: RadioAdminColors.textSecondary),
                const SizedBox(height: 8),
                Text(
                  'Click to upload',
                  style: TextStyle(
                    color: RadioAdminColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hint,
                  style: TextStyle(
                    fontSize: 11,
                    color: RadioAdminColors.textSecondary.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}