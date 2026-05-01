import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:space/core/models/shape_model.dart';

class ShapeService {
  final SupabaseClient supabaseClient;

  // Static caches so they persist across ShapeService instances
  static final Map<String, Uint8List> _bytesCache = {};
  static List<ShapeModel>? _shapesCache;

  static const _bucket = 'Shapes';

  ShapeService({required this.supabaseClient});

  /// Get all available shapes from the shapes table
  Future<List<ShapeModel>> getShapes() async {
    if (_shapesCache != null && _shapesCache!.isNotEmpty) {
      return _shapesCache!;
    }

    try {
      print('🔵 ShapeService: Fetching shapes from database...');
      final response = await supabaseClient
          .from('shapes')
          .select()
          .order('created_at');

      final shapeList =
          (response as List).map((json) => ShapeModel.fromJson(json)).toList();
      print('🟢 ShapeService: Parsed ${shapeList.length} shapes');

      _shapesCache = shapeList;
      return shapeList;
    } catch (e) {
      print('🔴 ShapeService: Error fetching shapes: $e');
      return [];
    }
  }

  /// Download shape bytes directly from Shapes bucket
  Future<Uint8List> getShapeBytes(String shapeKey) async {
    if (_bytesCache.containsKey(shapeKey)) {
      return _bytesCache[shapeKey]!;
    }

    try {
      final bytes = await supabaseClient.storage
          .from(_bucket)
          .download(shapeKey);
      print('🟢 ShapeService: Downloaded "$shapeKey"');
      _bytesCache[shapeKey] = bytes;
      return bytes;
    } catch (e) {
      print('🔴 ShapeService: Failed to download "$shapeKey": $e');
      rethrow;
    }
  }

  /// Get cached bytes synchronously
  Uint8List? getCachedBytes(String shapeKey) => _bytesCache[shapeKey];

  /// Preload all shapes into cache in the background
  Future<void> preloadShapes(List<ShapeModel> shapes) async {
    for (final shape in shapes) {
      if (!_bytesCache.containsKey(shape.shapeKey)) {
        try {
          await getShapeBytes(shape.shapeKey);
        } catch (_) {}
      }
    }
  }
}
