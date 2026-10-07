import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/app_file_picker.dart';
import '../../../core/services/storage_service.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/radio_admin/radio_profile_model.dart';

class RadioPageEditorScreen extends StatefulWidget {
  const RadioPageEditorScreen({Key? key}) : super(key: key);

  @override
  State<RadioPageEditorScreen> createState() => _RadioPageEditorScreenState();
}

class _RadioPageEditorScreenState extends State<RadioPageEditorScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _name;
  late TextEditingController _description;
  late TextEditingController _function;
  late TextEditingController _vision;
  late TextEditingController _mission;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _website;
  late TextEditingController _location;
  late TextEditingController _tagCtrl;

  String? _logoUrl;
  String? _bannerUrl;
  bool _uploadingLogo = false;
  bool _uploadingBanner = false;
  double _logoProgress = 0.0;
  double _bannerProgress = 0.0;

  String _language = 'French';
  List<String> _tags = [];
  bool _saving = false;
  bool _isInitializedFromProfile = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<RadioAdminViewModel>().radioProfile;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    _function = TextEditingController(text: p?.function ?? '');
    _vision = TextEditingController(text: p?.vision ?? '');
    _mission = TextEditingController(text: p?.mission ?? '');
    _email = TextEditingController(text: p?.contactEmail ?? '');
    _phone = TextEditingController(text: p?.contactPhone ?? '');
    _website = TextEditingController(text: p?.website ?? '');
    _location = TextEditingController(text: p?.location ?? '');
    _tagCtrl = TextEditingController();

    _logoUrl = p?.logoUrl;
    _bannerUrl = p?.bannerUrl;

    _language = p?.language ?? 'French';
    _tags = List.from(p?.tags ?? ['Music', 'News']);
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _function.dispose();
    _vision.dispose();
    _mission.dispose();
    _email.dispose();
    _phone.dispose();
    _website.dispose();
    _location.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo() async {
    if (_uploadingLogo) return;

    try {
      final file = await AppFilePicker.pickImage();
      if (file == null) return; // user cancelled file picker

      // Validate file size (< 5 MB)
      if (file.size > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image is too large (max 5 MB). Please choose another.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      setState(() {
        _uploadingLogo = true;
        _logoProgress = 0.0;
      });

      final prevLogoUrl = _logoUrl;
      final vm = context.read<RadioAdminViewModel>();

      try {
        final url = await vm.uploadLogo(
          file.toXFile(),
          onProgress: (p) {
            if (mounted) setState(() => _logoProgress = p);
          },
        );

        if (mounted) {
          setState(() {
            _logoUrl = url;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Logo uploaded to Storage and linked to database!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e, stack) {
        debugPrint('Logo upload error: $e\n$stack');

        // Resilience fallback: If Cloud Storage is not provisioned or blocked by CORS,
        // store the image directly in Firestore as a Data URI if under 800 KB
        if (file.bytes.lengthInBytes <= 800 * 1024) {
          try {
            final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'png';
            final mime = (ext == 'jpg' || ext == 'jpeg') ? 'image/jpeg' : (ext == 'webp' ? 'image/webp' : 'image/png');
            final dataUri = 'data:$mime;base64,${base64Encode(file.bytes)}';

            await vm.setLogoUrl(dataUri);
            if (mounted) {
              setState(() {
                _logoUrl = dataUri;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logo saved to station profile! (Saved directly to database)'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 4),
                ),
              );
            }
            return;
          } catch (dbErr) {
            debugPrint('Firestore fallback error: $dbErr');
          }
        }

        if (mounted) {
          setState(() {
            _logoUrl = prevLogoUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'Enter URL',
                textColor: Colors.white,
                onPressed: _enterLogoUrlDialog,
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _uploadingLogo = false;
            _logoProgress = 0.0;
          });
        }
      }
    } catch (pickerError, stack) {
      debugPrint('File picker error: $pickerError\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file explorer: $pickerError'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Paste URL',
              textColor: Colors.white,
              onPressed: _enterLogoUrlDialog,
            ),
          ),
        );
      }
    }
  }

  Future<void> _enterLogoUrlDialog() async {
    final ctrl = TextEditingController(text: _logoUrl ?? '');
    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link Station Logo URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a direct public image URL (PNG, JPG, WEBP):',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'https://example.com/logo.png',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Save Link'),
          ),
        ],
      ),
    );

    if (confirmed != null && confirmed.isNotEmpty) {
      try {
        await context.read<RadioAdminViewModel>().setLogoUrl(confirmed);
        if (mounted) {
          setState(() => _logoUrl = confirmed);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logo link saved to database!'), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save URL: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  Future<void> _pickAndUploadBanner() async {
    if (_uploadingBanner) return;

    try {
      final file = await AppFilePicker.pickImage();
      if (file == null) return; // user cancelled file picker

      // Validate file size (< 5 MB)
      if (file.size > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image is too large (max 5 MB). Please choose another.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      setState(() {
        _uploadingBanner = true;
        _bannerProgress = 0.0;
      });

      final prevBannerUrl = _bannerUrl;
      final vm = context.read<RadioAdminViewModel>();

      try {
        final url = await vm.uploadBanner(
          file.toXFile(),
          onProgress: (p) {
            if (mounted) setState(() => _bannerProgress = p);
          },
        );

        if (mounted) {
          setState(() {
            _bannerUrl = url;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Banner uploaded to Storage and linked to database!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e, stack) {
        debugPrint('Banner upload error: $e\n$stack');

        // Resilience fallback: If Cloud Storage is not provisioned or blocked by CORS,
        // store the banner directly in Firestore as a Data URI if under 800 KB
        if (file.bytes.lengthInBytes <= 800 * 1024) {
          try {
            final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'png';
            final mime = (ext == 'jpg' || ext == 'jpeg') ? 'image/jpeg' : (ext == 'webp' ? 'image/webp' : 'image/png');
            final dataUri = 'data:$mime;base64,${base64Encode(file.bytes)}';

            await vm.setBannerUrl(dataUri);
            if (mounted) {
              setState(() {
                _bannerUrl = dataUri;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Banner saved to station profile! (Saved directly to database)'),
                  backgroundColor: AppColors.success,
                  duration: Duration(seconds: 4),
                ),
              );
            }
            return;
          } catch (dbErr) {
            debugPrint('Firestore banner fallback error: $dbErr');
          }
        }

        if (mounted) {
          setState(() {
            _bannerUrl = prevBannerUrl;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Upload failed: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: AppColors.error,
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'Enter URL',
                textColor: Colors.white,
                onPressed: _enterBannerUrlDialog,
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _uploadingBanner = false;
            _bannerProgress = 0.0;
          });
        }
      }
    } catch (pickerError, stack) {
      debugPrint('Banner picker error: $pickerError\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file explorer: $pickerError'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Paste URL',
              textColor: Colors.white,
              onPressed: _enterBannerUrlDialog,
            ),
          ),
        );
      }
    }
  }

  Future<void> _enterBannerUrlDialog() async {
    final ctrl = TextEditingController(text: _bannerUrl ?? '');
    final confirmed = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link Header Banner URL'),
        content: Column(
          mainAxisSize: minAxisSize(),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter a direct public banner image URL (PNG, JPG, WEBP):',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'https://example.com/banner.png',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Save Link'),
          ),
        ],
      ),
    );

    if (confirmed != null && confirmed.isNotEmpty) {
      try {
        await context.read<RadioAdminViewModel>().setBannerUrl(confirmed);
        if (mounted) {
          setState(() => _bannerUrl = confirmed);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Banner link saved to database!'), backgroundColor: AppColors.success),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to save URL: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  ImageProvider _resolveImageProvider(String url) {
    if (url.startsWith('data:image')) {
      try {
        final base64String = url.split(',').last;
        return MemoryImage(base64Decode(base64String));
      } catch (e) {
        debugPrint('Base64 decode error: $e');
      }
    }
    final validUrl = StorageService.ensureValidUrl(url);
    return NetworkImage(validUrl);
  }

  Widget _resolveImageWidget(
    String url, {
    BoxFit fit = BoxFit.cover,
    Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
  }) {
    if (url.startsWith('data:image')) {
      try {
        final base64String = url.split(',').last;
        return Image.memory(base64Decode(base64String), fit: fit);
      } catch (e) {
        debugPrint('Base64 widget decode error: $e');
      }
    }
    final validUrl = StorageService.ensureValidUrl(url);
    return Image.network(validUrl, fit: fit, errorBuilder: errorBuilder);
  }

  MainAxisSize minAxisSize() => MainAxisSize.min;

  Future<void> _removeLogo() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Logo'),
        content: const Text('Are you sure you want to remove the station logo?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await context.read<RadioAdminViewModel>().removeLogo();
      if (mounted) {
        setState(() => _logoUrl = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo removed from database'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove logo: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _removeBanner() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Banner'),
        content: const Text('Are you sure you want to remove the station banner?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await context.read<RadioAdminViewModel>().removeBanner();
      if (mounted) {
        setState(() => _bannerUrl = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner removed from database'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to remove banner: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioAdminViewModel>();
    final profile = vm.radioProfile;
    if (!_isInitializedFromProfile && profile != null) {
      _name.text = profile.name;
      _description.text = profile.description;
      _function.text = profile.function ?? '';
      _vision.text = profile.vision ?? '';
      _mission.text = profile.mission ?? '';
      _email.text = profile.contactEmail ?? '';
      _phone.text = profile.contactPhone ?? '';
      _website.text = profile.website ?? '';
      _location.text = profile.location ?? '';
      _logoUrl = profile.logoUrl;
      _bannerUrl = profile.bannerUrl;
      _language = profile.language ?? 'French';
      _tags = List.from(profile.tags);
      _isInitializedFromProfile = true;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Radio Page & Branding',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save_outlined, size: 16),
            label: Text(_saving ? 'Saving...' : 'Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: Branding & Settings form
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ==================== VISUAL BRANDING UPLOAD TILES ====================
                      _buildUploadTilesSection(),
                      const SizedBox(height: 28),
                      const Divider(height: 1, color: AppColors.divider),
                      const SizedBox(height: 24),

                      // ==================== STATION IDENTITY ====================
                      const Text('Station Identity',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),

                      // Legal Status Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: (profile?.isNonProfit ?? false)
                              ? AppColors.success.withOpacity(0.08)
                              : AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (profile?.isNonProfit ?? false)
                                ? AppColors.success.withOpacity(0.3)
                                : AppColors.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              (profile?.isNonProfit ?? false)
                                  ? Icons.volunteer_activism_rounded
                                  : Icons.account_balance_outlined,
                              color: (profile?.isNonProfit ?? false)
                                  ? AppColors.success
                                  : AppColors.primary,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Legal Status: ',
                                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                      ),
                                      Text(
                                        (profile?.legalStatus == 'nonProfit')
                                            ? 'Non-Profit'
                                            : ((profile?.legalStatus == 'stateOwned') ? 'State-Owned' : 'For-Profit'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: (profile?.isNonProfit ?? false)
                                              ? AppColors.success
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    (profile?.isNonProfit ?? false)
                                        ? 'Eligible for listener donations via DigiPay & Bank Transfer on your station stream page.'
                                        : 'Standard commercial broadcasting status. Managed by platform SysAdmin.',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _name,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(labelText: 'Station Name *'),
                        validator: (v) =>
                            v?.trim().isEmpty == true ? 'Station name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _description,
                        onChanged: (_) => setState(() {}),
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Short Description'),
                      ),
                      const SizedBox(height: 24),

                      // ==================== STATION PURPOSE ====================
                      const Text('Station Purpose',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _function,
                        onChanged: (_) => setState(() {}),
                        maxLines: 2,
                        decoration: const InputDecoration(
                            labelText: 'Function (What this station does)'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _vision,
                        onChanged: (_) => setState(() {}),
                        maxLines: 2,
                        decoration: const InputDecoration(
                            labelText: 'Vision (Where the station is headed)'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _mission,
                        onChanged: (_) => setState(() {}),
                        maxLines: 2,
                        decoration: const InputDecoration(
                            labelText: 'Mission (Our daily commitment)'),
                      ),
                      const SizedBox(height: 24),

                      // ==================== CONTACT & LOCATION ====================
                      const Text('Contact & Location',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _email,
                              decoration:
                                  const InputDecoration(labelText: 'Public Contact Email'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _phone,
                              decoration:
                                  const InputDecoration(labelText: 'Public Contact Phone'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _website,
                              decoration: const InputDecoration(labelText: 'Website URL'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _location,
                              decoration: const InputDecoration(labelText: 'Location / City'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ==================== CATEGORIES & LANGUAGE ====================
                      const Text('Categories & Language',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _language,
                        items: const [
                          DropdownMenuItem(value: 'French', child: Text('French')),
                          DropdownMenuItem(value: 'English', child: Text('English')),
                          DropdownMenuItem(value: 'Arabic', child: Text('Arabic')),
                          DropdownMenuItem(
                              value: 'Bilingual', child: Text('Bilingual (FR/EN)')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (v) => setState(() => _language = v ?? _language),
                        decoration: const InputDecoration(labelText: 'Broadcasting Language'),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _tagCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Add genre tag',
                                hintText: 'e.g. Jazz, Pop, News...',
                              ),
                              onSubmitted: _addTag,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _addTag(_tagCtrl.text),
                            child: const Text('Add Tag'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: _tags
                            .map((t) => Chip(
                                  label: Text(t),
                                  onDeleted: () => setState(() => _tags.remove(t)),
                                  deleteIconColor: AppColors.textSecondary,
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),

            // Right column: Live preview with logo and banner
            Expanded(
              flex: 2,
              child: _buildLivePreview(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadTilesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined,
                  color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Visual Branding & Images',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    'Click either tile to choose an image from your device (PNG, JPG, WEBP, max 5 MB).',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ==================== LOGO TILE ====================
        const Text('Station Logo',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Recommended: 500 × 500 px square image',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo Clickable Tile
            InkWell(
              onTap: _uploadingLogo ? null : _pickAndUploadLogo,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _logoUrl != null ? AppColors.border : AppColors.primary.withOpacity(0.4),
                    width: _logoUrl != null ? 1 : 1.5,
                  ),
                  image: _logoUrl != null
                      ? DecorationImage(
                          image: _resolveImageProvider(_logoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Empty placeholder
                    if (_logoUrl == null && !_uploadingLogo)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_outlined,
                                size: 32, color: AppColors.primary.withOpacity(0.8)),
                            const SizedBox(height: 6),
                            const Text(
                              'Upload Logo',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),

                    // Progress overlay
                    if (_uploadingLogo)
                      Container(
                        color: Colors.black54,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  value: _logoProgress > 0 ? _logoProgress : null,
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${(_logoProgress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Logo Action Button
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _uploadingLogo ? null : _pickAndUploadLogo,
                      icon: const Icon(Icons.folder_open, size: 16),
                      label: Text(_logoUrl != null ? 'Change (File)' : 'Browse Files'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _uploadingLogo ? null : _enterLogoUrlDialog,
                      icon: const Icon(Icons.link, size: 16),
                      label: const Text('Paste URL'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    if (_logoUrl != null) ...[
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _uploadingLogo ? null : _removeLogo,
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                        label: const Text('Remove', style: TextStyle(color: AppColors.error)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('Opens device file explorer',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    if (_logoUrl != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, size: 11, color: AppColors.success),
                            SizedBox(width: 4),
                            Text('Stored in Firestore',
                                style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ==================== BANNER TILE ====================
        const Text('Station Header Banner',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Recommended: 1600 × 400 px landscape image',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 8),

        // Banner Clickable Tile
        InkWell(
          onTap: _uploadingBanner ? null : _pickAndUploadBanner,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _bannerUrl != null ? AppColors.border : AppColors.primary.withOpacity(0.4),
                width: _bannerUrl != null ? 1 : 1.5,
              ),
              image: _bannerUrl != null
                  ? DecorationImage(
                      image: _resolveImageProvider(_bannerUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Empty placeholder
                if (_bannerUrl == null && !_uploadingBanner)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.panorama_outlined,
                            size: 36, color: AppColors.primary.withOpacity(0.8)),
                        const SizedBox(height: 6),
                        const Text(
                          'Click to upload station banner from your device',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary),
                        ),
                        const SizedBox(height: 2),
                        const Text('PNG, JPG, WEBP up to 5 MB',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),

                // Progress overlay
                if (_uploadingBanner)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              value: _bannerProgress > 0 ? _bannerProgress : null,
                              strokeWidth: 3,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Uploading banner: ${(_bannerProgress * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text('Opens device file explorer',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                if (_bannerUrl != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 11, color: AppColors.success),
                        SizedBox(width: 4),
                        Text('Stored in Firestore',
                            style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            Row(
              children: [
                if (_bannerUrl != null) ...[
                  OutlinedButton.icon(
                    onPressed: _uploadingBanner ? null : _removeBanner,
                    icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                    label: const Text('Remove', style: TextStyle(color: AppColors.error)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                OutlinedButton.icon(
                  onPressed: _uploadingBanner ? null : _enterBannerUrlDialog,
                  icon: const Icon(Icons.link, size: 16),
                  label: const Text('Paste URL'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _uploadingBanner ? null : _pickAndUploadBanner,
                  icon: const Icon(Icons.folder_open, size: 16),
                  label: Text(_bannerUrl != null ? 'Change (File)' : 'Browse Files'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLivePreview() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.visibility_outlined, size: 18, color: AppColors.textSecondary),
              SizedBox(width: 6),
              Text('Live Listener Preview',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),

          // Station card mockup
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_bannerUrl != null)
                        _resolveImageWidget(
                          _bannerUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildDefaultBanner(),
                        )
                      else
                        _buildDefaultBanner(),
                      Container(color: Colors.black.withOpacity(0.18)),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, color: Colors.white, size: 7),
                              SizedBox(width: 4),
                              Text('LIVE',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Logo overlapping header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Transform.translate(
                    offset: const Offset(0, -28),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _logoUrl != null
                              ? _resolveImageWidget(
                                  _logoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.radio, size: 28, color: AppColors.primary),
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.radio, size: 28, color: AppColors.primary),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _name.text.isNotEmpty ? _name.text : 'Station Name',
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _location.text.isNotEmpty
                                      ? _location.text
                                      : 'Broadcasting in $_language',
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Body content
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _description.text.isNotEmpty
                            ? _description.text
                            : 'Short description of the station goes here...',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _tags
                            .map((t) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text('#$t',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary)),
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Details breakdown in preview
          if (_function.text.isNotEmpty) ...[
            const Text('Function',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(_function.text,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
          ],
          if (_vision.text.isNotEmpty) ...[
            const Text('Vision',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(_vision.text,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
          ],
          if (_mission.text.isNotEmpty) ...[
            const Text('Mission',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(_mission.text,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _buildDefaultBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.panorama_outlined, color: Colors.white70, size: 24),
            const SizedBox(width: 8),
            Text(
              _name.text.isNotEmpty ? _name.text : 'Station Banner Preview',
              style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _addTag(String val) {
    final t = val.trim();
    if (t.isNotEmpty && !_tags.contains(t)) {
      setState(() {
        _tags.add(t);
        _tagCtrl.clear();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final vm = context.read<RadioAdminViewModel>();

    // Logo and Banner are already written immediately to Firestore upon upload.
    // Preserving current values so form save updates text fields without overwriting URLs.
    final profile = RadioProfile(
      id: vm.radioId,
      name: _name.text.trim(),
      description: _description.text.trim(),
      function: _function.text.trim(),
      vision: _vision.text.trim(),
      mission: _mission.text.trim(),
      logoUrl: _logoUrl ?? vm.radioProfile?.logoUrl,
      bannerUrl: _bannerUrl ?? vm.radioProfile?.bannerUrl,
      contactEmail: _email.text.trim(),
      contactPhone: _phone.text.trim(),
      website: _website.text.trim(),
      location: _location.text.trim(),
      language: _language,
      tags: _tags,
      legalStatus: vm.radioProfile?.legalStatus ?? 'profit',
      updatedAt: DateTime.now(),
    );

    await vm.updateRadioProfile(profile);
    if (mounted) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Radio profile updated'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }
}
