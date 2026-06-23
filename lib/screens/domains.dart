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

import 'package:solidpod/solidpod.dart'
    show getResourcesInContainer, getWebId, isUserLoggedIn;
import 'package:solidui/solidui.dart';

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

      final names = subDirs.map(_folderName).where((n) => n.isNotEmpty).toList()
        ..sort();

      if (!mounted) return;
      setState(() {
        _podRoot = podRoot;
        _domains = names;
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

  // Open the shared profile editor. This is the same dialog that
  // is reachable from the avatar menu in the top-right of the app, so the
  // editing experience (display name, public/private visibility, and avatar
  // upload/delete) is identical regardless of where it is launched from.

  Future<void> _editProfile() async {
    await SolidProfileEditor.show(context);
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
                    IconButton(
                      onPressed: _loading ? null : _loadDomains,
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Every app that stores data on your Pod appears as a folder '
                  'under your Pod root. The list below is derived from those '
                  'folders.',
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
            ListTile(
              leading: const Icon(Icons.folder),
              title: Text(domains[i]),
              subtitle: const Text('App domain on your Pod'),
              trailing: TextButton.icon(
                onPressed: _editProfile,
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
