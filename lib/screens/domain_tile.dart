/// MyPod - one row in the Domains list.
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
/// Authors: Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

/// One row in the Domains list. Shows the domain name, an optional user
/// note, and Add/Edit Note, Edit Profile, Backup and Archive actions.

class DomainTile extends StatelessWidget {
  const DomainTile({
    super.key,
    required this.domainName,
    required this.note,
    required this.onEditNote,
    required this.onEditProfile,
    required this.onBackup,
    required this.onArchive,
  });

  final String domainName;
  final String? note;
  final VoidCallback onEditNote;
  final VoidCallback onEditProfile;
  final VoidCallback onBackup;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNote = note != null && note!.isNotEmpty;

    return ListTile(
      leading: const Icon(Icons.folder),
      title: Text(domainName),
      subtitle: hasNote
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.sticky_note_2_outlined,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    note!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MarkdownTooltip(
            message: hasNote
                ? '''

            **Edit Note**

            Tap here to edit the note attached to this domain.

            '''
                : '''

            **Add Note**

            Tap here to attach a note to this domain, for example to
            record what you use it for.

            ''',
            child: IconButton(
              onPressed: onEditNote,
              icon: const Icon(Icons.edit_note),
            ),
          ),
          MarkdownTooltip(
            message: '''

            **Edit Profile**

            Tap here to edit this domain's app profile, including its
            display name, visibility, and avatar.

            ''',
            child: IconButton(
              onPressed: onEditProfile,
              icon: const Icon(Icons.edit),
            ),
          ),
          MarkdownTooltip(
            message: '''

            **Backup**

            Tap here to take a dated backup of this domain into the
            Archive folder on your Pod. The domain remains available to
            its app.

            ''',
            child: IconButton(
              onPressed: onBackup,
              icon: const Icon(Icons.save_alt),
            ),
          ),
          MarkdownTooltip(
            message: '''

            **Archive**

            Tap here to move this domain into the Archive folder on your
            Pod so it is no longer available to its app. It can be
            restored later from the Archive.

            ''',
            child: IconButton(
              onPressed: onArchive,
              icon: const Icon(Icons.archive_outlined),
            ),
          ),
        ],
      ),
    );
  }
}
