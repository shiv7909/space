import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:ui';
import '../../services/space_service.dart';
// import '../spaces/screens/premium_upgrade_screen.dart';

class QRScannerView extends StatefulWidget {
  final String? spaceId; // The space to add the member to
  /// When true, the scanner only extracts the user ID and returns it
  /// without trying to add them to a space or showing space-type picker.
  final bool searchOnly;

  const QRScannerView({super.key, this.spaceId, this.searchOnly = false});

  @override
  State<QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends State<QRScannerView> {
  late final MobileScannerController cameraController;
  bool isProcessing = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController(
      autoStart: true,
      torchEnabled: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Scanner — mobile_scanner v5 requests permission automatically
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (!isProcessing) {
                for (final barcode in capture.barcodes) {
                  if (barcode.rawValue != null) {
                    _handleScannedCode(barcode.rawValue!);
                    break;
                  }
                }
              }
            },
            errorBuilder: (context, error, child) {
              // Permission denied or camera error
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Camera Access Needed',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Please allow camera access so you can scan QR codes.',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await cameraController.start();
                          },
                          icon: const Icon(Icons.camera_alt_rounded),
                          label: Text(
                            'Allow Camera Access',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6B6BE0),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white54,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),
                  // Flash button — only active once controller is running
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: GestureDetector(
                          onTap: () async {
                            try {
                              await cameraController.toggleTorch();
                              setState(() => _torchOn = !_torchOn);
                            } catch (_) {}
                          },
                          child: Row(
                            children: [
                              Icon(
                                _torchOn
                                    ? Icons.flash_on
                                    : Icons.flash_off,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Flash',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scan frame overlay
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: List.generate(4, (index) {
                  return Positioned(
                    top: index < 2 ? 0 : null,
                    bottom: index >= 2 ? 0 : null,
                    left: index % 2 == 0 ? 0 : null,
                    right: index % 2 == 1 ? 0 : null,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        border: Border(
                          top: index < 2
                              ? const BorderSide(color: Color(0xFF6B6BE0), width: 4)
                              : BorderSide.none,
                          bottom: index >= 2
                              ? const BorderSide(color: Color(0xFF6B6BE0), width: 4)
                              : BorderSide.none,
                          left: index % 2 == 0
                              ? const BorderSide(color: Color(0xFF6B6BE0), width: 4)
                              : BorderSide.none,
                          right: index % 2 == 1
                              ? const BorderSide(color: Color(0xFF6B6BE0), width: 4)
                              : BorderSide.none,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          // Bottom instructions
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Scan QR code to connect',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static final _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  String? _extractUserId(String code) {
    final trimmed = code.trim();
    if (trimmed.startsWith('habitz://profile/')) {
      final id = trimmed.replaceFirst('habitz://profile/', '');
      if (_uuidRegex.hasMatch(id)) return id;
      return null;
    }
    if (_uuidRegex.hasMatch(trimmed)) return trimmed;
    return null;
  }

  void _handleScannedCode(String code) async {
    if (isProcessing) return;
    setState(() => isProcessing = true);
    await cameraController.stop();
    HapticFeedback.mediumImpact();

    final userId = _extractUserId(code);

    if (userId != null) {
      if (widget.searchOnly) {
        Navigator.pop(context, {'userId': userId});
        return;
      }
      if (widget.spaceId != null) {
        await _handleMemberScan(userId, widget.spaceId!);
      } else {
        await _showSpaceTypeDialog(userId);
      }
    } else {
      _showErrorSnackBar('Invalid QR code. Please scan a Habitz user QR.');
      setState(() => isProcessing = false);
      await cameraController.start();
    }
  }

  Future<void> _handleMemberScan(String scannedUserId, String spaceId) async {
    try {
      final spaceService = context.read<SpaceService>();
      // Use the new invite flow instead of direct add
      final response = await spaceService.sendInviteByScan(
        userId: scannedUserId,
        spaceId: spaceId,
      );

      if (!mounted) return;

      final bool success = response['success'] == true;
      final String message = response['message'] as String? ?? 'Unknown error';
      final String? code = response['code'] as String?;

      if (success) {
        _showSuccessSnackBar(message);
        Navigator.pop(context, {'success': true, 'invite_sent': true, 'userId': scannedUserId});
      } else if (code == 'NOT_PREMIUM') {
        _showErrorSnackBar('Premium upgrade currently unavailable.');
        setState(() => isProcessing = false);
        await cameraController.start();
      } else if (code == 'ALREADY_MEMBER' || code == 'INVITE_PENDING') {
        _showErrorSnackBar(message);
        setState(() => isProcessing = false);
        await cameraController.start();
      } else {
        _showErrorSnackBar(message);
        setState(() => isProcessing = false);
        await cameraController.start();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('An unexpected error occurred: ${e.toString()}');
        setState(() => isProcessing = false);
        await cameraController.start();
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: const Color(0xFF4CAF50),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    ));
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: const Color(0xFFE53935),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 4),
    ));
  }

  Future<void> _showSpaceTypeDialog(String userId) async {
    final spaceType = await showDialog<String>(
      context: context,
      builder: (context) => _SpaceTypeDialog(),
    );
    if (spaceType != null && mounted) {
      Navigator.pop(context, {'userId': userId, 'spaceType': spaceType});
    } else {
      setState(() => isProcessing = false);
      await cameraController.start();
    }
  }

  void _showExclusivityWarningDialog(String spaceName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Exclusive Space Alert'),
        content: Text(
          'You are already a member of another space: "$spaceName". Please leave the current space before joining a new one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

class _SpaceTypeDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.group_add, size: 60, color: Color(0xFF6B6BE0)),
                const SizedBox(height: 16),
                Text(
                  'Create a Space',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'What type of space would you like to create?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF5A5A5A),
                  ),
                ),
                const SizedBox(height: 24),
                _SpaceTypeOption(
                  icon: Icons.favorite,
                  title: 'Couple',
                  description: 'Share habits with your partner',
                  color: const Color(0xFFFF6B6B),
                  onTap: () => Navigator.pop(context, 'couple'),
                ),
                const SizedBox(height: 12),
                _SpaceTypeOption(
                  icon: Icons.groups,
                  title: 'Group',
                  description: 'Share habits with multiple people',
                  color: const Color(0xFF6B6BE0),
                  onTap: () => Navigator.pop(context, 'group'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF5A5A5A),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpaceTypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _SpaceTypeOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Color(0xFF5A5A5A),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
