/// MyPod - per-app profile editor.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://www.gnu.org/licenses/gpl-3.0.html
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program. If not, see <https://www.gnu.org/licenses/gpl-3.0.html>.
///
/// Authors: Tony Chen

library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:file_picker/file_picker.dart';
import 'package:solidpod/solidpod.dart';
import 'package:solidui/solidui.dart' show SolidProfileCropDialog;

// This dialog edits the profile of ONE app/domain folder on the user's Pod,
// independently of every other app. Each app keeps its own profile under its
// own folder, encrypted (when the app uses encryption) with that app's own
// security key. The flow is therefore:
//
//   1. Determine whether the app has encryption set up.
//   2. If it does, ask for that app's security key and verify it.
//   3. Read and decrypt the app's profile and show it.
//   4. On save, re-encrypt (or write as plaintext) under the chosen visibility
//      and write it back to that same app's folder.
//
// Routing the current app (MyPod) here is intentionally avoided by the caller:
// MyPod's own key is already unlocked, so its row uses the standard in-app
// editor instead.

// Maximum allowed upload size for profile pictures (2 MB), matching solidui.

const int _maxProfilePictureBytes = 2 * 1024 * 1024;

/// A dialog that edits the profile (display name, avatar, and visibility) of a
/// single app/domain identified by [appRootUrl].

class EditAppProfileDialog extends StatefulWidget {
  const EditAppProfileDialog({
    super.key,
    required this.appRootUrl,
    required this.appName,
  });

  /// The root URL of the app folder whose profile is being edited.

  final String appRootUrl;

  /// The display name of the app/domain, shown in the dialog title.

  final String appName;

  /// Opens the editor as a modal dialog.

  static Future<void> show(
    BuildContext context, {
    required String appRootUrl,
    required String appName,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => EditAppProfileDialog(
        appRootUrl: appRootUrl,
        appName: appName,
      ),
    );
  }

  @override
  State<EditAppProfileDialog> createState() => _EditAppProfileDialogState();
}

// The stage the dialog is currently showing.

enum _Stage { checking, enterKey, editing }

class _EditAppProfileDialogState extends State<EditAppProfileDialog> {
  _Stage _stage = _Stage.checking;

  // Whether this app has encryption set up (and therefore needs a key).

  bool _hasEncryption = false;

  // The verified key material for the app, once the security key is accepted.

  PodAppKey? _appKey;

  // Security-key entry state.

  final _keyController = TextEditingController();
  bool _verifying = false;
  String? _keyError;

  // Editing state.

  late final TextEditingController _nameController = TextEditingController();
  Uint8List? _pendingAvatar;
  bool _avatarRemoved = false;
  bool _isSaving = false;

  // The values originally loaded, used to detect changes.

  String _originalName = '';
  Uint8List? _originalAvatar;
  bool _originalPrivate = false;

  // The chosen visibility. Forced public when the app has no encryption.

  bool _private = false;

  String? _loadError;

  @override
  void initState() {
    super.initState();
    _checkEncryption();
  }

  @override
  void dispose() {
    _keyController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Decide whether a security key is required.

  Future<void> _checkEncryption() async {
    try {
      final encrypted = await appHasEncryption(widget.appRootUrl);
      if (!mounted) return;
      _hasEncryption = encrypted;
      if (encrypted) {
        setState(() => _stage = _Stage.enterKey);
      } else {
        // Plaintext-only app: no key needed, visibility is public.

        _private = false;
        await _loadProfile();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _stage = _Stage.editing;
      });
    }
  }

  // Verify the entered security key, then load the profile.

