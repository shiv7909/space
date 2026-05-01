import re

file1 = 'lib/Features/shared/sticky_action_buttons.dart'
try:
    with open(file1, 'r', encoding='utf-8') as f:
        t = f.read()

    t = t.replace(
        "import '../../core/routes/app_router.dart';",
        "import '../../core/routes/app_router.dart';\nimport '../../core/theme/app_theme.dart';"
    )

    old_dec = """    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(const Color(0xFF0F0A20), const Color(0xFF1a0f35), 0.5)!,
            Color.lerp(const Color(0xFF1a0f35), const Color(0xFF0d0515), 0.5)!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _accentColor.withValues(alpha: 0.15),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            "SPACE",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),"""

    new_dec = """    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: AppTheme.background,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            "SPACE",
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.onBackground,
              letterSpacing: 1.2,
            ),
          ),"""

    t = t.replace(old_dec, new_dec)
    
    with open(file1, 'w', encoding='utf-8') as f:
        f.write(t)
    print("sticky action buttons replaced successfully.")
except Exception as e:
    print(e)
