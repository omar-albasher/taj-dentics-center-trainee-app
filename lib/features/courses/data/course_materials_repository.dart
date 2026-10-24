import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/course_material_model.dart';

final courseMaterialsRepositoryProvider = Provider<CourseMaterialsRepository>((ref) {
  return CourseMaterialsRepository();
});

final courseMaterialsProvider =
    FutureProvider.family<List<CourseMaterial>, String>((ref, courseId) async {
  final repo = ref.watch(courseMaterialsRepositoryProvider);
  return repo.getMaterials(courseId: courseId);
});

class CourseMaterialsRepository {
  final SupabaseClient _client;

  CourseMaterialsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<CourseMaterial>> getMaterials({required String courseId}) async {
    final response = await _client
        .from('course_materials')
        .select()
        .eq('course_id', courseId)
        .eq('is_published', true)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => CourseMaterial.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> getSignedUrl(String filePath, {int expiresIn = 3600}) async {
    final signedUrl = await _client.storage
        .from('course-materials')
        .createSignedUrl(filePath, expiresIn);
    return signedUrl;
  }
}
