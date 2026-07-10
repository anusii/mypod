/// MyPod - widget tests for the DomainTile row.
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
/// Authors: Graham Williams

library;

import 'package:flutter/material.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:markdown_tooltip/markdown_tooltip.dart';

import 'package:mypod/screens/domain_tile.dart';

/// Pump a [DomainTile] inside a minimal app shell, recording which callbacks
/// fire into [calls].

Future<void> pumpTile(
  WidgetTester tester, {
  String? note,
  List<String>? calls,
}) async {
  final log = calls ?? <String>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DomainTile(
          domainName: 'billipod',
          note: note,
          onEditNote: () => log.add('note'),
          onEditProfile: () => log.add('profile'),
          onBackup: () => log.add('backup'),
          onArchive: () => log.add('archive'),
        ),
      ),
    ),
  );
}

/// The MarkdownTooltip message wrapping the button that shows [icon].

String tooltipFor(WidgetTester tester, IconData icon) {
  final finder = find.ancestor(
    of: find.byIcon(icon),
    matching: find.byType(MarkdownTooltip),
  );
  return tester.widget<MarkdownTooltip>(finder.first).message;
}

void main() {
  group('DomainTile rendering', () {
    testWidgets('shows the domain name', (tester) async {
      await pumpTile(tester);
      expect(find.text('billipod'), findsOneWidget);
    });

    testWidgets('shows no subtitle text when there is no note', (
      tester,
    ) async {
      await pumpTile(tester);
      expect(find.text('App domain on your Pod'), findsNothing);
      expect(find.byIcon(Icons.sticky_note_2_outlined), findsNothing);
    });

    testWidgets('shows the note with its icon when a note is set', (
      tester,
    ) async {
      await pumpTile(tester, note: 'My invoices app.');
      expect(find.text('My invoices app.'), findsOneWidget);
      expect(find.byIcon(Icons.sticky_note_2_outlined), findsOneWidget);
    });

    testWidgets('treats an empty note as no note', (tester) async {
      await pumpTile(tester, note: '');
      expect(find.byIcon(Icons.sticky_note_2_outlined), findsNothing);
    });
  });

  group('DomainTile actions and tooltips', () {
    testWidgets('tapping each button fires its callback', (tester) async {
      final calls = <String>[];
      await pumpTile(tester, calls: calls);
      await tester.tap(find.byIcon(Icons.edit_note));
      await tester.tap(find.byIcon(Icons.edit));
      await tester.tap(find.byIcon(Icons.save_alt));
      await tester.tap(find.byIcon(Icons.archive_outlined));
      expect(calls, ['note', 'profile', 'backup', 'archive']);
    });

    testWidgets('note tooltip says Add Note when there is no note', (
      tester,
    ) async {
      await pumpTile(tester);
      expect(tooltipFor(tester, Icons.edit_note), contains('**Add Note**'));
    });

    testWidgets('note tooltip says Edit Note when a note exists', (
      tester,
    ) async {
      await pumpTile(tester, note: 'A note.');
      expect(tooltipFor(tester, Icons.edit_note), contains('**Edit Note**'));
    });

    testWidgets('every action button is wrapped in a MarkdownTooltip', (
      tester,
    ) async {
      await pumpTile(tester);
      for (final icon in [
        Icons.edit_note,
        Icons.edit,
        Icons.save_alt,
        Icons.archive_outlined,
      ]) {
        expect(
          find.ancestor(
            of: find.byIcon(icon),
            matching: find.byType(MarkdownTooltip),
          ),
          findsWidgets,
        );
      }
    });

    testWidgets('tooltip titles match their buttons', (tester) async {
      await pumpTile(tester);
      expect(tooltipFor(tester, Icons.edit), contains('**Edit Profile**'));
      expect(tooltipFor(tester, Icons.save_alt), contains('**Backup**'));
      expect(
        tooltipFor(tester, Icons.archive_outlined),
        contains('**Archive**'),
      );
    });
  });
}
