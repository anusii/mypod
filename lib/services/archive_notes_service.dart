/// MyPod - persistence for user notes attached to archived/backed-up domains.
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

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:solidpod/solidpod.dart'
    show ResourceNotExistException, readPod, writePod;

/// Notes that the user attaches to archived/backed-up domain folders.
///
/// All notes are stored together as a single encrypted JSON file in MyPod's
/// own data directory on the Pod, keyed by the archived folder name (which is
/// unique because of its timestamp suffix). Because the file lives in the
/// MyPod domain and is encrypted with MyPod's key (already unlocked while the
/// user is signed in), no extra key prompt is needed.

class ArchiveNotesService {
  ArchiveNotesService._();

  /// Path of the notes file relative to MyPod's data directory. solidpod
  /// requires encrypted files to use the `.ttl` extension; the JSON payload is
  /// stored as the (encrypted) content within that file.

  static const String _notesFile = 'archive_notes.ttl';

  /// In-memory cache of the notes map, loaded lazily.

  static Map<String, String>? _cache;

  /// Loads all notes as a map of archived-folder-name to note text.

  static Future<Map<String, String>> loadNotes({bool force = false}) async {
    if (_cache != null && !force) return _cache!;
    try {
      final content = await readPod(_notesFile);
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      _cache = decoded.map((k, v) => MapEntry(k, v.toString()));
    } on ResourceNotExistException {
      // No notes file yet — start with an empty map.
      _cache = <String, String>{};
    } catch (e) {
      debugPrint('ArchiveNotesService: loadNotes error: $e');
      _cache = <String, String>{};
    }
    return _cache!;
  }

  /// Returns the note for [archivedName], or null if none is set.

  static Future<String?> noteFor(String archivedName) async {
    final notes = await loadNotes();
    final note = notes[archivedName];
    return (note != null && note.isNotEmpty) ? note : null;
  }

  /// Sets (or, when [note] is empty, clears) the note for [archivedName] and
  /// persists the whole map back to the Pod.

  static Future<void> setNote(String archivedName, String note) async {
    final notes = Map<String, String>.from(await loadNotes());
    if (note.trim().isEmpty) {
      notes.remove(archivedName);
    } else {
      notes[archivedName] = note.trim();
    }
    await _save(notes);
  }

  /// Removes the note for [archivedName], if any (e.g. when its folder is
  /// deleted or renamed on restore).

  static Future<void> removeNote(String archivedName) async {
    final notes = Map<String, String>.from(await loadNotes());
    if (notes.remove(archivedName) != null) {
      await _save(notes);
    }
  }

  static Future<void> _save(Map<String, String> notes) async {
    _cache = notes;
    await writePod(_notesFile, jsonEncode(notes), overwrite: true);
  }
}
