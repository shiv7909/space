import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/category_model.dart';

class CategoryService {
  final SupabaseClient supabaseClient;

  CategoryService({required this.supabaseClient});

  List<CategoryModel>? _cachedCategories;

  Future<List<CategoryModel>> getCategories() async {
    if (_cachedCategories != null) return _cachedCategories!;

    try {
      print('🔵 CategoryService: Fetching categories...');

      final res = await supabaseClient
          .from('categories')
          .select('id, key, name, emoji, display_order')
          .eq('is_active', true)
          .order('display_order');

      _cachedCategories =
          (res as List).map((e) => CategoryModel.fromJson(e)).toList();

      print(
          '🟢 CategoryService: Fetched ${_cachedCategories!.length} categories');
      return _cachedCategories!;
    } catch (e) {
      print('🔴 CategoryService: Error fetching categories: $e');
      return [];
    }
  }

  void clearCache() => _cachedCategories = null;
}

