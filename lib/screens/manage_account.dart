/// MyPod - manage a Solid account on the server.
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

import 'package:solidpod/solidpod.dart' show getWebId, isUserLoggedIn;
import 'package:solidui/solidui.dart';

import 'package:mypod/constants/app.dart';

// This screen gathers the three account-level operations that the
// Community Solid Server account management API supports, plus a placeholder
// for account deletion which CSS does not yet expose. Each operation is a
// thin wrapper over a `solidui` popup so that the look and feel matches the
// rest of the Solid app family.

class ManageAccount extends StatefulWidget {
  const ManageAccount({super.key});

  @override
  State<ManageAccount> createState() => _ManageAccountState();
}

class _ManageAccountState extends State<ManageAccount> {
  // The server on which a new account should be created. Left empty initially
  // and filled in from the logged-in user's server, since the target Solid
  // server is not known ahead of time.

  final TextEditingController _serverController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Prefill the server field with the server of the currently
    // logged-in WebID so that, in the common case, the user does not have to
    // type it in.

    _resolveCurrentServer();
  }

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  // Derive the server URL from the logged-in WebID and update the field.

  Future<void> _resolveCurrentServer() async {
    final webId = await getWebId();
    final serverUri = WebIdParts.tryParse(webId)?.serverUri;
    if (serverUri != null && mounted) {
      setState(() => _serverController.text = serverUri);
    }
  }

  // Open the create-account popup for the server in the text field.

  Future<void> _createAccount() async {
    final serverUrl = _serverController.text.trim().isNotEmpty
        ? _serverController.text.trim()
        : SolidConfig.defaultServerUrl;

    // The child is the widget to return to on cancel. Since the
    // popup is launched from within an existing page we hand it an empty
    // placeholder rather than a full screen.

    await createAccountPopup(context, const SizedBox.shrink(),
        serverUrl: serverUrl);
  }

  // Open the change-password popup. Changing the password requires an active
  // session, so when the user is not logged in we prompt them to log in first
  // rather than letting the popup throw.

  Future<void> _changePassword() async {
    if (!await isUserLoggedIn()) {
      if (!mounted) return;
      await _promptLogin();
      return;
    }

    if (!mounted) return;
    await changePasswordPopup(context, const SizedBox.shrink());
  }

  // Inform the user that a session is required and offer to open
  // the SolidUI login prompt. The login screen is pushed only if the user
  // chooses to proceed.

  Future<void> _promptLogin() async {
    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login required'),
        content: const Text(
          'You need to be logged in to your Solid account before you can '
          'change its password. Would you like to log in now?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Log In'),
          ),
        ],
      ),
    );

    if (shouldLogin != true || !mounted) return;

    // Push the SolidUI login prompt using the app's client identity, so the
    // user can authenticate without leaving the account screen.

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SolidPopupLogin(
          clientId: clientId,
          redirectUris: redirectUris,
          postLogoutRedirectUris: postLogoutRedirectUris,
        ),
      ),
    );
  }

  // Account deletion is a placeholder. The Community Solid Server
  // does not currently provide an account-deletion endpoint, so we surface a
  // disabled action with an explanatory message rather than hiding it.

  void _deleteAccount() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Deleting your account from the Solid server is not currently '
          'supported on the Community Solid Server (CSS). This feature is '
          'reserved for a future server release.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Account Management',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Administer your Solid account directly through the Community '
                'Solid Server account management API.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              // ── Create account ────────────────────────────────────────────

              _ActionCard(
                icon: Icons.person_add,
                title: 'Create a new account with a named Pod',
                description:
                    'Register a new account on a Solid server and provision a '
                    'Pod for it. Works on Community Solid Server v7 or later.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _serverController,
                      decoration: const InputDecoration(
                        labelText: 'Solid server URL',
                        hintText: 'https://your-solid-server',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.dns),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _createAccount,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Create Account'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Change password ───────────────────────────────────────────

              _ActionCard(
                icon: Icons.password,
                title: 'Change your account password',
                description:
                    'Update the password of the account you are currently '
                    'logged in to. You will be asked for your email and your '
                    'current password to confirm the change.',
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _changePassword,
                    icon: const Icon(Icons.password),
                    label: const Text('Change Password'),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Delete account (placeholder) ──────────────────────────────

              _ActionCard(
                icon: Icons.delete_forever,
                title: 'Delete your account from the server',
                description:
                    'Remove your account from the Solid server. This is not '
                    'currently supported on the Community Solid Server (CSS).',
                child: Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    onPressed: _deleteAccount,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete Account'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// A small presentation card grouping an icon, a heading, a description, and
// the action widget for one account operation.

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
