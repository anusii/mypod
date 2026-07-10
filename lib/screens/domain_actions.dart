/// MyPod - confirmation dialogs and progress handling for backing up and
/// archiving Pod app domains.
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

import 'package:mypod/screens/note_dialog.dart';
import 'package:mypod/services/archive_service.dart';
import 'package:mypod/services/notes_service.dart';

// ignore_for_file: use_build_context_synchronously

/// Confirms and backs up [domainName] (copy to Archive, original kept).
///
/// Returns true if the domain list should be refreshed afterwards. Backup
/// leaves the Domains list unchanged, so this always returns false on success.

Future<bool> backupDomainAction(
  BuildContext context,
  String domainName,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Back up "$domainName"?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A dated copy of the "$domainName" folder will be placed in the '
            'Archive on your Pod server. The original stays in place, so the '
            '$domainName app continues to work normally.',
          ),
          const SizedBox(height: 12),
          const Text(
            'You can restore a backup later from the Archive menu, provided '
            'no current domain of the same name exists.',
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
          child: const Text('Back Up'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return false;

  return _runBlocking(
    context,
    progressLabel: 'Backing up domain…',
    failTitle: 'Backup failed',
    failPrefix: 'Could not back up "$domainName"',
    action: () async {
      final name = await ArchiveService.backupDomain(domainName);
      return (
        message: 'Backed up "$domainName" as "$name".',
        folderName: name,
      );
    },
    refreshAfter: false,
  );
}

/// Confirms and archives [domainName] (move to Archive, original removed).
///
/// Returns true if the domain list should be refreshed afterwards.

Future<bool> archiveDomainAction(
  BuildContext context,
  String domainName,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Archive "$domainName"?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'The "$domainName" folder will be moved into the Archive on '
            'your Pod server. Once archived, the $domainName app will no '
            'longer be able to access this data.',
          ),
          const SizedBox(height: 12),
          const Text(
            'Before archiving, consider backing up the app data using the '
            'Backup feature within the corresponding app, so you keep a '
            'local copy you can restore from.',
          ),
          const SizedBox(height: 12),
          const Text(
            'You can restore an archived domain later from the Archive '
            'menu, provided no current domain of the same name exists.',
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
          child: const Text('Archive'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return false;

  return _runBlocking(
    context,
    progressLabel: 'Archiving domain…',
    failTitle: 'Archive failed',
    failPrefix: 'Could not archive "$domainName"',
    action: () async {
      final name = await ArchiveService.archiveDomain(domainName);

      // Any note on the domain follows the folder into the archive, where
      // the Archive tab will show it against the dated entry.

      await domainNotes.transferNote(domainName, archiveNotes, name);
      return (
        message: 'Archived "$domainName" as "$name".',
        folderName: name,
      );
    },
    refreshAfter: true,
  );
}

/// Runs [action] behind a blocking progress dialog, showing a success snackbar
/// or an error dialog. Returns [refreshAfter] on success, false on failure.

Future<bool> _runBlocking(
  BuildContext context, {
  required String progressLabel,
  required String failTitle,
  required String failPrefix,
  required Future<({String message, String folderName})> Function() action,
  required bool refreshAfter,
}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(child: Text(progressLabel)),
        ],
      ),
    ),
  );

  try {
    final result = await action();
    if (!context.mounted) return false;
    Navigator.of(context).pop(); // Dismiss progress dialog.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        action: SnackBarAction(
          label: 'Add Note',
          onPressed: () =>
              showNoteDialog(context, result.folderName, archiveNotes),
        ),
        duration: const Duration(seconds: 8),
      ),
    );
    return refreshAfter;
  } catch (e) {
    if (!context.mounted) return false;
    Navigator.of(context).pop(); // Dismiss progress dialog.
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(failTitle),
        content: Text('$failPrefix:\n\n$e'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return false;
  }
}
