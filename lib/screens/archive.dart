/// MyPod - list and manage archived app domains on a Pod.
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

import 'package:solidpod/solidpod.dart' show isUserLoggedIn;

import 'package:mypod/screens/archive_note_dialog.dart';
import 'package:mypod/screens/archive_tile.dart';
import 'package:mypod/services/archive_notes_service.dart';
import 'package:mypod/services/archive_service.dart';

// Lists the folders held under the Pod's `archive/` container — domains that
// have previously been archived from the Domains screen. Each archived folder
// keeps a `_YYYYMMDD` suffix recording when it was archived. A domain can be
// restored (only when no current domain of the same name exists) or deleted
// permanently.

class Archive extends StatefulWidget {
  const Archive({super.key});

  @override
  State<Archive> createState() => _ArchiveState();
}

class _ArchiveState extends State<Archive> {
  // Archived folder names discovered under `archive/`.

  List<String>? _archived;

  // Current (non-archived) domain names, used to gate restore.

  Set<String> _currentDomains = {};

  // Notes keyed by archived folder name, loaded from MyPod's Pod data.

  Map<String, String> _notes = {};

  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadArchive();
  }

  Future<void> _loadArchive() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (!await isUserLoggedIn()) {
        throw Exception('You must be logged in to view your archive.');
      }

      final archived = await ArchiveService.listArchived();
      final current = await ArchiveService.listCurrentDomains();
      final notes = await ArchiveNotesService.loadNotes(force: true);

      if (!mounted) return;
      setState(() {
        _archived = archived;
        _currentDomains = current;
        _notes = notes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // Restore an archived folder back to a live domain. Disabled when a current
  // domain of the same base name exists.

  Future<void> _restore(String archivedName) async {
    final original = ArchiveService.baseName(archivedName);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Restore "$original"?'),
        content: Text(
          'This will move "$archivedName" out of the Archive and back to '
          '"$original" under your Pod root, making it available to the '
          '$original app again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _runBlocking('Restoring domain…', () async {
      final restored = await ArchiveService.restoreDomain(archivedName);
      await ArchiveNotesService.removeNote(archivedName);
      return 'Restored "$restored".';
    });
  }

  // Permanently delete an archived folder.

  Future<void> _delete(String archivedName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "$archivedName"?'),
        content: const Text(
          'This permanently deletes the archived folder and all of its data '
          'from your Pod server. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _runBlocking('Deleting archive…', () async {
      await ArchiveService.deleteArchived(archivedName);
      await ArchiveNotesService.removeNote(archivedName);
      return 'Deleted "$archivedName".';
    });
  }

  // Run [action] behind a blocking progress dialog, then show the result and
  // refresh the list.

  Future<void> _runBlocking(
    String progressLabel,
    Future<String> Function() action,
  ) async {
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
      final message = await action();
      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss progress.
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      await _loadArchive();
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Dismiss progress.
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Operation failed'),
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Archive',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    IconButton(
                      onPressed: _loading ? null : _loadArchive,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Domains you have archived are kept under the Archive folder '
                  'on your Pod with a date suffix. Restore a domain to make it '
                  'available to its app again, or delete it permanently.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                _buildBody(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final archived = _archived ?? const [];
    if (archived.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No archived domains were found on your Pod.'),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < archived.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            ArchiveTile(
              archivedName: archived[i],
              note: _notes[archived[i]],
              clash: _currentDomains.contains(
                ArchiveService.baseName(archived[i]),
              ),
              originalName: ArchiveService.baseName(archived[i]),
              onEditNote: () => _editNote(archived[i]),
              onRestore: () => _restore(archived[i]),
              onDelete: () => _delete(archived[i]),
            ),
          ],
        ],
      ),
    );
  }

  // Add or edit the note for an archived entry, then refresh.

  Future<void> _editNote(String archivedName) async {
    final saved = await showArchiveNoteDialog(context, archivedName);
    if (saved && mounted) {
      final notes = await ArchiveNotesService.loadNotes(force: true);
      if (mounted) setState(() => _notes = notes);
    }
  }
}
