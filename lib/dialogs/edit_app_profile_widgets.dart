/// MyPod - smaller widgets for the per-app profile editor.
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

/// Circular avatar preview, or a person placeholder when no avatar is staged.

class AvatarPreview extends StatelessWidget {
  const AvatarPreview({super.key, required this.bytes});

  /// The avatar bytes to preview, or null for the placeholder.

  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAvatar = bytes != null && bytes!.isNotEmpty;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: theme.colorScheme.surfaceContainerHighest,
        image: hasAvatar
            ? DecorationImage(image: MemoryImage(bytes!), fit: BoxFit.cover)
            : null,
      ),
      child: hasAvatar
          ? null
          : Icon(Icons.person,
              size: 64, color: theme.colorScheme.onSurfaceVariant),
    );
  }
}

/// Visibility selector. Disabled (forced public) when the app has no encryption
/// set up, since storing a private profile requires the app's own keys.

class ProfileVisibilitySelector extends StatelessWidget {
  const ProfileVisibilitySelector({
    super.key,
    required this.hasEncryption,
    required this.private,
    required this.enabled,
    required this.onChanged,
  });

  /// Whether the app supports a private (encrypted) profile.

  final bool hasEncryption;

  /// Whether the current selection is private.

  final bool private;

  /// Whether the selector is interactive.

  final bool enabled;

  /// Called when the user changes the visibility.

  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = !hasEncryption
        ? 'This app has no encryption, so its profile is public (plaintext).'
        : private
            ? 'Encrypted on the Pod with this app\'s key; only you can read it.'
            : 'Stored as plaintext linked data; readable by anyone with the '
                'URL.';

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
              Icon(private ? Icons.lock_outline : Icons.public,
                  size: 18, color: theme.colorScheme.onSurface),
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
            selected: {private},
            onSelectionChanged:
                enabled ? (values) => onChanged(values.first) : null,
          ),
          const SizedBox(height: 6),
          Text(
            summary,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
