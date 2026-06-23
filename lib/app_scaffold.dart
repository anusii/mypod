/// MyPod - the primary application scaffold.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
///
/// License: https://opensource.org/license/gpl-3-0.
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
// this program. If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart';

import 'package:mypod/constants/app.dart';
import 'package:mypod/screens/domains.dart';
import 'package:mypod/screens/manage_account.dart';

// A single controller shared by the scaffold so that AppBar
// actions can navigate to subpages without rebuilding the whole tree.

final _scaffoldController = SolidScaffoldController();

const appScaffold = AppScaffold();

class AppScaffold extends StatelessWidget {
  const AppScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    return SolidScaffold(
      controller: _scaffoldController,
      hideNavRail: false,
      enableProfile: true,
      onLogout: (context) => SolidAuthHandler.instance.handleLogout(context),
      menu: const [
        SolidMenuItem(
          icon: Icons.manage_accounts,
          title: 'Account',
          tooltip: '''

            **Account**

            Tap here to create a new Solid account with a named Pod, change
            your account password, or remove your account from the server.

            ''',
          child: ManageAccount(),
        ),
        SolidMenuItem(
          icon: Icons.dns,
          title: 'Domains',
          tooltip: '''

            **Domains**

            Tap here to list every app (domain) hosted on your Pod and to
            curate each app profile, display name, visibility, and avatar.

            ''',
          child: Domains(),
        ),
      ],
      appBar: SolidAppBarConfig(
        title: appTitle.split(' - ')[0],
        versionConfig: const SolidVersionConfig(
          changelogUrl: 'https://github.com/anusii/mypod/blob/dev/CHANGELOG.md',
          showUpdateButton: true,
          downloadUrl: 'https://solidcommunity.au/installers/',
        ),
      ),
      statusBar: const SolidStatusBarConfig(
        serverInfo: SolidServerInfo(serverUri: SolidConfig.defaultServerUrl),
        loginStatus: SolidLoginStatus(),
        securityKeyStatus: SolidSecurityKeyStatus(),
      ),
      aboutConfig: SolidAboutConfig(
        applicationName: appTitle.split(' - ')[0],
        applicationIcon: Image.asset(
          'assets/images/app_icon.png',
          width: 64,
          height: 64,
        ),
        applicationLegalese: '''

        © 2026 Software Innovation Institute, ANU

        ''',
        text: '''

        MyPod is an app-independent tool for managing your Solid account on
        a Community Solid Server. It talks to the server's account management
        API directly, so you can administer your Pods without leaving the app.

        ### Key features

        - Create a new Solid account with a named Pod on a Solid server
        - Change the password of your Solid account on the server
        - List all domains (apps) hosted on your Solid server
        - Edit each app profile, display name, visibility, and avatar
        - Theme switching (light / dark / system)
        - Responsive navigation (rail and drawer)

        For more information, visit the
        [MyPod](https://github.com/anusii/mypod) GitHub repository and our
        [Australian Solid Community](https://solidcommunity.au) web site.

        ''',
        readmeUrl: 'https://anusii.github.io/mypod',
      ),
      themeToggle: const SolidThemeToggleConfig(
        enabled: true,
        showInAppBarActions: true,
      ),
      inviteConfig: inviteOthersConfig,
      child: const ManageAccount(),
    );
  }
}
