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

import 'package:flutter/foundation.dart' show kIsWeb;

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

const String clientId = 'https://anusii.github.io/mypod/client-profile.jsonld';

/// Redirect URIs offered to the Solid-OIDC flow, one format per platform.
///
/// These are application redirect endpoints, not Pod server addresses.
/// `pickRedirectUri` (from solidpod) selects one at runtime by *format*: on web
/// it returns the first `https://` entry (falling back to the first entry when
/// none is `https://`), on Android/iOS/macOS the custom-scheme entry, and on
/// Windows/Linux the `http://localhost` loopback entry.
///
/// On web the chosen redirect MUST be same-origin as wherever the app is being
/// served, because `redirect.html` hands the auth response back through a
/// same-origin `BroadcastChannel`; any origin mismatch leaves login hanging on
/// the loading spinner. Crucially, `pickRedirectUri` does NOT match on origin —
/// it just takes the first `https://` entry — so a hard-coded remote `https`
/// URI would always be picked even while debugging at `http://localhost:4400`,
/// producing exactly that hang. We therefore derive the web entry from
/// `Uri.base.origin` at runtime: it resolves to
/// `https://mypod.solidcommunity.au/redirect.html` for the deployed build and to
/// `http://localhost:4400/redirect.html` under
/// `flutter run -d chrome --web-port=4400`. For the localhost case there is no
/// `https://` entry, so `pickRedirectUri` falls back to this single (loopback)
/// entry — keeping the redirect same-origin either way.
///
/// Off the web the list is static: the custom scheme serves Android/iOS/macOS
/// and the loopback entry serves Windows/Linux. Every runtime redirect must
/// also appear in the client identifier document's `redirect_uris`.

List<String> get redirectUris {
  if (kIsWeb) {
    return ['${Uri.base.origin}/redirect.html'];
  }
  return const [
    'com.togaware.mypod://redirect',
    'http://localhost:4400/redirect.html',
  ];
}

/// Post-logout redirect URIs offered to the Solid-OIDC flow.
///
/// Mirrors [redirectUris] (same origin-aware web derivation) and must likewise
/// match the client identifier document's `post_logout_redirect_uris`.

List<String> get postLogoutRedirectUris {
  if (kIsWeb) {
    return ['${Uri.base.origin}/redirect.html'];
  }
  return const [
    'com.togaware.mypod://redirect',
    'http://localhost:4400/redirect.html',
  ];
}

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
