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

import 'package:mypod/dialogs/edit_app_profile_views.dart';

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

  final TextEditingController _nameController = TextEditingController();
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
      final profile = await readAppProfile(widget.appRootUrl, key: _appKey);
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
    final avatarChanged =
        _avatarRemoved || !identical(_pendingAvatar, _originalAvatar);
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
      final displayName =
          (name.isNotEmpty && (nameChanged || privacyChanged)) ? name : null;

      // Likewise for the avatar.

      final avatarChanged = !identical(_pendingAvatar, _originalAvatar);
      final avatarBytes = (!_avatarRemoved &&
              _pendingAvatar != null &&
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_stage) {
      case _Stage.checking:
        return const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        );
      case _Stage.enterKey:
        return SecurityKeyPrompt(
          appName: widget.appName,
          controller: _keyController,
          verifying: _verifying,
          errorText: _keyError,
          onSubmit: _submitKey,
          onCancel: () => Navigator.of(context).pop(),
        );
      case _Stage.editing:
        return ProfileEditorForm(
          appName: widget.appName,
          loadError: _loadError,
          pendingAvatar: _pendingAvatar,
          hasEncryption: _hasEncryption,
          private: _private,
          isSaving: _isSaving,
          hasChanges: _hasChanges,
          nameController: _nameController,
          onPickImage: _pickImage,
          onRemoveAvatar: _removeAvatar,
          onPrivacyChanged: (value) => setState(() => _private = value),
          onNameChanged: () => setState(() {}),
          onCancel: () => Navigator.of(context).pop(),
          onSave: _save,
        );
    }
  }
}
