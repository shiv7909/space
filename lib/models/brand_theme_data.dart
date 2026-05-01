import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ═══════════════════════════════════════════════════════════════════════════
// BRAND THEME DATA — Parsed from brand_theme JSONB (v2 schema)
//
// Structure:
//   { colors: {...}, typography: {...}, components: {...} }
//
// Falls back to sensible defaults for every field so the UI never breaks
// even if a brand has a partial or empty theme.
// ═══════════════════════════════════════════════════════════════════════════

class BrandThemeData {
  final BrandColors colors;
  final BrandTypography typography;
  final BrandComponents components;
  final BrandVibeConfig vibe;

  const BrandThemeData({
    required this.colors,
    required this.typography,
    required this.components,
    required this.vibe,
  });

  /// Parse from the raw `brand_theme` JSONB map.
  /// Gracefully handles null, empty, or partial data.
  factory BrandThemeData.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return BrandThemeData.fallback();

    return BrandThemeData(
      colors: BrandColors.fromJson(
        json['colors'] is Map
            ? Map<String, dynamic>.from(json['colors'] as Map)
            : {},
      ),
      typography: BrandTypography.fromJson(
        json['typography'] is Map
            ? Map<String, dynamic>.from(json['typography'] as Map)
            : {},
      ),
      components: BrandComponents.fromJson(
        json['components'] is Map
            ? Map<String, dynamic>.from(json['components'] as Map)
            : {},
      ),
      vibe: BrandVibeConfig.fromJson(
        json['vibe'] is Map
            ? Map<String, dynamic>.from(json['vibe'] as Map)
            : {},
      ),
    );
  }

  /// Default theme — matches the current hardcoded BrandChallengeScreen look.
  factory BrandThemeData.fallback() {
    return BrandThemeData(
      colors: BrandColors.fallback(),
      typography: BrandTypography.fallback(),
      components: BrandComponents.fallback(),
      vibe: BrandVibeConfig.fallback(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BRAND COLORS
// ═══════════════════════════════════════════════════════════════════════════

class BrandColors {
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color primary;
  final Color accent;
  final Color success;
  final Color info;
  final Color border;
  final Color snapBorderColor;
  final Color heroBgStart;
  final Color heroBgEnd;
  final Color heroGlow;

  const BrandColors({
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.primary,
    required this.accent,
    required this.success,
    required this.info,
    required this.border,
    required this.snapBorderColor,
    required this.heroBgStart,
    required this.heroBgEnd,
    required this.heroGlow,
  });

  factory BrandColors.fromJson(Map<String, dynamic> json) {
    final fb = BrandColors.fallback();
    return BrandColors(
      background: _parseColor(json['background']) ?? fb.background,
      surface: _parseColor(json['surface']) ?? fb.surface,
      textPrimary: _parseColor(json['textPrimary']) ?? fb.textPrimary,
      textSecondary: _parseColor(json['textSecondary']) ?? fb.textSecondary,
      textTertiary: _parseColor(json['textTertiary']) ?? fb.textTertiary,
      primary: _parseColor(json['primary']) ?? fb.primary,
      accent: _parseColor(json['accent']) ?? fb.accent,
      success: _parseColor(json['success']) ?? fb.success,
      info: _parseColor(json['info']) ?? fb.info,
      border: _parseColor(json['border']) ?? fb.border,
      snapBorderColor: _parseColor(json['snapBorderColor']) ?? fb.snapBorderColor,
      heroBgStart: _parseColor(json['heroBgStart']) ?? fb.heroBgStart,
      heroBgEnd: _parseColor(json['heroBgEnd']) ?? fb.heroBgEnd,
      heroGlow: _parseColor(json['heroGlow']) ?? fb.heroGlow,
    );
  }

  factory BrandColors.fallback() {
    return const BrandColors(
      background: Color(0xFFF5F5F8),
      surface: Color(0xFFFFFFFF),
      textPrimary: Color(0xFF1A1A2E),
      textSecondary: Color(0xFF8E8E9A),
      textTertiary: Color(0xFFBBBBC5),
      primary: Color(0xFF5C4AE4),
      accent: Color(0xFF5C4AE4),
      success: Color(0xFF2DA44E),
      info: Color(0xFF5C4AE4),
      border: Color(0xFFE0E0E5),
      snapBorderColor: Color(0xFF5C4AE4),
      heroBgStart: Color(0xFFFFFFFF),
      heroBgEnd: Color(0xFFF5F5F8),
      heroGlow: Color(0x336C63FF),
    );
  }

  /// Is this a dark-mode brand theme?
  bool get isDark {
    final luminance = background.computeLuminance();
    return luminance < 0.5;
  }

  /// Contrast-safe text color for use on [primary] backgrounds
  Color get onPrimary {
    return primary.computeLuminance() > 0.5 ? Colors.black : Colors.white;
  }

  /// Contrast-safe text color for use on [background]
  Color get onBackground {
    return isDark ? Colors.white : textPrimary;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BRAND TYPOGRAPHY
// ═══════════════════════════════════════════════════════════════════════════

class BrandTypography {
  final String fontFamily;
  final int headingWeight;
  final int bodyWeight;
  final double letterSpacing;
  final String textTransform; // 'uppercase' | 'capitalize' | 'none'

  const BrandTypography({
    required this.fontFamily,
    required this.headingWeight,
    required this.bodyWeight,
    required this.letterSpacing,
    required this.textTransform,
  });

  factory BrandTypography.fromJson(Map<String, dynamic> json) {
    final fb = BrandTypography.fallback();
    return BrandTypography(
      fontFamily: json['fontFamily']?.toString() ?? fb.fontFamily,
      headingWeight: _parseInt(json['headingWeight']) ?? fb.headingWeight,
      bodyWeight: _parseInt(json['bodyWeight']) ?? fb.bodyWeight,
      letterSpacing: _parseDouble(json['letterSpacing']) ?? fb.letterSpacing,
      textTransform: json['textTransform']?.toString() ?? fb.textTransform,
    );
  }

  factory BrandTypography.fallback() {
    return const BrandTypography(
      fontFamily: 'Nunito',
      headingWeight: 800,
      bodyWeight: 600,
      letterSpacing: -0.3,
      textTransform: 'uppercase',
    );
  }

  /// Resolve the heading [FontWeight] from the numeric value.
  FontWeight get headingFontWeight => _toFontWeight(headingWeight);

  /// Resolve the body [FontWeight] from the numeric value.
  FontWeight get bodyFontWeight => _toFontWeight(bodyWeight);

  /// Apply text transform to a string.
  String transform(String text) {
    switch (textTransform) {
      case 'uppercase':
        return text.toUpperCase();
      case 'capitalize':
        return text.split(' ').map((w) {
          if (w.isEmpty) return w;
          return w[0].toUpperCase() + w.substring(1).toLowerCase();
        }).join(' ');
      case 'lowercase':
        return text.toLowerCase();
      default:
        return text;
    }
  }

  /// Get a heading TextStyle using this brand's typography config.
  TextStyle headingStyle({
    double? size,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return _resolveFont(
      fontFamily: fontFamily,
      size: size,
      weight: headingFontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing ?? this.letterSpacing,
    );
  }

  /// Get a body TextStyle using this brand's typography config.
  TextStyle bodyStyle({
    double? size,
    Color? color,
    FontWeight? weight,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return _resolveFont(
      fontFamily: fontFamily,
      size: size,
      weight: weight ?? bodyFontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  /// Resolve a Google Font TextStyle from the font family name.
  static TextStyle _resolveFont({
    required String fontFamily,
    double? size,
    FontWeight? weight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    // Map common font family names to Google Fonts constructors
    switch (fontFamily.toLowerCase().replaceAll(' ', '')) {
      case 'barlowcondensed':
        return GoogleFonts.barlowCondensed(
          fontSize: size, fontWeight: weight, color: color,
          height: height, letterSpacing: letterSpacing, decoration: decoration,
        );
      case 'barlow':
        return GoogleFonts.barlow(
          fontSize: size, fontWeight: weight, color: color,
          height: height, letterSpacing: letterSpacing, decoration: decoration,
        );
      case 'inter':
        return GoogleFonts.inter(
          fontSize: size, fontWeight: weight, color: color,
          height: height, letterSpacing: letterSpacing, decoration: decoration,
        );
      case 'poppins':
        return GoogleFonts.poppins(
          fontSize: size, fontWeight: weight, color: color,
          height: height, letterSpacing: letterSpacing, decoration: decoration,
        );
      case 'montserrat':
        return GoogleFonts.montserrat(
          fontSize: size, fontWeight: weight, color: color,
          height: height, letterSpacing: letterSpacing, decoration: decoration,
        );
      case 'oswald':
        return GoogleFonts.oswald(
          fontSize: size, fontWeight: weight, color: color,
          height: height, letterSpacing: letterSpacing, decoration: decoration,
        );
      case 'raleway':
        return GoogleFonts.raleway(
          fontSize: size, fontWeight: weight, color: color,
          height: height, letterSpacing: letterSpacing, decoration: decoration,
        );
      case 'roboto':
        return GoogleFonts.roboto(
          fontSize: size, fontWeight: weight, color: color,
          height: height, letterSpacing: letterSpacing, decoration: decoration,
        );
      case 'nunito':
        return GoogleFonts.plusJakartaSans(
          fontSize: size, fontWeight: weight, color: color,
          height: height, letterSpacing: letterSpacing, decoration: decoration,
        );
      case 'spacegrotesk':
        return GoogleFonts.spaceGrotesk(
          fontSize: size, fontWeight: weight, color: color,
          height: height, letterSpacing: letterSpacing, decoration: decoration,
        );
      case 'plusjakartasans':
        return GoogleFonts.plusJakartaSans(
          fontSize: size, fontWeight: weight, color: color,
          height: height, letterSpacing: letterSpacing, decoration: decoration,
        );
      case 'outfit':
        return GoogleFonts.outfit(
          fontSize: size, fontWeight: weight, color: color,
          height: height, letterSpacing: letterSpacing, decoration: decoration,
        );
      default:
        // Fallback: try dynamic lookup, else Barlow Condensed
        try {
          return GoogleFonts.getFont(
            fontFamily,
            fontSize: size, fontWeight: weight, color: color,
            height: height, letterSpacing: letterSpacing, decoration: decoration,
          );
        } catch (_) {
          return GoogleFonts.barlowCondensed(
            fontSize: size, fontWeight: weight, color: color,
            height: height, letterSpacing: letterSpacing, decoration: decoration,
          );
        }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BRAND COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

class BrandComponents {
  final double cardRadius;
  final String buttonStyle;     // 'rounded' | 'sharp' | 'pill'
  final String snapBorderStyle; // 'solid' | 'dashed'
  final double snapBorderWidth;
  final String badgeStyle;      // 'filled' | 'soft' | 'outline'

  const BrandComponents({
    required this.cardRadius,
    required this.buttonStyle,
    required this.snapBorderStyle,
    required this.snapBorderWidth,
    required this.badgeStyle,
  });

  factory BrandComponents.fromJson(Map<String, dynamic> json) {
    final fb = BrandComponents.fallback();
    return BrandComponents(
      cardRadius: _parseDouble(json['cardRadius']) ?? fb.cardRadius,
      buttonStyle: json['buttonStyle'] as String? ?? fb.buttonStyle,
      snapBorderStyle: json['snapBorderStyle'] as String? ?? fb.snapBorderStyle,
      snapBorderWidth: _parseDouble(json['snapBorderWidth']) ?? fb.snapBorderWidth,
      badgeStyle: json['badgeStyle'] as String? ?? fb.badgeStyle,
    );
  }

  factory BrandComponents.fallback() {
    return const BrandComponents(
      cardRadius: 16,
      buttonStyle: 'rounded',
      snapBorderStyle: 'solid',
      snapBorderWidth: 2,
      badgeStyle: 'filled',
    );
  }

  /// Button border radius based on buttonStyle.
  double get buttonRadius {
    switch (buttonStyle) {
      case 'pill':
        return 9999;
      case 'sharp':
        return 4;
      case 'rounded':
      default:
        return 12;
    }
  }

  /// Badge decoration based on badgeStyle.
  BoxDecoration badgeDecoration(Color color) {
    switch (badgeStyle) {
      case 'outline':
        return BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: color, width: 1.5),
          borderRadius: BorderRadius.circular(20),
        );
      case 'soft':
        return BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        );
      case 'filled':
      default:
        return BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        );
    }
  }

  /// Badge text color based on badgeStyle.
  Color badgeTextColor(Color bgColor) {
    switch (badgeStyle) {
      case 'outline':
        return bgColor;
      case 'soft':
        return bgColor;
      case 'filled':
      default:
        return bgColor.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PARSE HELPERS
// ═══════════════════════════════════════════════════════════════════════════

/// Parse a hex color string like "#FF3B1F" or "FF3B1F" into a [Color].
Color? _parseColor(dynamic value) {
  if (value == null) return null;
  final s = value.toString().trim();
  if (s.isEmpty) return null;

  // Remove leading #
  String hex = s.startsWith('#') ? s.substring(1) : s;

  // Handle 6-char (RGB) and 8-char (ARGB/RGBA)
  if (hex.length == 6) {
    hex = 'FF$hex'; // Add full opacity
  } else if (hex.length != 8) {
    return null;
  }

  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return null;
  return Color(parsed);
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  
  final s = value.toString().toLowerCase().trim();
  if (s == 'bold') return 700;
  if (s == 'normal' || s == 'regular') return 400;
  if (s == 'light') return 300;
  if (s == 'medium') return 500;
  
  return int.tryParse(s);
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  return double.tryParse(value.toString());
}

FontWeight _toFontWeight(int weight) {
  switch (weight) {
    case 100: return FontWeight.w100;
    case 200: return FontWeight.w200;
    case 300: return FontWeight.w300;
    case 400: return FontWeight.w400;
    case 500: return FontWeight.w500;
    case 600: return FontWeight.w600;
    case 700: return FontWeight.w700;
    case 800: return FontWeight.w800;
    case 900: return FontWeight.w900;
    default: return FontWeight.w700;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BRAND VIBE CONFIG — hero style, glow intensity, accent glow
// ═══════════════════════════════════════════════════════════════════════════

class BrandVibeConfig {
  final String heroStyle;     // 'dark_grid' | 'organic_light'
  final double glowIntensity; // 0.0 – 1.0
  final bool accentGlow;      // whether to show accent glow behind hero emoji

  const BrandVibeConfig({
    required this.heroStyle,
    required this.glowIntensity,
    required this.accentGlow,
  });

  factory BrandVibeConfig.fromJson(Map<String, dynamic> json) {
    final fb = BrandVibeConfig.fallback();
    return BrandVibeConfig(
      heroStyle: json['heroStyle'] as String? ?? fb.heroStyle,
      glowIntensity: _parseDouble(json['glowIntensity']) ?? fb.glowIntensity,
      accentGlow: json['accentGlow'] as bool? ?? fb.accentGlow,
    );
  }

  factory BrandVibeConfig.fallback() {
    return const BrandVibeConfig(
      heroStyle: 'organic_light',
      glowIntensity: 0.4,
      accentGlow: true,
    );
  }

  bool get isDarkHero => heroStyle == 'dark_grid';
}