  Future<void> _submitKey() async {
    final securityKey = _keyController.text;
    if (securityKey.isEmpty) {
      setState(() => _keyError = 'Please enter the security key.');
      return;
    }

    setState(() {
      _verifying = true;
      _keyError = null;
    });

    try {
      _appKey = await verifyAppSecurityKey(widget.appRootUrl, securityKey);
      if (!mounted) return;
      await _loadProfile();
    } on SecurityKeyVerificationException {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _keyError = 'Incorrect security key. Please try again.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _keyError = 'Unable to read this profile: $e';
      });
    }
  }

  // Read the (decrypted) profile into the editing fields.

  Future<void> _loadProfile() async {
    try {
      final profile =
          await readAppProfile(widget.appRootUrl, key: _appKey);
      if (!mounted) return;
      setState(() {
        _originalName = profile.displayName ?? '';
        _originalAvatar = profile.avatarBytes;
        _originalPrivate = profile.isPrivate;
        _nameController.text = _originalName;
        _pendingAvatar = profile.avatarBytes;
        _private = _hasEncryption && profile.isPrivate;
        _avatarRemoved = false;
        _verifying = false;
        _stage = _Stage.editing;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _verifying = false;
        _stage = _Stage.editing;
      });
    }
  }

  bool get _hasChanges {
    final nameChanged = _nameController.text.trim() != _originalName;
    final avatarChanged = _avatarRemoved ||
        !identical(_pendingAvatar, _originalAvatar);
    final privacyChanged = _private != _originalPrivate;
    return nameChanged || avatarChanged || privacyChanged;
  }

  // Pick and crop a new avatar image.

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final bytes = result.files.first.bytes;
    if (bytes == null) return;

    if (bytes.length > _maxProfilePictureBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image must be smaller than 2 MB')),
        );
      }
      return;
    }

    if (!mounted) return;
    final cropped = await SolidProfileCropDialog.show(context, bytes);
    if (cropped != null && mounted) {
      setState(() {
        _pendingAvatar = cropped;
        _avatarRemoved = false;
      });
    }
  }

  void _removeAvatar() {
    setState(() {
      _pendingAvatar = null;
      _avatarRemoved = true;
    });
  }

  // Persist the edited profile back to the app's folder.

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final name = _nameController.text.trim();
      final privacyChanged = _private != _originalPrivate;

      // Rewrite the name when it changed, or when the visibility changed (so
      // the file is re-encrypted / decrypted under the new mode).

      final nameChanged = name != _originalName;
      final displayName = (name.isNotEmpty && (nameChanged || privacyChanged))
          ? name
          : null;

      // Likewise for the avatar.

      final avatarChanged = !identical(_pendingAvatar, _originalAvatar);
      final avatarBytes =
          (!_avatarRemoved && _pendingAvatar != null &&
                  (avatarChanged || privacyChanged))
              ? _pendingAvatar
              : null;

      await writeAppProfile(
        widget.appRootUrl,
        key: _appKey,
        displayName: displayName,
        avatarBytes: avatarBytes,
        removeAvatar: _avatarRemoved,
        private: _private,
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildBody(theme),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    switch (_stage) {
      case _Stage.checking:
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        );
      case _Stage.enterKey:
        return _buildKeyEntry(theme);
      case _Stage.editing:
        return _buildEditor(theme);
    }
  }

  // Security-key entry.

  Widget _buildKeyEntry(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Unlock ${widget.appName}',
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'This app\'s profile is encrypted. Enter its security key to view '
          'and edit it.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _keyController,
          obscureText: true,
          autofocus: true,
          enabled: !_verifying,
          onSubmitted: (_) => _verifying ? null : _submitKey(),
          decoration: InputDecoration(
            labelText: 'Security key',
            errorText: _keyError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.key_outlined),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed:
                  _verifying ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _verifying ? null : _submitKey,
              child: _verifying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Unlock'),
            ),
          ],
        ),
      ],
    );
  }

  // Profile editor.

  Widget _buildEditor(ThemeData theme) {
    final hasAvatar = _pendingAvatar != null && _pendingAvatar!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.appName,
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        Text(
          'Edit Profile',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),

        if (_loadError != null) ...[
          Text(
            _loadError!,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],

        // Avatar preview.

        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surfaceContainerHighest,
            image: hasAvatar
                ? DecorationImage(
                    image: MemoryImage(_pendingAvatar!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: hasAvatar
              ? null
              : Icon(
                  Icons.person,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            TextButton.icon(
              onPressed: _isSaving ? null : _pickImage,
              icon: const Icon(Icons.upload, size: 18),
              label: Text(hasAvatar ? 'Change Photo' : 'Upload Photo'),
            ),
            if (hasAvatar)
              TextButton.icon(
                onPressed: _isSaving ? null : _removeAvatar,
                icon: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                label: Text(
                  'Remove',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),

        const SizedBox(height: 20),

        // Display name input.

        TextField(
          controller: _nameController,
          enabled: !_isSaving,
          decoration: InputDecoration(
            labelText: 'Display Name',
            hintText: 'Enter the display name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 16),

        _buildPrivacySelector(theme),

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: (_isSaving || !_hasChanges) ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ],
    );
  }

  // Visibility selector. Disabled (forced public) when the app has no
  // encryption set up, since storing a private profile requires the app's
  // own encryption keys.

  Widget _buildPrivacySelector(ThemeData theme) {
    final summary = !_hasEncryption
        ? 'This app has no encryption, so its profile is public (plaintext).'
        : _private
            ? 'Encrypted on the Pod with this app\'s key; only you can read it.'
            : 'Stored as plaintext linked data; readable by anyone with the URL.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _private ? Icons.lock_outline : Icons.public,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                'Profile visibility',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('Private'),
                icon: Icon(Icons.lock_outline, size: 16),
              ),
              ButtonSegment(
                value: false,
                label: Text('Public'),
                icon: Icon(Icons.public, size: 16),
              ),
            ],
            selected: {_private},
            onSelectionChanged: (_isSaving || !_hasEncryption)
                ? null
                : (values) => setState(() => _private = values.first),
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
