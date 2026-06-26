/// MyPod - service for archiving, restoring and deleting Pod app domains.
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

import 'package:flutter/foundation.dart' show debugPrint;

import 'package:solidpod/solidpod.dart'
    show
        ResourceContentType,
        createResource,
        deleteResource,
        getResource,
        getResourcesInContainer,
        getWebId;
import 'package:solidui/solidui.dart' show WebIdParts;

/// The container under the Pod root that holds archived domains.

const String archiveDirName = 'archive';

/// Service that moves whole app-domain folders into an `archive/` container
/// (and back), operating on the raw stored bytes so no security key is needed.
///
/// Solid servers offer no atomic folder rename or move, so a "move" is a
/// recursive copy of every resource followed by a recursive delete of the
/// original. Files are copied verbatim (still encrypted), so archiving never
/// needs to decrypt anything.

class ArchiveService {
  ArchiveService._();

  /// Returns the Pod root URL, e.g. `https://server/alice/`.

  static Future<String> podRoot() async {
    final webId = await getWebId();
    final parts = WebIdParts.tryParse(webId);
    if (parts == null || parts.username.isEmpty) {
      throw Exception('Could not determine the Pod root from your WebID.');
    }
    return '${parts.serverUri}/${parts.username}/';
  }

  /// A timestamp suffix of the form `_YYYYMMDD_HHMMSS` for archived folder
  /// names, including time so archiving the same domain more than once a day
  /// does not collide.

  static String timestampSuffix([DateTime? when]) {
    final t = when ?? DateTime.now();
    final y = t.year.toString().padLeft(4, '0');
    final mo = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    final h = t.hour.toString().padLeft(2, '0');
    final mi = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '_$y$mo${d}_$h$mi$s';
  }

  /// Strips a trailing `_YYYYMMDD_HHMMSS` (or legacy `_YYYYMMDD`) timestamp
  /// from an archived folder name, returning the original domain name. Returns
  /// [name] unchanged if it has no recognised suffix.

  static String baseName(String name) {
    final withTime = RegExp(r'^(.*)_\d{8}_\d{6}$').firstMatch(name);
    if (withTime != null) return withTime.group(1)!;
    final dateOnly = RegExp(r'^(.*)_\d{8}$').firstMatch(name);
    return dateOnly == null ? name : dateOnly.group(1)!;
  }

  /// Ensures the top-level `archive/` container exists under the Pod root.

  static Future<void> _ensureArchiveContainer(String root) async {
    final url = '$root$archiveDirName/';
    try {
      await createResource(
        url,
        isFile: false,
        contentType: ResourceContentType.directory,
        replaceIfExist: false,
      );
    } catch (e) {
      // Already exists (or a benign POST-exists response) — safe to ignore.
      debugPrint('ArchiveService: ensure archive container: $e');
    }
  }

  /// Recursively copies the container at [srcUrl] to [dstUrl]. Both URLs must
  /// end with a slash. Files are copied as raw bytes.

  static Future<void> _copyContainer(String srcUrl, String dstUrl) async {
    await createResource(
      dstUrl,
      isFile: false,
      contentType: ResourceContentType.directory,
      replaceIfExist: false,
    );

    final (subDirs: subDirs, files: files) = await getResourcesInContainer(
      srcUrl,
    );

    for (final file in files) {
      final name = _lastSegment(file);
      if (name.isEmpty) continue;
      final bytes = await getResource('$srcUrl$name');
      await createResource(
        '$dstUrl$name',
        content: bytes,
        contentType: ResourceContentType.binary,
      );
    }

    for (final dir in subDirs) {
      final name = _lastSegment(dir);
      if (name.isEmpty) continue;
      await _copyContainer('$srcUrl$name/', '$dstUrl$name/');
    }
  }

  /// Recursively deletes the container at [url] (which must end with a slash)
  /// and everything inside it.

  static Future<void> _deleteContainer(String url) async {
    final (subDirs: subDirs, files: files) = await getResourcesInContainer(
      url,
    );

    for (final file in files) {
      final name = _lastSegment(file);
      if (name.isEmpty) continue;
      await deleteResource('$url$name', ResourceContentType.binary);
    }

    for (final dir in subDirs) {
      final name = _lastSegment(dir);
      if (name.isEmpty) continue;
      await _deleteContainer('$url$name/');
    }

    await deleteResource(url, ResourceContentType.directory);
  }

  /// Archives the domain [domainName]: copies `root/<domain>/` to
  /// `root/archive/<domain>_YYYYMMDD_HHMMSS/` then deletes the original.
  ///
  /// Returns the archived folder name.

  static Future<String> archiveDomain(String domainName) async {
    final archivedName = await backupDomain(domainName);
    final root = await podRoot();
    await _deleteContainer('$root$domainName/');
    return archivedName;
  }

  /// Backs up the domain [domainName]: copies `root/<domain>/` to
  /// `root/archive/<domain>_YYYYMMDD_HHMMSS/` and leaves the original in place.
  ///
  /// Returns the backup folder name.

  static Future<String> backupDomain(String domainName) async {
    final root = await podRoot();
    await _ensureArchiveContainer(root);

    final archivedName = '$domainName${timestampSuffix()}';
    final srcUrl = '$root$domainName/';
    final dstUrl = '$root$archiveDirName/$archivedName/';

    await _copyContainer(srcUrl, dstUrl);
    return archivedName;
  }

  /// Lists the archived folder names under `root/archive/`.

  static Future<List<String>> listArchived() async {
    final root = await podRoot();
    final archiveUrl = '$root$archiveDirName/';
    try {
      final (subDirs: subDirs, files: _) = await getResourcesInContainer(
        archiveUrl,
      );
      final names =
          subDirs.map(_lastSegment).where((n) => n.isNotEmpty).toList()..sort();
      return names;
    } catch (e) {
      // Archive container does not exist yet — nothing archived.
      debugPrint('ArchiveService: listArchived: $e');
      return [];
    }
  }

  /// Lists the current (non-archived) domain folder names under the Pod root,
  /// used to check for name clashes before restoring.

  static Future<Set<String>> listCurrentDomains() async {
    final root = await podRoot();
    final (subDirs: subDirs, files: _) = await getResourcesInContainer(root);
    return subDirs.map(_lastSegment).where((n) => n.isNotEmpty).toSet();
  }

  /// Restores an archived folder [archivedName] back to its original domain
  /// name under the Pod root. Throws if a current domain of the same base
  /// name already exists.

  static Future<String> restoreDomain(String archivedName) async {
    final root = await podRoot();
    final original = baseName(archivedName);

    final current = await listCurrentDomains();
    if (current.contains(original)) {
      throw Exception(
        'A domain named "$original" already exists. Remove or rename it '
        'before restoring this archive.',
      );
    }

    final srcUrl = '$root$archiveDirName/$archivedName/';
    final dstUrl = '$root$original/';
    await _copyContainer(srcUrl, dstUrl);
    await _deleteContainer(srcUrl);
    return original;
  }

  /// Permanently deletes an archived folder [archivedName].

  static Future<void> deleteArchived(String archivedName) async {
    final root = await podRoot();
    await _deleteContainer('$root$archiveDirName/$archivedName/');
  }

  /// Extract the final path segment (folder/file name) from a resource URL.

  static String _lastSegment(String url) {
    final trimmed = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    final segments = Uri.parse(trimmed).pathSegments;
    return segments.isEmpty ? '' : segments.last;
  }
}
