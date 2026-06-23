# MyPod - Manage Your Solid Pod

> Account, Pod, and App-Profile Management for the Decentralised Web

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

[![Github Repo](https://img.shields.io/badge/GitHub-Repo-blue?logo=github)](https://github.com/anusii/mypod)
[![GitHub License](https://img.shields.io/github/license/anusii/mypod)](https://raw.githubusercontent.com/anusii/mypod/dev/LICENSE)
[![GitHub Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/anusii/mypod/dev/pubspec.yaml&query=$.version&label=version&logo=github)](https://github.com/anusii/mypod/blob/dev/CHANGELOG.md)

[MyPod](https://github.com/anusii/mypod) is an app-independent tool for
managing your Solid account. The Community Solid Server (CSS) supports API
calls to manage your account, and MyPod wraps those calls in a
familiar Solid app experience so you can create accounts, provision
Pods, change passwords, and curate your app profiles without leaving
the app. Your Pod sits in a personal Data Vault on a Solid server in
the cloud, where you stay in control of your data.

## Features

+ Create a new account on a Solid server with a named Pod
+ Change the password of your Solid account on the server
+ List all of the domains hosted on that Solid server
+ Edit each app profile, display name, visibility, and avatar
+ Delete your account from the Solid server (not currently supported on CSS)

## Introduction

MyPod gives you a focused, app-independent place to administer your
Solid account. Rather than browsing files, MyPod talks to the
Community Solid Server (CSS) account management API directly so you can
register new accounts, change passwords, and review which apps are
hosted on your Pod. The app is multi-platform so you can install it for
your desktop or mobile device, or run it directly through a web
browser, all managing the same account on your Solid server.

MyPod also serves as a reference template for any SolidUI-based Flutter
app — wrapping the SolidUI account, password, and profile dialogs with
a typical `SolidScaffold` setup that you can adapt for your own
project.

---

## Quick start

The typical workflow is:

1. **Sign in** to your Solid Pod using the SolidLogin screen on first
   launch. You can also tap **Register** on the login screen to create
   an account before you have one.
2. Open the **Account** screen to create a new account with a named
   Pod, change your password, or review account deletion.
3. Open the **Domains** screen to list every app hosted on your Pod
   and to curate the profile that those apps share.
4. Tap your **avatar** in the top-right at any time to open the same
   profile editor directly.

---

## The screens

A left-hand navigation rail (or collapsible drawer on narrow screens)
gives you:

### Home

Welcome page with a quick feature overview and pointers to the
account-management views. Tap the home icon at any time to return here.

### Account

Administer your Solid account against the Community Solid Server
account management API:

+ **Create a new account with a named POD** — enter a server URL, an
  email address, a password, and a POD name to register a brand-new
  account and provision a POD for it. Works on Community Solid Server
  v7 or later.
+ **Change your account password** — update the password of the
  account you are logged in to. You confirm the change with your email
  and current password.
+ **Delete your account** — a placeholder for account removal. The
  Community Solid Server does not currently expose an account-deletion
  endpoint, so MyPod surfaces a disabled action with an explanatory
  message reserved for a future server release.

### Domains

Every app that stores data on your POD appears as a folder under your
POD root, so the **Domains** screen lists those folders as the
"domains" hosted on the server. From here you can open the shared
profile editor for each app to curate the display name, public/private
visibility, and avatar.

---

## App profiles

The profile editor — reachable from each row on the **Domains** screen
and from the avatar menu in the top-right of the app — lets you:

+ **Set a display name** for your profile.
+ **Toggle visibility** between private (encrypted, owner-only) and
  public (publicly readable linked data).
+ **Upload or delete an avatar** image, with cropping support.

The operations are identical wherever the editor is launched from, so
the experience matches the rest of the Solid app family.

---

## Security keys

Some data on your POD is encrypted for privacy. MyPod manages the
security key needed to read and write encrypted data through the
standard SolidPod flow. The status bar at the bottom of the window
shows your current security-key state — if a key is required, tap the
indicator to enter your password and the app will unlock the relevant
data automatically.

---

## Theme

A theme toggle in the app bar lets you switch between **light**,
**dark**, and **system** modes. The choice is remembered across
sessions.

---

## About info

Tap the **info** (ℹ) button in the top app bar at any time to see a
brief about-the-app dialog with the version number, key features, and
links to the GitHub repository and the Australian Solid Community.

---

## Data and privacy

MyPod authenticates to your POD when you start the app. Account
operations are sent directly to your Solid server's account management
API, which is independent of the app's OIDC login session. Profile data
lives in your POD in the standard folder structure maintained by the
POD server, and any encrypted data is handled through the SolidPod
security-key flow shown in the status bar.

---

## Deployment (Solid-OIDC client registration)

MyPod authenticates with Solid-OIDC, which requires a public **client
identifier document** plus a web **redirect handler**. Following the
same convention as the
[solidpod example](https://anushkavidanage.github.io/solidpod/example/client-profile.jsonld),
these are hosted on **GitHub Pages** rather than on any one Solid
server, so they are publicly reachable by every login server. The two
files live in the Flutter `web/` folder, so `flutter build web`
publishes them automatically:

```bash
web/
├── client-profile.jsonld   → https://anusii.github.io/mypod/client-profile.jsonld
└── redirect.html           → https://anusii.github.io/mypod/redirect.html
```

Deploy the web build (`build/web`) to GitHub Pages at
`https://anusii.github.io/mypod/`, after which both files are served at
the URLs shown above.

Two rules keep login working:

1. The document's `client_id` field **must equal its own public URL**.
2. The redirect MyPod sends at runtime **must be listed** in the
   document's `redirect_uris`. `pickRedirectUri` (from solidpod) sends
   the first `https://` entry on web, the `com.togaware.mypod://`
   custom scheme on Android/iOS/macOS, and the `http://localhost:4400`
   loopback on Windows/Linux.

The app is configured in `lib/constants/app.dart`. None of these values
name a particular POD server — the user chooses their Solid server at
login time:

+ **`clientId`** points at the GitHub Pages document. A login server
  fetches it over the web, so it works when signing in to **any** Solid
  server the user enters.
+ **`redirectUris`** / **`postLogoutRedirectUris`** list the GitHub
  Pages `redirect.html` as the first `https://` entry; because the web
  build is served from the same GitHub Pages origin, the redirect is
  same-origin as required by the BroadcastChannel handshake. The other
  entries are the custom scheme and the loopback callback.

The Android custom scheme is registered through the
`appAuthRedirectScheme` manifest placeholder in
`android/app/build.gradle.kts`. iOS and macOS need no extra
registration (the `oidc` package uses `ASWebAuthenticationSession`),
and Windows/Linux use a loopback callback.

Verify the deployed document with:

```bash
curl https://anusii.github.io/mypod/client-profile.jsonld
```

---

## Troubleshooting

**Account creation says it is not supported.**
Creating accounts and changing passwords requires a Community Solid
Server running v7 or later (for example solidcommunity.au). Other
servers do not expose the account management API.

**The Domains list is empty after login.**
A brand-new POD may not yet contain any app folders. Sign in with an
app such as FilePod first, or tap the refresh action to fetch the
latest listing from your POD.

**Changing my password fails.**
You must be logged in, and you must supply the email address and
current password registered with the server account. Double-check
these and try again.

---

## Authors

+ Tony Chen

For more information about Solid and PODs, visit
[solidproject.org](https://solidproject.org).

---

## License

GNU General Public License v3. See `LICENSE` or
<https://opensource.org/license/gpl-3-0>.

Copyright (C) 2026, Software Innovation Institute, ANU.
