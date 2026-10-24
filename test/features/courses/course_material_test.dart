import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:trainee_app/features/courses/domain/course_material_model.dart';

void main() {
  group('CourseMaterial domain model tests (trainee_app)', () {
    test('parses file material correctly from map', () {
      final map = {
        'id': 'mat-101',
        'course_id': 'crs-1',
        'title': 'Endodontics Manual',
        'description': 'Full clinical procedure manual',
        'material_type': 'file',
        'file_path': 'crs-1/manual.pdf',
        'file_size_bytes': 2097152, // 2 MB
        'mime_type': 'application/pdf',
        'external_url': null,
        'is_published': true,
        'created_at': '2026-10-24T12:00:00Z',
        'created_by': 'admin-uuid',
      };

      final mat = CourseMaterial.fromMap(map);

      expect(mat.id, 'mat-101');
      expect(mat.courseId, 'crs-1');
      expect(mat.title, 'Endodontics Manual');
      expect(mat.isFile, true);
      expect(mat.isLink, false);
      expect(mat.fileSizeDisplay, '2.0 MB');
      expect(mat.icon, Icons.picture_as_pdf_outlined);
      expect(mat.isPublished, true);
    });

    test('parses link material correctly from map and detects video icon', () {
      final map = {
        'id': 'mat-102',
        'course_id': 'crs-1',
        'title': 'YouTube Lecture Recording',
        'description': 'Live session recap',
        'material_type': 'link',
        'file_path': null,
        'file_size_bytes': null,
        'mime_type': null,
        'external_url': 'https://www.youtube.com/watch?v=abcd1234',
        'is_published': true,
        'created_at': '2026-10-24T12:00:00Z',
      };

      final mat = CourseMaterial.fromMap(map);

      expect(mat.id, 'mat-102');
      expect(mat.isFile, false);
      expect(mat.isLink, true);
      expect(mat.fileSizeDisplay, '');
      expect(mat.icon, Icons.play_circle_outline);
      expect(mat.iconColor, const Color(0xFFE53935));
    });

    test('detects cloud drive link icon', () {
      final mat = CourseMaterial(
        id: 'mat-103',
        courseId: 'crs-1',
        title: 'Google Drive Assets',
        materialType: CourseMaterialType.link,
        externalUrl: 'https://drive.google.com/drive/folders/123',
        isPublished: true,
        createdAt: DateTime.now(),
      );

      expect(mat.icon, Icons.cloud_outlined);
    });
  });
}
