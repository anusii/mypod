/// MyPod - presentational widgets for the per-app profile editor.
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

import 'package:mypod/dialogs/edit_app_profile_widgets.dart';

// Stateless views for [EditAppProfileDialog]. They hold no profile state; the
// dialog owns it and passes values and callbacks in. Keeping them here keeps
// the dialog file focused on the read/verify/save logic.

/// Security-key entry view, shown for encryption-enabled apps before their
/// profile can be read.

class SecurityKeyPrompt extends StatelessWidget {
  const SecurityKeyPrompt({
    super.key,
    required this.appName,
    required this.controller,
    required this.verifying,
    required this.errorText,
    required this.onSubmit,
    required this.onCancel,
  });

  /// The display name of the app/domain being unlocked.

  final String appName;

  /// Controller backing the obscured security-key field.

  final TextEditingController controller;

  /// Whether a verification attempt is in progress.

  final bool verifying;

  /// Inline error message to show beneath the field, if any.

  final String? errorText;

  /// Called when the user submits the key.

  final VoidCallback onSubmit;

  /// Called when the user cancels.

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Unlock $appName',
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
          controller: controller,
          obscureText: true,
          autofocus: true,
          enabled: !verifying,
          onSubmitted: (_) => verifying ? null : onSubmit(),
          decoration: InputDecoration(
            labelText: 'Security key',
            errorText: errorText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.key_outlined),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: verifying ? null : onCancel,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: verifying ? null : onSubmit,
              child: verifying
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
}

/// The profile editing form: avatar, display name, visibility, and actions.

class ProfileEditorForm extends StatelessWidget {
  const ProfileEditorForm({
    super.key,
    required this.appName,
    required this.loadError,
    required this.pendingAvatar,
    required this.hasEncryption,
    required this.private,
    required this.isSaving,
    required this.hasChanges,
    required this.nameController,
    required this.onPickImage,
    required this.onRemoveAvatar,
    required this.onPrivacyChanged,
    required this.onNameChanged,
    required this.onCancel,
    required this.onSave,
  });

  /// The display name of the app/domain, shown as the title.

  final String appName;

  /// A non-fatal error to surface above the form, if any.

  final String? loadError;

  /// The avatar bytes currently staged for preview, or null for none.

  final Uint8List? pendingAvatar;

  /// Whether the app supports a private (encrypted) profile.

  final bool hasEncryption;

  /// Whether the current selection is private.

  final bool private;

  /// Whether a save is in progress.

  final bool isSaving;

  /// Whether there are unsaved changes (enables the Save button).

  final bool hasChanges;

  /// Controller backing the display-name field.

  final TextEditingController nameController;

  /// Callbacks for the various actions.

  final VoidCallback onPickImage;
  final VoidCallback onRemoveAvatar;
  final ValueChanged<bool> onPrivacyChanged;
  final VoidCallback onNameChanged;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAvatar = pendingAvatar != null && pendingAvatar!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          appName,
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        Text(
          'Edit Profile',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        if (loadError != null) ...[
          Text(
            loadError!,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
          const SizedBox(height: 12),
        ],
        AvatarPreview(bytes: pendingAvatar),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            TextButton.icon(
              onPressed: isSaving ? null : onPickImage,
              icon: const Icon(Icons.upload, size: 18),
              label: Text(hasAvatar ? 'Change Photo' : 'Upload Photo'),
            ),
            if (hasAvatar)
              TextButton.icon(
                onPressed: isSaving ? null : onRemoveAvatar,
                icon: Icon(Icons.delete_outline,
                    size: 18, color: theme.colorScheme.error),
                label: Text('Remove',
                    style: TextStyle(color: theme.colorScheme.error)),
              ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          controller: nameController,
          enabled: !isSaving,
          decoration: InputDecoration(
            labelText: 'Display Name',
            hintText: 'Enter the display name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            prefixIcon: const Icon(Icons.badge_outlined),
          ),
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => onNameChanged(),
        ),
        const SizedBox(height: 16),
        ProfileVisibilitySelector(
          hasEncryption: hasEncryption,
          private: private,
          enabled: !isSaving && hasEncryption,
          onChanged: onPrivacyChanged,
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: isSaving ? null : onCancel,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: (isSaving || !hasChanges) ? null : onSave,
              child: isSaving
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
}
