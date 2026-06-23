/// MyPod - main entry point for the Solid account manager app.
///
/// Copyright (C) 2026, Software Innovation Institute, ANU.
///
/// Licensed under the GNU General Public License, Version 3 (the "License").
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
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Tony Chen

library;

import 'package:flutter/material.dart';

import 'package:solidui/solidui.dart';
import 'package:window_manager/window_manager.dart';

import 'package:mypod/app.dart';
import 'package:mypod/constants/app.dart';

// Below is the main entry point for the application. For our
// main() we require [async] because we asynchronously [await] the window
// manager below. Eventually `main()` will hand over to the widget passed to
// [runApp].

void main() async {
  // Optionally for development we utilise [debugPrint] to trace
  // execution, and note that the output is not shown on a `flutter
  // --release`. To quieten the `flutter --debug` when developing we can
  // globally remove [debugPrint] messages by mapping it to null (no op).
  //
  // debugPrint = (String? message, {int? wrapWidth}) {
  //   null;
  // };

  // ── Desktop setup ───────────────────────────────────────────────────────────

  // We want to ensure Flutter bindings are initialised for async
  // operations particularly to set the desktop window [title] as we do below.

  WidgetsFlutterBinding.ensureInitialized();

  if (isDesktop) {
    await windowManager.ensureInitialized();

    // For our desktop app we tune various window oriented
    // settings. Not required for mobile apps.

    const windowOptions = WindowOptions(
      title: appTitle,
      minimumSize: Size(500, 800),
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    // We now await the window to be shown and to receive the
    // focus, to then proceed to run the app.

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // ── Run the app ─────────────────────────────────────────────────────────────

  // The runApp() function takes the given Widget and makes it the
  // root of the tree of widgets that an app creates.

  runApp(const App());
}
