/// MyPod - app-wide constants.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
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

import 'package:solidui/solidui.dart' show SolidInviteOthersConfig;

/// Application title displayed as the window title.

const String appTitle = 'MyPod - Manage your Solid Pod';

/// URL of the Solid-OIDC client identifier document for MyPod.
///
/// This identifies the MyPod application itself, not the user's Pod server.
/// Following the same convention as the solidpod example, the document is
/// hosted on GitHub Pages so it is publicly reachable by whichever Solid
/// server the user chooses to log in to. The login server fetches it to learn
/// MyPod's registered redirect URIs. It must be publicly readable and its own
/// `client_id` field must equal this URL. The source document lives at
/// `web/client-profile.jsonld` in this repository and is published with the
/// web build.

const String clientId = 'https://mypod.solidcommunity.au/client-profile.jsonld';

/// Redirect URIs offered to the Solid-OIDC flow, one format per platform.
///
/// These are application redirect endpoints, not Pod server addresses.
/// `pickRedirectUri` (from solidpod) selects the right one at runtime. On web
/// it picks the entry whose origin equals the origin the app is served from,
/// because `redirect.html` hands the auth response back via a same-origin
/// `BroadcastChannel` — a mismatch leaves login hanging on the loading spinner.
/// The custom scheme is used for Android/iOS/macOS and the loopback entry for
/// Windows/Linux (and web debugging). Every entry here must also appear in the
/// client identifier document's `redirect_uris`.

const List<String> redirectUris = [
  'https://mypod.solidcommunity.au/redirect.html',
  'http://localhost:4400/redirect.html',
  'com.togaware.mypod://redirect',
];

/// Post-logout redirect URIs offered to the Solid-OIDC flow.
///
/// Mirrors [redirectUris] and must likewise match the client identifier
/// document's `post_logout_redirect_uris`.

const List<String> postLogoutRedirectUris = [
  'https://mypod.solidcommunity.au/redirect.html',
  'http://localhost:4400/redirect.html',
  'com.togaware.mypod://redirect',
];

/// Public URL where MyPod is hosted. Used by the Invite Others
/// feature to send a working link to the recipient.

const String appUrl = 'https://anusii.github.io/mypod/';

/// Application-wide Invite Others configuration shared by the
/// AppBar share button and the App Info dialog so that users can
/// invite others to set up their POD and try MyPod.

const SolidInviteOthersConfig inviteOthersConfig = SolidInviteOthersConfig(
  applicationName: 'MyPod',
  appUrl: appUrl,
  appDescription:
      'manage your Solid account, Pods, and app profiles using MyPod',
  messageTemplate: '''
You might like to try the {appName} app, available online here:

{appUrl}

Signing into {appName} will set up your data vault so you can manage your
Solid account, create Pods, and curate your app profiles.

''',
  subject: 'Try the MyPod app on your Solid POD',
  tooltip: '''

  **Invite Others**

  Tap to invite someone else to try MyPod. You can copy the
  invitation to the clipboard or share it through any messaging app
  installed on your device.

  ''',
);
