/// MyPod - unit tests for ArchiveService name and timestamp helpers.
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

import 'package:flutter_test/flutter_test.dart';

import 'package:mypod/services/archive_service.dart';

// These tests cover the pure helpers only. The Pod I/O methods
// (archiveDomain, restoreDomain, ...) require a live solidpod session and
// are exercised manually against a test Pod.

void main() {
  group('ArchiveService.timestampSuffix', () {
    test('formats a known moment as _YYYYMMDD_HHMMSS', () {
      final when = DateTime(2026, 7, 10, 8, 36, 25);
      expect(ArchiveService.timestampSuffix(when), '_20260710_083625');
    });

    test('zero-pads single-digit fields', () {
      final when = DateTime(2026, 1, 2, 3, 4, 5);
      expect(ArchiveService.timestampSuffix(when), '_20260102_030405');
    });

    test('round-trips through baseName', () {
      final archived = 'billipod${ArchiveService.timestampSuffix()}';
      expect(ArchiveService.baseName(archived), 'billipod');
    });
  });

  group('ArchiveService.baseName', () {
    test('strips a full _YYYYMMDD_HHMMSS suffix', () {
      expect(ArchiveService.baseName('cvpod_20260626_134752'), 'cvpod');
    });

    test('strips a legacy date-only _YYYYMMDD suffix', () {
      expect(ArchiveService.baseName('cvpod_20260626'), 'cvpod');
    });

    test('returns an unsuffixed name unchanged', () {
      expect(ArchiveService.baseName('billipod'), 'billipod');
    });

    test('preserves underscores within the domain name itself', () {
      expect(
        ArchiveService.baseName('my_app_20260710_083625'),
        'my_app',
      );
    });

    test('strips only the trailing timestamp from a doubly archived name', () {
      // An archive of an archive: only the last suffix is removed.
      expect(
        ArchiveService.baseName('cvpod_20260626_134752_20260710_083625'),
        'cvpod_20260626_134752',
      );
    });

    test('does not treat short digit runs as a timestamp', () {
      expect(ArchiveService.baseName('app_2026'), 'app_2026');
      expect(ArchiveService.baseName('app_20260626_1234'), 'app_20260626_1234');
    });

    test('handles a name that is only a timestamp-like string', () {
      // No base before the underscore pattern: nothing sensible to strip
      // beyond the regex, which requires a (possibly empty) prefix.
      expect(ArchiveService.baseName('20260626_134752'), '20260626_134752');
    });
  });
}
