import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'dart:io';
import '../../../gen/assets.gen.dart';
import '../../../models/user_model.dart';

class JoinSpacePopup extends StatelessWidget {
  final UserModel user;
  final String? avatarUrl;

  const JoinSpacePopup({super.key, required this.user, this.avatarUrl});

  // Global key for capturing the widget as image
  final GlobalKey _qrKey = const GlobalObjectKey('qr_with_avatar');

  @override
  Widget build(BuildContext context) {
    // QR Code contains ONLY user ID
    final String qrData = user.id;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: SvgPicture.asset(Assets.svg.doubleChevronDown),
                ),
              ),
              const SizedBox(height: 8),

              // Content to capture (Avatar + QR Code)
              RepaintBoundary(
                key: _qrKey,
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Avatar (no edit button)
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: const Color(0x6BE0D2),
                        backgroundImage:
                            avatarUrl != null
                                ? CachedNetworkImageProvider(avatarUrl!)
                                : (user.avatarUrl != null
                                    ? CachedNetworkImageProvider(
                                      user.avatarUrl!,
                                    )
                                    : null),
                        child:
                            avatarUrl == null && user.avatarUrl == null
                                ? Text(
                                  user.displayName?.isNotEmpty == true
                                      ? user.displayName![0].toUpperCase()
                                      : 'U',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 32,
                                  ),
                                )
                                : null,
                      ),
                      const SizedBox(height: 16),

                      // Name
                      Text(
                        user.displayName ?? 'User',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // QR Code
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF6B6BE0),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF2D2D2D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Instruction text
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B6BE0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.qr_code_scanner,
                      color: Color(0xFF6B6BE0),
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF5A5A5A),
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(text: 'Share this QR with a '),
                          TextSpan(
                            text: 'Premium user',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF6B6BE0),
                            ),
                          ),
                          const TextSpan(
                            text:
                                ' who has a space\nto get added to their group!',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Social Media Sharing Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      'Share via:',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF5A5A5A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _SocialShareButton(
                          iconWidget: SvgPicture.asset(
                            Assets.svg.whatsApp,
                            fit: BoxFit.contain,
                            width: 28,
                            height: 28,
                          ),
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                          onTap: () => _shareQRImage(context, 'whatsapp'),
                        ),
                        _SocialShareButton(
                          iconWidget: const Icon(
                            Icons.telegram,
                            color: Color(0xFF0088CC),
                            size: 28,
                          ),
                          label: 'Telegram',
                          color: const Color(0xFF0088CC),
                          onTap: () => _shareQRImage(context, 'telegram'),
                        ),
                        _SocialShareButton(
                          iconWidget: const Icon(
                            Icons.share,
                            color: Color(0xFF5A5A5A),
                            size: 28,
                          ),
                          label: 'More',
                          color: const Color(0xFF5A5A5A),
                          onTap: () => _shareQRImage(context, 'general'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareQRImage(BuildContext context, String platform) async {
    try {
      // Capture the widget as image
      RenderRepaintBoundary boundary =
          _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      var byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      var pngBytes = byteData!.buffer.asUint8List();

      // Save to temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/habitz_qr_${user.id}.png');
      await file.writeAsBytes(pngBytes);

      // Share message
      final String message =
          'Add me to your Space! Scan my QR code to add me to your group. 🚀';

      if (platform == 'whatsapp') {
        await _shareViaWhatsApp(context, file.path, message);
      } else if (platform == 'telegram') {
        await _shareViaTelegram(context, file.path, message);
      } else {
        // General share
        await Share.shareXFiles([XFile(file.path)], text: message);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    }
  }

  Future<void> _shareViaWhatsApp(
    BuildContext context,
    String imagePath,
    String message,
  ) async {
    try {
      await Share.shareXFiles([XFile(imagePath)], text: message);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share via WhatsApp')),
        );
      }
    }
  }

  Future<void> _shareViaTelegram(
    BuildContext context,
    String imagePath,
    String message,
  ) async {
    try {
      await Share.shareXFiles([XFile(imagePath)], text: message);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to share via Telegram')),
        );
      }
    }
  }
}

class _SocialShareButton extends StatelessWidget {
  final Widget iconWidget;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialShareButton({
    required this.iconWidget,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: iconWidget,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5A5A5A),
            ),
          ),
        ],
      ),
    );
  }
}
