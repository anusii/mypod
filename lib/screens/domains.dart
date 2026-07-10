/// MyPod - list and curate the domains (apps) hosted on a Pod.
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
import 'package:solidpod/solidpod.dart'
    show SolidConstants, getResourcesInContainer, getWebId, isUserLoggedIn;
import 'package:solidui/solidui.dart';

import 'package:mypod/dialogs/edit_app_profile.dart';
import 'package:mypod/screens/domain_actions.dart';
import 'package:mypod/screens/domain_tile.dart';
import 'package:mypod/screens/note_dialog.dart';
import 'package:mypod/services/archive_service.dart';
import 'package:mypod/services/notes_service.dart';

// Each top-level folder under a user's Pod root corresponds to an
// app (a "domain") that has stored data on the Pod. This screen enumerates
// those folders to show which apps are hosted on the server, and lets the
// user open the profile editor to curate the display name, visibility, and
// avatar that those apps share.

class Domains extends StatefulWidget {
  const Domains({super.key});

  @override
  State<Domains> createState() => _DomainsState();
}

class _DomainsState extends State<Domains> {
  // The list of app/domain folder names discovered under the Pod root.

  List<String>? _domains;

  // Notes the user has attached to domains, keyed by domain name.

  Map<String, String> _notes = {};

  // Human-readable Pod root URL, shown as the source of the listing.

  String? _podRoot;

  // Populated when the listing fails so the cause can be shown to the user.

  String? _error;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDomains();
  }

  // Fetch the list of app folders under the Pod root.

  Future<void> _loadDomains() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (!await isUserLoggedIn()) {
        throw Exception('You must be logged in to list your domains.');
      }

      // Reconstruct the Pod root URL from the WebID. The root is
      // the user's container directly under whichever Solid server they are
      // logged in to, e.g. `https://<their-pod-server>/alice/`.

      final webId = await getWebId();
      final parts = WebIdParts.tryParse(webId);
      if (parts == null || parts.username.isEmpty) {
        throw Exception('Could not determine the Pod root from your WebID.');
      }

      final podRoot = '${parts.serverUri}/${parts.username}/';

      // List the containers (folders) at the root. Each
      // sub-container is treated as one app/domain.

      final (subDirs: subDirs, files: _) =
          await getResourcesInContainer(podRoot);

      final notes = await domainNotes.loadNotes(force: true);

      // Keep only genuine POD applications. Some containers under the Pod
      // root are not apps but storage folders named with a UUID-style
      // hexadecimal code, or reserved folders such as `profile`; these are
      // filtered out so the list shows only app domains.

      final names = subDirs
          .map(_folderName)
          .where((n) => n.isNotEmpty && !_isUuidName(n) && !_isReservedName(n))
          .toList()
        ..sort();

      if (!mounted) return;
      setState(() {
        _podRoot = podRoot;
        _domains = names;
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

  // Extract the final path segment (the folder name) from a container URL.

  String _folderName(String url) {
    final trimmed = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    final segments = Uri.parse(trimmed).pathSegments;
    return segments.isEmpty ? '' : segments.last;
  }

  // Matches a canonical UUID, i.e. a fixed-length hexadecimal code in the
  // 8-4-4-4-12 form.

  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  // Whether a folder name is a UUID-style code rather than a POD app domain.
  // Such folders are storage containers, not applications, so they are
  // excluded from the domains list.

  bool _isUuidName(String name) => _uuidPattern.hasMatch(name);

  // Reserved folder names that are part of the Pod's own structure rather
  // than POD applications (e.g. the `profile` container), so they are
  // excluded from the domains list.

  static const Set<String> _reservedNames = {'profile', archiveDirName};

  bool _isReservedName(String name) =>
      _reservedNames.contains(name.toLowerCase());

  // Open the profile editor for a single app/domain.
  //
  // Each app keeps its own profile under its own folder, so editing must target
  // the clicked app specifically rather than a shared profile. MyPod's own
  // folder is a special case: the user is already signed in to MyPod, so its
  // security key is unlocked and we reuse the standard in-app editor (the same
  // dialog reachable from the avatar menu). Every other app needs its own
  // security key, so it opens the per-app editor, which prompts for that key
  // and reads/writes that app's profile independently.

  Future<void> _editProfile(String domainName) async {
    if (domainName == SolidConstants.directories.app) {
      await SolidProfileEditor.show(context);
      return;
    }

    final appRootUrl = '$_podRoot$domainName/';
    if (!mounted) return;
    await EditAppProfileDialog.show(
      context,
      appRootUrl: appRootUrl,
      appName: domainName,
    );
  }

  // Add or edit the note for a domain, then refresh the notes shown.

  Future<void> _editNote(String domainName) async {
    final saved = await showNoteDialog(context, domainName, domainNotes);
    if (saved) {
      final notes = await domainNotes.loadNotes(force: true);
      if (mounted) setState(() => _notes = notes);
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
                        'Domains',
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    MarkdownTooltip(
                      message: '''

                      **Refresh**

                      Tap here to reload the list of app
                      domains from your Pod.

                      ''',
                      child: IconButton(
                        onPressed: _loading ? null : _loadDomains,
                        icon: const Icon(Icons.refresh),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Every app that stores data on the Pod server appears as a folder '
                  'under your Pod root, which we call a domain. The list below is derived from those '
                  'folders in your Pod server. Tap a button to edit the profile of a domain, '
                  'to backup a domain (into the Archive on the Pod server), or to archive the domain,'
                  'so that it is no longer listed here or available to the apps. This latter operation '
                  'allows you to start the app again with a fresh/empty pod. The domain '
                  'can be restored at a later time as you wish.',
                  style: theme.textTheme.bodyMedium,
                ),
                if (_podRoot != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _podRoot!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
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

    final domains = _domains ?? const [];
    if (domains.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('No app domains were found on your Pod.'),
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < domains.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            DomainTile(
              domainName: domains[i],
              note: _notes[domains[i]],
              onEditNote: () => _editNote(domains[i]),
              onEditProfile: () => _editProfile(domains[i]),
              onBackup: () async {
                await backupDomainAction(context, domains[i]);
              },
              onArchive: () async {
                final refresh = await archiveDomainAction(
                  context,
                  domains[i],
                );
                if (refresh && mounted) await _loadDomains();
              },
            ),
          ],
        ],
      ),
    );
  }
}
