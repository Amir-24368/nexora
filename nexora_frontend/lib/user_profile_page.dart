import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'ui/theme.dart';
import 'ui/widgets.dart';

class UserProfilePage extends StatefulWidget {
  final String username;
  const UserProfilePage({super.key, required this.username});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String? _avatarUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final data = await ApiService.getProfile();
      if (!mounted) return;
      setState(() {
        _nameController.text = (data['full_name'] ?? widget.username ?? '').toString();
        _usernameController.text = (data['username'] ?? '').toString();
        _phoneController.text = (data['phone'] ?? '').toString();
        _emailController.text = (data['email'] ?? '').toString();
        _avatarUrl = data['avatar_url']?.toString();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      nxSnack(context, 'Failed to load profile: $e', isError: true);
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await ApiService.updateProfile({
        'full_name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      if (!mounted) return;
      nxSnack(context, 'Profile updated');
    } catch (e) {
      if (!mounted) return;
      nxSnack(context, 'Failed to update: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Opens an image picker; on success uploads the picture as the new avatar.
  Future<void> _changeAvatar() async {
    if (_isUploadingAvatar) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      final file = result?.files.single;
      final Uint8List? bytes = file?.bytes;
      if (bytes == null || bytes.isEmpty) return; // user cancelled

      setState(() => _isUploadingAvatar = true);
      final updated = await ApiService.uploadAvatar(bytes, file!.name);
      if (!mounted) return;
      setState(() {
        final url = updated['avatar_url']?.toString();
        // Cache-bust so the new image loads immediately.
        _avatarUrl = (url != null && url.isNotEmpty)
            ? '$url?v=${DateTime.now().millisecondsSinceEpoch}'
            : null;
        _isUploadingAvatar = false;
      });
      nxSnack(context, 'Profile picture updated');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
      nxSnack(context, 'Failed to upload picture: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = nxOf(context);

    if (_isLoading) return const NxLoader(label: 'Loading profile…');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // ---- Profile picture: tap to change ----
              GestureDetector(
                onTap: _changeAvatar,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: palette.primarySoft,
                      backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                      child: _avatarUrl == null
                          ? Icon(Icons.person_rounded, size: 56, color: palette.textMuted)
                          : null,
                    ),
                    if (_isUploadingAvatar)
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          child: Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: palette.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: palette.surface, width: 2),
                        ),
                        child: const Icon(Icons.photo_camera_rounded, size: 17, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text('Tap the picture to change it', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: palette.textMuted)),
              const SizedBox(height: 24),

              NxCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      NxTextField(
                        controller: _nameController,
                        label: 'Full name',
                        prefixIcon: Icons.badge_outlined,
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      NxTextField(
                        controller: _usernameController,
                        label: 'Username',
                        prefixIcon: Icons.alternate_email_rounded,
                      ),
                      const SizedBox(height: 12),
                      NxTextField(
                        controller: _phoneController,
                        label: 'Phone number',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12),
                      NxTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Your Gmail login — cannot be changed here',
                        prefixIcon: Icons.mail_outline_rounded,
                        enabled: false,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: NxButton(
                          label: _isSaving ? 'Saving…' : 'Update profile',
                          icon: Icons.save_outlined,
                          onPressed: _isSaving ? null : _saveProfile,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              NxCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('APPEARANCE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 1.1, color: palette.textMuted)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: Text('Dark mode', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: palette.textPrimary))),
                        const NxThemeToggle(iconOnly: true),
                      ],
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
