import 'dart:io';
import 'dart:ui' as ui;
import 'package:camera/camera.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:saifix/helper/custom_print_helper.dart';
import '../core/app_colors.dart';

/// Custom camera screen with an ID-card-sized overlay frame.
/// Returns the path of the taken photo as a [String] via [Navigator.pop].
class IdCameraScreen extends StatefulWidget {
  final String title; // e.g. 'صورة الهوية الأمامية'

  const IdCameraScreen({super.key, required this.title});

  @override
  State<IdCameraScreen> createState() => _IdCameraScreenState();
}

class _IdCameraScreenState extends State<IdCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isTaking = false;
  String? _errorMsg;

  // Flash modes cycle
  FlashMode _flashMode = FlashMode.off;
  final _flashIcons = [
    (FlashMode.off, Icons.flash_off_rounded),
    (FlashMode.torch, Icons.flash_on_rounded),
    (FlashMode.auto, Icons.flash_auto_rounded),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Force landscape? No — keep portrait, card frame fits the screen better in portrait
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _errorMsg = 'no_camera_available'.tr());
        return;
      }
      final back = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );
      _controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await _controller!.initialize();
      await _controller!.setFlashMode(_flashMode);
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      setState(() => _errorMsg = 'camera_init_error'.tr(args: [e.toString()]));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _cycleFlash() async {
    final currentIdx = _flashIcons.indexWhere((f) => f.$1 == _flashMode);
    final next = _flashIcons[(currentIdx + 1) % _flashIcons.length];
    setState(() => _flashMode = next.$1);
    await _controller?.setFlashMode(next.$1);
  }

  Future<void> _takePicture(
    double frameLeft,
    double frameTop,
    double frameWidth,
    double frameHeight,
    double previewWidth,
    double previewHeight,
  ) async {
    if (_controller == null || !_controller!.value.isInitialized || _isTaking) {
      return;
    }
    setState(() => _isTaking = true);

    try {
      // Take full photo
      final XFile photo = await _controller!.takePicture();

      // ── Crop to card frame area ──────────────────────────────────────────
      final imageBytes = await photo.readAsBytes();
      final fullImage = await decodeImageFromList(imageBytes);

      final double scaleX = fullImage.width / previewWidth;
      final double scaleY = fullImage.height / previewHeight;

      final cropX = (frameLeft * scaleX).round().clamp(0, fullImage.width);
      final cropY = (frameTop * scaleY).round().clamp(0, fullImage.height);
      final cropW = (frameWidth * scaleX).round().clamp(
        1,
        fullImage.width - cropX,
      );
      final cropH = (frameHeight * scaleY).round().clamp(
        1,
        fullImage.height - cropY,
      );

      // Use dart:ui to crop
      final recorder = _createCropRecorder();
      final canvas = recorder.$1;
      final pictureRecorder = recorder.$2;

      canvas.drawImageRect(
        fullImage,
        Rect.fromLTWH(
          cropX.toDouble(),
          cropY.toDouble(),
          cropW.toDouble(),
          cropH.toDouble(),
        ),
        Rect.fromLTWH(0, 0, cropW.toDouble(), cropH.toDouble()),
        Paint(),
      );

      final picture = pictureRecorder.endRecording();
      final croppedImg = await picture.toImage(cropW, cropH);
      final pngBytes = await croppedImg.toByteData(
        format: ui.ImageByteFormat.png,
      );

      // Save cropped image
      final tmpDir = Directory.systemTemp;
      final croppedFile = File(
        '${tmpDir.path}/id_cropped_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await croppedFile.writeAsBytes(pngBytes!.buffer.asUint8List());

      if (mounted) Navigator.pop(context, croppedFile.path);
    } catch (e) {
      customPrint('Camera capture error: $e');
      // Fallback: return original uncropped path
      try {
        final photo = await _controller!.takePicture();
        if (mounted) Navigator.pop(context, photo.path);
      } catch (_) {}
    } finally {
      if (mounted) setState(() => _isTaking = false);
    }
  }

  /// Helper: creates a canvas for cropping using dart:ui PictureRecorder
  (ui.Canvas, ui.PictureRecorder) _createCropRecorder() {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    return (canvas, recorder);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body:
          _errorMsg != null
              ? _buildError()
              : !_isInitialized
              ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
              : _buildCamera(),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.camera_alt_outlined,
            color: Colors.white54,
            size: 64,
          ),
          const SizedBox(height: 20),
          Text(
            _errorMsg!,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.white30),
            ),
            child: Text(
              'back'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildCamera() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = constraints.maxWidth;
        final screenH = constraints.maxHeight;

        // Card frame: credit-card aspect ratio 85.6mm × 54mm ≈ 1.586
        const cardAspect = 85.6 / 54.0;
        final frameW =
            screenW * 0.82; // 82% of screen width matches real card size
        final frameH = frameW / cardAspect;
        final frameLeft = (screenW - frameW) / 2;
        final frameTop = (screenH - frameH) / 2 - 40; // slightly above center

        return Stack(
          children: [
            // ── Full-screen camera preview ──────────────────────────────
            Positioned.fill(child: CameraPreview(_controller!)),

            // ── Dark overlay with hole for card frame ───────────────────
            Positioned.fill(
              child: CustomPaint(
                painter: _CardFramePainter(
                  frameRect: Rect.fromLTWH(frameLeft, frameTop, frameW, frameH),
                ),
              ),
            ),

            // ── Top bar ─────────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back
                      _glassButton(
                        icon: Icons.close_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      // Title
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Flash
                      _glassButton(
                        icon:
                            _flashIcons
                                .firstWhere((f) => f.$1 == _flashMode)
                                .$2,
                        onTap: _cycleFlash,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Guide text ──────────────────────────────────────────────
            Positioned(
              top: frameTop - 50,
              left: 0,
              right: 0,
              child: Text(
                'place_card_hint'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  shadows: [
                    Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 8),
                  ],
                ),
              ),
            ),

            // ── Capture button + company branding ────────────────────────────
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  // Capture button
                  GestureDetector(
                    onTap:
                        _isTaking
                            ? null
                            : () => _takePicture(
                              frameLeft,
                              frameTop,
                              frameW,
                              frameH,
                              screenW,
                              screenH,
                            ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: _isTaking ? 64 : 72,
                      height: _isTaking ? 64 : 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isTaking ? Colors.white54 : Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue.withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child:
                          _isTaking
                              ? const Padding(
                                padding: EdgeInsets.all(18),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                              : Container(
                                margin: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColors.primaryBlue,
                                    width: 3,
                                  ),
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // ─── Company branding ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipOval(
                        child: Image.asset(
                          'logo_circle.png',
                          width: 28,
                          height: 28,
                          errorBuilder:
                              (_, __, ___) => const SizedBox(width: 28),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'branding_text'.tr(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _glassButton({required IconData icon, required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
}

/// Painter that draws a dark overlay with a transparent rectangular "hole"
/// and animated corner brackets (like QR scanner).
class _CardFramePainter extends CustomPainter {
  final Rect frameRect;

  const _CardFramePainter({required this.frameRect});

  @override
  void paint(Canvas canvas, Size size) {
    // Dark overlay
    final overlayPaint = Paint()..color = Colors.black.withValues(alpha: 0.62);

    // Draw overlay as 4 rects around the frame hole
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, frameRect.top),
      overlayPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        0,
        frameRect.bottom,
        size.width,
        size.height - frameRect.bottom,
      ),
      overlayPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, frameRect.top, frameRect.left, frameRect.height),
      overlayPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        frameRect.right,
        frameRect.top,
        size.width - frameRect.right,
        frameRect.height,
      ),
      overlayPaint,
    );

    // Frame border (subtle full rectangle)
    final borderPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(8)),
      borderPaint,
    );

    // Corner brackets
    const cornerLen = 28.0;
    const cornerRadius = 8.0;
    const thickness = 3.5;
    final cornerPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness
          ..strokeCap = StrokeCap.round;

    final corners = [
      // Top-left
      (frameRect.topLeft, 1.0, 1.0),
      // Top-right
      (frameRect.topRight, -1.0, 1.0),
      // Bottom-left
      (frameRect.bottomLeft, 1.0, -1.0),
      // Bottom-right
      (frameRect.bottomRight, -1.0, -1.0),
    ];

    for (final (origin, dx, dy) in corners) {
      final path = Path();
      path.moveTo(origin.dx + dx * cornerLen, origin.dy);
      path.lineTo(origin.dx + dx * cornerRadius, origin.dy);
      path.arcToPoint(
        Offset(origin.dx, origin.dy + dy * cornerRadius),
        radius: const Radius.circular(cornerRadius),
        clockwise: dx * dy < 0,
      );
      path.lineTo(origin.dx, origin.dy + dy * cornerLen);
      canvas.drawPath(path, cornerPaint);
    }
  }

  @override
  bool shouldRepaint(_CardFramePainter old) => old.frameRect != frameRect;
}
