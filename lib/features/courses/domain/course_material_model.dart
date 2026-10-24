import 'package:flutter/material.dart';

enum CourseMaterialType {
  file,
  link;

  static CourseMaterialType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'file':
        return CourseMaterialType.file;
      case 'link':
      default:
        return CourseMaterialType.link;
    }
  }

  String toDbValue() => name;
}

class CourseMaterial {
  final String id;
  final String courseId;
  final String title;
  final String? description;
  final CourseMaterialType materialType;
  final String? filePath;
  final int? fileSizeBytes;
  final String? mimeType;
  final String? externalUrl;
  final bool isPublished;
  final DateTime createdAt;
  final String? createdBy;

  const CourseMaterial({
    required this.id,
    required this.courseId,
    required this.title,
    this.description,
    required this.materialType,
    this.filePath,
    this.fileSizeBytes,
    this.mimeType,
    this.externalUrl,
    required this.isPublished,
    required this.createdAt,
    this.createdBy,
  });

  bool get isFile => materialType == CourseMaterialType.file;
  bool get isLink => materialType == CourseMaterialType.link;

  String get fileSizeDisplay {
    if (fileSizeBytes == null || fileSizeBytes == 0) return '';
    const kb = 1024;
    const mb = kb * 1024;
    if (fileSizeBytes! >= mb) {
      return '${(fileSizeBytes! / mb).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSizeBytes! / kb).toStringAsFixed(0)} KB';
    }
  }

  IconData get icon {
    if (isLink) {
      final url = externalUrl?.toLowerCase() ?? '';
      if (url.contains('youtube') || url.contains('youtu.be') || url.contains('vimeo')) {
        return Icons.play_circle_outline;
      }
      if (url.contains('drive.google.com') || url.contains('dropbox')) {
        return Icons.cloud_outlined;
      }
      return Icons.link;
    }

    final mime = mimeType?.toLowerCase() ?? '';
    final path = filePath?.toLowerCase() ?? '';
    if (mime.contains('pdf') || path.endsWith('.pdf')) {
      return Icons.picture_as_pdf_outlined;
    }
    if (mime.startsWith('image/') ||
        path.endsWith('.png') ||
        path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.webp')) {
      return Icons.image_outlined;
    }
    if (mime.contains('presentation') ||
        mime.contains('powerpoint') ||
        path.endsWith('.ppt') ||
        path.endsWith('.pptx')) {
      return Icons.slideshow_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  Color get iconColor {
    if (isLink) return const Color(0xFFE53935); // YouTube red / link accent
    final mime = mimeType?.toLowerCase() ?? '';
    final path = filePath?.toLowerCase() ?? '';
    if (mime.contains('pdf') || path.endsWith('.pdf')) {
      return const Color(0xFFE53935); // PDF red
    }
    if (mime.startsWith('image/')) {
      return const Color(0xFF43A047); // Green
    }
    if (mime.contains('powerpoint') || path.endsWith('.pptx')) {
      return const Color(0xFFFB8C00); // Orange
    }
    return const Color(0xFF1E88E5); // Blue
  }

  factory CourseMaterial.fromMap(Map<String, dynamic> map) {
    return CourseMaterial(
      id: map['id'] as String,
      courseId: map['course_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      materialType: CourseMaterialType.fromString(map['material_type'] as String? ?? 'file'),
      filePath: map['file_path'] as String?,
      fileSizeBytes: (map['file_size_bytes'] as num?)?.toInt(),
      mimeType: map['mime_type'] as String?,
      externalUrl: map['external_url'] as String?,
      isPublished: map['is_published'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      createdBy: map['created_by'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'description': description,
      'material_type': materialType.toDbValue(),
      'file_path': filePath,
      'file_size_bytes': fileSizeBytes,
      'mime_type': mimeType,
      'external_url': externalUrl,
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
    };
  }
}
