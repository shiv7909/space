import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/shape_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// HERO ILLUSTRATION — Bento Grid Style
// ═══════════════════════════════════════════════════════════════════════════
class HeroIllustration extends StatefulWidget {
  const HeroIllustration({super.key});

  @override
  State<HeroIllustration> createState() => _HeroIllustrationState();
}

class _HeroIllustrationState extends State<HeroIllustration> {
  List<String> _shapeKeys = [];

  @override
  void initState() {
    super.initState();
    _fetchShapes();
  }

  Future<void> _fetchShapes() async {
    try {
      final shapeService = context.read<ShapeService>();
      final shapes = await shapeService.getShapes();
      if (shapes.isNotEmpty && mounted) {
        setState(() {
          _shapeKeys = shapes.map((s) => s.shapeKey).toList();
        });
      }
    } catch (_) {
      // Fallback or ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220, // Slightly reduced height for tighter bentos
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── BIG BENTO BLOCK (Left) ──
          Expanded(
            flex: 5,
            child: _BentoCard(
              color: const Color(0xFF5C4AE4).withValues(alpha: 0.1),
              child: _shapeKeys.isNotEmpty
                  ? HeroShapeRenderer(shapeKey: _shapeKeys[0])
                  : _buildPlaceholder(Icons.auto_awesome_rounded, const Color(0xFF5C4AE4)),
            ),
          ),

          const SizedBox(width: 12),

          // ── STACKED BENTO BLOCKS (Right) ──
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Top block
                Expanded(
                  child: _BentoCard(
                    color: const Color(0xFF4ECDC4).withValues(alpha: 0.1),
                    child: _shapeKeys.length > 1
                        ? HeroShapeRenderer(shapeKey: _shapeKeys[1])
                        : _buildPlaceholder(Icons.bolt_rounded, const Color(0xFF4ECDC4)),
                  ),
                ),
                const SizedBox(height: 12),
                // Bottom block
                Expanded(
                  child: _BentoCard(
                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                    child: _shapeKeys.length > 2
                        ? HeroShapeRenderer(shapeKey: _shapeKeys[2])
                        : _buildPlaceholder(Icons.favorite_rounded, const Color(0xFFFF6B6B)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(IconData icon, Color color) {
    return Icon(icon, size: 32, color: color.withValues(alpha: 0.6));
  }
}

class _BentoCard extends StatelessWidget {
  final Widget child;
  final Color color;

  const _BentoCard({required this.child, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Center(child: child),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SVG RENDERER
// ═══════════════════════════════════════════════════════════════════════════
class HeroShapeRenderer extends StatelessWidget {
  final String shapeKey;

  const HeroShapeRenderer({
    super.key,
    required this.shapeKey,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: context.read<ShapeService>().getShapeBytes(shapeKey),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SvgPicture.memory(
            snapshot.data!,

            placeholderBuilder: (_) => _placeholder(),
          );
        }
        return _placeholder();
      },
    );
  }

  Widget _placeholder() => const SizedBox();
}
