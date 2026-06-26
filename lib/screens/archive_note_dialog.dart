/// MyPod - dialog for adding or editing a note on an archived domain.
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

import 'package:mypod/services/archive_notes_service.dart';

/// Shows a dialog to add or edit the note for [archivedName]. The note is
/// stored in MyPod's domain on the Pod. Returns true if the note was saved.

Future<bool> showArchiveNoteDialog(
  BuildContext context,
  String archivedName,
) async {
  // Load any existing note before showing the editor.
  String? existing;
  try {
    existing = await ArchiveNotesService.noteFor(archivedName);
  } catch (_) {
    existing = null;
  }
  if (!context.mounted) return false;

  final controller = TextEditingController(text: existing ?? '');

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Note for "$archivedName"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This note is stored privately in your MyPod data on the Pod '
            'server.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'e.g. Archived before reinstalling the app.',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Save'),
        ),
      ],
    ),
  );

  if (saved != true) {
    controller.dispose();
    return false;
  }

  final text = controller.text;
  controller.dispose();

  try {
    await ArchiveNotesService.setNote(archivedName, text);
    return true;
  } catch (e) {
    if (context.mounted) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Could not save note'),
          content: Text('$e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
    return false;
  }
}
