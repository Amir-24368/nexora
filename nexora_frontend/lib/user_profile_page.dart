import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'services/api_service.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await ApiService.updateProfile({
        'full_name': _nameController.text.trim(),
        'username': _usernameController.text.trim(),
        'phone': _phoneController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload picture: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // ---- Profile picture: tap to change ----
          GestureDetector(
            onTap: _changeAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                  child: _avatarUrl == null
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
                if (_isUploadingAvatar)
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: CircularProgressIndicator(color: Colors.white)),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text('Tap the picture to change it',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 20),

          // ---- Editable fields ----
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.alternate_email),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.badge),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            readOnly: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              helperText: 'Your Gmail login - cannot be changed here',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? 'Saving...' : 'Update Profile'),
            ),
          ),
        ],
      ),
    );
  }
}