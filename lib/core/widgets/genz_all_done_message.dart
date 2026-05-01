import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../../Features/solo/constants/solo_constants.dart';

class GenZAllDoneMessage extends StatelessWidget {
  const GenZAllDoneMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 10.rs(context)),
      padding: EdgeInsets.symmetric(
        horizontal: 16.rs(context),
        vertical: 16.rs(context),
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20.rs(context)),
        border: Border.all(
          color: AppTheme.outline.withValues(alpha: 0.36),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10.rs(context),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 9.rs(context),
              vertical: 4.rs(context),
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'ALL DONE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5.rs(context),
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
                letterSpacing: 0.5,
                height: 1,
              ),
            ),
          ),
          SizedBox(height: 8.rs(context)),
          Container(
            padding: EdgeInsets.all(9.rs(context)),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.095),
              shape: BoxShape.circle,
            ),
            child: Text('🔥', style: TextStyle(fontSize: 18.rs(context))),
          ),
          SizedBox(height: 8.rs(context)),
          Text(
            'Crushed It. No Cap.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15.rs(context),
              fontWeight: FontWeight.w800,
              color: AppTheme.onBackground,
              letterSpacing: -0.2,
              height: 1.2,
            ),
          ),
          SizedBox(height: 3.rs(context)),
          Text(
            'You closed every goal today.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.25.rs(context),
              fontWeight: FontWeight.w500,
              color: AppTheme.onSurfaceVariant,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
