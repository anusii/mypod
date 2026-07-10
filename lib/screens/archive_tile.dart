/// MyPod - a single archived-domain row with note, restore and delete.
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

import 'package:flutter/material.dart';

import 'package:markdown_tooltip/markdown_tooltip.dart';

/// One row in the Archive list. Shows the archived folder name, an optional
/// note, and Add/Edit Note, Restore and Delete actions. Restore is disabled
/// when [clash] is true (a current domain of the same name exists).

class ArchiveTile extends StatelessWidget {
  const ArchiveTile({
    super.key,
    required this.archivedName,
    required this.note,
    required this.clash,
    required this.originalName,
    required this.onEditNote,
    required this.onRestore,
    required this.onDelete,
  });

  final String archivedName;
  final String? note;
  final bool clash;
  final String originalName;
  final VoidCallback onEditNote;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasNote = note != null && note!.isNotEmpty;

    return ListTile(
      leading: const Icon(Icons.inventory_2_outlined),
      title: Text(archivedName),
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

            Tap here to edit the note attached to this
            archived domain.

            '''
                : '''

            **Add Note**

            Tap here to attach a note to this archived
            domain, for example to record why it was archived.

            ''',
            child: IconButton(
              onPressed: onEditNote,
              icon: const Icon(Icons.edit_note),
            ),
          ),
          MarkdownTooltip(
            message: clash
                ? '''

            **Restore Unavailable**

            A domain named *"$originalName"*
            already exists on your Pod, so this archive cannot be
            restored. Archive or delete the current *"$originalName"*
            domain first.

            '''
                : '''

            **Restore**

            Tap here to restore this archived domain as
            *"$originalName"*, making it available to its app again.

            ''',
            child: IconButton(
              onPressed: clash ? null : onRestore,
              icon: const Icon(Icons.unarchive_outlined),
            ),
          ),
          MarkdownTooltip(
            message: '''

            **Delete**

            Tap here to permanently delete this archived
            domain from your Pod. This cannot be undone.

            ''',
            child: IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
