/// MyPod - widget tests for the ArchiveTile row.
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

import 'package:mypod/screens/archive_tile.dart';

/// Pump an [ArchiveTile] inside a minimal app shell, recording which
/// callbacks fire into [calls].

Future<void> pumpTile(
  WidgetTester tester, {
  required bool clash,
  String? note,
  List<String>? calls,
}) async {
  final log = calls ?? <String>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ArchiveTile(
          archivedName: 'cvpod_20260626_134752',
          note: note,
          clash: clash,
          originalName: 'cvpod',
          onEditNote: () => log.add('edit'),
          onRestore: () => log.add('restore'),
          onDelete: () => log.add('delete'),
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

/// The IconButton that shows [icon].

IconButton buttonFor(WidgetTester tester, IconData icon) {
  return tester.widget<IconButton>(
    find.widgetWithIcon(IconButton, icon),
  );
}

void main() {
  group('ArchiveTile rendering', () {
    testWidgets('shows the archived folder name', (tester) async {
      await pumpTile(tester, clash: false);
      expect(find.text('cvpod_20260626_134752'), findsOneWidget);
    });

    testWidgets('shows no subtitle text when there is no note', (
      tester,
    ) async {
      await pumpTile(tester, clash: false);
      expect(find.text('Archived domain'), findsNothing);
      expect(find.byIcon(Icons.sticky_note_2_outlined), findsNothing);
    });

    testWidgets('shows the note with its icon when a note is set', (
      tester,
    ) async {
      await pumpTile(tester, clash: false, note: 'Test 1 and some more.');
      expect(find.text('Test 1 and some more.'), findsOneWidget);
      expect(find.byIcon(Icons.sticky_note_2_outlined), findsOneWidget);
    });

    testWidgets('treats an empty note as no note', (tester) async {
      await pumpTile(tester, clash: false, note: '');
      expect(find.byIcon(Icons.sticky_note_2_outlined), findsNothing);
    });
  });

  group('ArchiveTile restore and clash', () {
    testWidgets('restore is enabled when there is no clash', (tester) async {
      await pumpTile(tester, clash: false);
      expect(buttonFor(tester, Icons.unarchive_outlined).onPressed, isNotNull);
    });

    testWidgets('restore is disabled on a name clash', (tester) async {
      await pumpTile(tester, clash: true);
      expect(buttonFor(tester, Icons.unarchive_outlined).onPressed, isNull);
    });

    testWidgets('clash explanation lives in the restore tooltip', (
      tester,
    ) async {
      await pumpTile(tester, clash: true);
      final message = tooltipFor(tester, Icons.unarchive_outlined);
      expect(message, contains('**Restore Unavailable**'));
      expect(message, contains('"cvpod"'));
      // The explanation must NOT be repeated inline in the tile.
      expect(find.textContaining('Cannot restore'), findsNothing);
    });

    testWidgets('no-clash tooltip names the restore target', (tester) async {
      await pumpTile(tester, clash: false);
      final message = tooltipFor(tester, Icons.unarchive_outlined);
      expect(message, contains('**Restore**'));
      expect(message, contains('"cvpod"'));
    });

    testWidgets('tapping restore fires onRestore when enabled', (
      tester,
    ) async {
      final calls = <String>[];
      await pumpTile(tester, clash: false, calls: calls);
      await tester.tap(find.byIcon(Icons.unarchive_outlined));
      expect(calls, ['restore']);
    });

    testWidgets('tapping restore does nothing on a clash', (tester) async {
      final calls = <String>[];
      await pumpTile(tester, clash: true, calls: calls);
      await tester.tap(find.byIcon(Icons.unarchive_outlined));
      expect(calls, isEmpty);
    });
  });

  group('ArchiveTile other actions and tooltips', () {
    testWidgets('tapping the note button fires onEditNote', (tester) async {
      final calls = <String>[];
      await pumpTile(tester, clash: false, calls: calls);
      await tester.tap(find.byIcon(Icons.edit_note));
      expect(calls, ['edit']);
    });

    testWidgets('tapping delete fires onDelete', (tester) async {
      final calls = <String>[];
      await pumpTile(tester, clash: false, calls: calls);
      await tester.tap(find.byIcon(Icons.delete_outline));
      expect(calls, ['delete']);
    });

    testWidgets('note tooltip says Add Note when there is no note', (
      tester,
    ) async {
      await pumpTile(tester, clash: false);
      expect(tooltipFor(tester, Icons.edit_note), contains('**Add Note**'));
    });

    testWidgets('note tooltip says Edit Note when a note exists', (
      tester,
    ) async {
      await pumpTile(tester, clash: false, note: 'A note.');
      expect(tooltipFor(tester, Icons.edit_note), contains('**Edit Note**'));
    });

    testWidgets('every action button is wrapped in a MarkdownTooltip', (
      tester,
    ) async {
      await pumpTile(tester, clash: false);
      for (final icon in [
        Icons.edit_note,
        Icons.unarchive_outlined,
        Icons.delete_outline,
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
  });
}
