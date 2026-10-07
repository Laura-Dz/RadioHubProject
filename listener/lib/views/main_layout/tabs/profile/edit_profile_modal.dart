import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/widgets/safe_image.dart';
import '../../../../view_models/profile_view_model.dart';
import '../../../../core/constants/app_colors.dart';

class EditProfileModal extends StatefulWidget {
  const EditProfileModal({Key? key}) : super(key: key);
  @override
  State<EditProfileModal> createState() => _State();
}

class _State extends State<EditProfileModal> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _phone;
  late TextEditingController _bio;
  late TextEditingController _city;

  String? _ageGroup;
  String? _gender;
  String? _language;

  bool _uploadingAvatar = false;
  double _avatarProgress = 0;
  bool _saving = false;

  final _picker = ImagePicker();

  static const _ageGroups = [
    ('18_24', '18–24'),
    ('25_34', '25–34'),
    ('35_44', '35–44'),
    ('45_54', '45–54'),
    ('55_plus', '55+'),
  ];

  static const _genders = [
    ('male', 'Male'),
    ('female', 'Female'),
    ('other', 'Other'),
    ('prefer_not', 'Prefer not to say'),
  ];

  static const _languages = [
    ('en', 'English'),
    ('fr', 'Français'),
  ];

  @override
  void initState() {
    super.initState();
    final p = context.read<ProfileViewModel>().profile;
    _name = TextEditingController(text: p?.displayName ?? '');
    _phone = TextEditingController(text: p?.phone ?? '');
    _bio = TextEditingController(text: p?.bio ?? '');
    _city = TextEditingController(text: p?.city ?? '');
    _ageGroup = p?.ageGroup;
    _gender = p?.gender;
    _language = p?.language ?? 'en';
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _bio.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final p = vm.profile;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_outlined, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Edit profile',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: _saving ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Center(
                          child: Stack(
                            children: [
                              MouseRegion(
                                cursor: _uploadingAvatar
                                    ? SystemMouseCursors.basic
                                    : SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: _uploadingAvatar
                                      ? null
                                      : _pickAvatar,
                                  child: Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppColors.border, width: 2),
                                    ),
                                    child: ClipOval(
                                      child: SafeImage(
                                        imageUrl: p?.photoUrl,
                                        width: 96,
                                        height: 96,
                                        fallback: Center(
                                          child: Text(
                                            p?.displayName.isNotEmpty == true
                                                ? p!.displayName[0]
                                                    .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                                fontSize: 36,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_uploadingAvatar)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${(_avatarProgress * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        _label('Display name'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _name,
                          decoration: _dec('Your name'),
                          validator: (v) => (v?.trim().isEmpty ?? true)
                              ? 'Required'
                              : null,
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Phone'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _phone,
                                    keyboardType: TextInputType.phone,
                                    decoration: _dec('Optional'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('City'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _city,
                                    decoration: _dec('Optional'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Age group'),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: _ageGroup,
                                    isExpanded: true,
                                    items: _ageGroups
                                        .map((e) => DropdownMenuItem(
                                            value: e.$1, child: Text(e.$2)))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _ageGroup = v),
                                    decoration: _dec('Optional'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Gender'),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: _gender,
                                    isExpanded: true,
                                    items: _genders
                                        .map((e) => DropdownMenuItem(
                                            value: e.$1, child: Text(e.$2)))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _gender = v),
                                    decoration: _dec('Optional'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        _label('Language'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _language,
                          isExpanded: true,
                          items: _languages
                              .map((e) => DropdownMenuItem(
                                  value: e.$1, child: Text(e.$2)))
                              .toList(),
                          onChanged: (v) => setState(() => _language = v),
                          decoration: _dec(''),
                        ),
                        const SizedBox(height: 14),

                        _label('Bio'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _bio,
                          maxLines: 3,
                          maxLength: 200,
                          decoration: _dec('Tell us a bit about yourself'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check, size: 16),
                      label: const Text('Save changes'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700));

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      );

  Future<void> _pickAvatar() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        imageQuality: 90,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.length > 5 * 1024 * 1024) {
        _snack('Image is too large (max 5 MB).', error: true);
        return;
      }
      setState(() {
        _uploadingAvatar = true;
        _avatarProgress = 0;
      });
      final ext = picked.name.split('.').last.toLowerCase();
      await context.read<ProfileViewModel>().uploadAvatar(
            bytes: bytes,
            extension: ext,
            onProgress: (p) {
              if (mounted) setState(() => _avatarProgress = p);
            },
          );
      if (mounted) _snack('Avatar updated');
    } catch (e) {
      if (mounted) _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await context.read<ProfileViewModel>().updateProfile(
            displayName: _name.text,
            phone: _phone.text,
            bio: _bio.text,
            city: _city.text,
            ageGroup: _ageGroup,
            gender: _gender,
            language: _language,
          );
      if (!mounted) return;
      Navigator.pop(context);
      _snack('Profile updated');
    } catch (e) {
      if (mounted) _snack(e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
        duration: Duration(seconds: error ? 5 : 3),
      ),
    );
  }
}
