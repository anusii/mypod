/// MyPod - persistence for user notes keyed to Pod folders.
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
/// Authors: Tony Chen, Graham Williams

library;

import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:solidpod/solidpod.dart'
    show ResourceNotExistException, readPod, writePod;

/// Notes that the user attaches to folders on their Pod, keyed by folder
/// name. One instance per notes file: [archiveNotes] keys on archived folder
/// names (unique via their timestamp suffix) and [domainNotes] keys on live
/// domain names.
///
/// Each instance's notes are stored together as a single encrypted JSON file
/// in MyPod's own data directory on the Pod. Because the file lives in the
/// MyPod domain and is encrypted with MyPod's key (already unlocked while the
/// user is signed in), no extra key prompt is needed.

class NotesService {
  /// [file] is the path of the notes file relative to MyPod's data
  /// directory. solidpod requires encrypted files to use the `.ttl`
  /// extension; the JSON payload is stored as the (encrypted) content within
  /// that file.

  NotesService(this._file);

  final String _file;

  /// In-memory cache of the notes map, loaded lazily.

  Map<String, String>? _cache;

  /// Loads all notes as a map of folder-name to note text.

  Future<Map<String, String>> loadNotes({bool force = false}) async {
    if (_cache != null && !force) return _cache!;
    try {
      final content = await readPod(_file);
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      _cache = decoded.map((k, v) => MapEntry(k, v.toString()));
    } on ResourceNotExistException {
      // No notes file yet — start with an empty map.
      _cache = <String, String>{};
    } catch (e) {
      debugPrint('NotesService($_file): loadNotes error: $e');
      _cache = <String, String>{};
    }
    return _cache!;
  }

  /// Returns the note for [name], or null if none is set.

  Future<String?> noteFor(String name) async {
    final notes = await loadNotes();
    final note = notes[name];
    return (note != null && note.isNotEmpty) ? note : null;
  }

  /// Sets (or, when [note] is empty, clears) the note for [name] and
  /// persists the whole map back to the Pod.

  Future<void> setNote(String name, String note) async {
    final notes = Map<String, String>.from(await loadNotes());
    if (note.trim().isEmpty) {
      notes.remove(name);
    } else {
      notes[name] = note.trim();
    }
    await _save(notes);
  }

  /// Removes the note for [name], if any (e.g. when its folder is deleted or
  /// renamed on restore).

  Future<void> removeNote(String name) async {
    final notes = Map<String, String>.from(await loadNotes());
    if (notes.remove(name) != null) {
      await _save(notes);
    }
  }

  /// Moves the note for [name], if any, to the note for [toName] in the
  /// [target] service — used when archiving a domain (domain note follows the
  /// folder into the archive) and when restoring one (archive note follows it
  /// back).

  Future<void> transferNote(
    String name,
    NotesService target,
    String toName,
  ) async {
    final note = await noteFor(name);
    if (note == null) return;
    await target.setNote(toName, note);
    await removeNote(name);
  }

  Future<void> _save(Map<String, String> notes) async {
    _cache = notes;
    await writePod(_file, jsonEncode(notes), overwrite: true);
  }
}

/// Notes on archived/backed-up folders, keyed by archived folder name.

final NotesService archiveNotes = NotesService('archive_notes.ttl');

/// Notes on live app domains, keyed by domain name.

final NotesService domainNotes = NotesService('domain_notes.ttl');
