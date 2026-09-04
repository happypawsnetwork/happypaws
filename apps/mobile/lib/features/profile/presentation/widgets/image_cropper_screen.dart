import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Interactive 1:1 circular image cropper with locked boundaries and grid lines.
class ImageCropperScreen extends StatefulWidget {
  final File imageFile;

  const ImageCropperScreen({super.key, required this.imageFile});

  static Future<File?> cropImage(BuildContext context, File imageFile) {
    return Navigator.of(context).push<File?>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ImageCropperScreen(imageFile: imageFile),
      ),
    );
  }

  @override
  State<ImageCropperScreen> createState() => _ImageCropperScreenState();
}

class _ImageCropperScreenState extends State<ImageCropperScreen> {
  ui.Image? _loadedImage;
  bool _isLoading = true;
  bool _isExporting = false;

  int _rotationQuarterTurns = 0;
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  double _baseScale = 1.0;
  Offset _baseOffset = Offset.zero;
  Offset _focalStart = Offset.zero;

  Size _viewportSize = Size.zero;
  double _cropDiameter = 280.0;
  bool _hasInitializedScale = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _loadedImage = frame.image;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load image for cropping')),
        );
      }
    }
  }

  double get _curImgWidth {
    if (_loadedImage == null) return 1.0;
    return (_rotationQuarterTurns % 2 == 0)
        ? _loadedImage!.width.toDouble()
        : _loadedImage!.height.toDouble();
  }

  double get _curImgHeight {
    if (_loadedImage == null) return 1.0;
    return (_rotationQuarterTurns % 2 == 0)
        ? _loadedImage!.height.toDouble()
        : _loadedImage!.width.toDouble();
  }

  double _calcMinScale(double cropDiameter) {
    if (_curImgWidth <= 0 || _curImgHeight <= 0) return 1.0;
    return math.max(cropDiameter / _curImgWidth, cropDiameter / _curImgHeight);
  }

  double _calcMaxScale(double cropDiameter) {
    return _calcMinScale(cropDiameter) * 6.0;
  }

  void _clampOffsetAndScale() {
    final minScale = _calcMinScale(_cropDiameter);
    final maxScale = _calcMaxScale(_cropDiameter);
    _scale = _scale.clamp(minScale, maxScale);

    final maxDx = (_curImgWidth * _scale - _cropDiameter) / 2;
    final maxDy = (_curImgHeight * _scale - _cropDiameter) / 2;

    _offset = Offset(
      _offset.dx.clamp(-math.max(0.0, maxDx), math.max(0.0, maxDx)),
      _offset.dy.clamp(-math.max(0.0, maxDy), math.max(0.0, maxDy)),
    );
  }

  void _initSizing(Size size) {
    _viewportSize = size;
    final minSide = math.min(size.width, size.height);
    _cropDiameter = (minSide * 0.76).clamp(180.0, 360.0);

    final minScale = _calcMinScale(_cropDiameter);
    if (!_hasInitializedScale) {
      _scale = minScale;
      _offset = Offset.zero;
      _hasInitializedScale = true;
    } else {
      _clampOffsetAndScale();
    }
  }

  void _rotateRight() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
      _scale = _calcMinScale(_cropDiameter);
      _offset = Offset.zero;
    });
  }

  void _rotateLeft() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 3) % 4;
      _scale = _calcMinScale(_cropDiameter);
      _offset = Offset.zero;
    });
  }

  void _resetTransform() {
    setState(() {
      _rotationQuarterTurns = 0;
      _scale = _calcMinScale(_cropDiameter);
      _offset = Offset.zero;
    });
  }

  void _zoomIn() {
    setState(() {
      _scale *= 1.25;
      _clampOffsetAndScale();
    });
  }

  void _zoomOut() {
    setState(() {
      _scale /= 1.25;
      _clampOffsetAndScale();
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _baseScale = _scale;
    _baseOffset = _offset;
    _focalStart = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final minScale = _calcMinScale(_cropDiameter);
    final maxScale = _calcMaxScale(_cropDiameter);
    final newScale = (_baseScale * details.scale).clamp(minScale, maxScale);

    final delta = details.localFocalPoint - _focalStart;
    final center = Offset(_viewportSize.width / 2, _viewportSize.height / 2);
    final focalToCenter = details.localFocalPoint - center;

    final newOffset =
        _baseOffset +
        delta +
        (focalToCenter - _baseOffset) * (1 - (newScale / _baseScale));

    final maxDx = (_curImgWidth * newScale - _cropDiameter) / 2;
    final maxDy = (_curImgHeight * newScale - _cropDiameter) / 2;

    setState(() {
      _scale = newScale;
      _offset = Offset(
        newOffset.dx.clamp(-math.max(0.0, maxDx), math.max(0.0, maxDx)),
        newOffset.dy.clamp(-math.max(0.0, maxDy), math.max(0.0, maxDy)),
      );
    });
  }

  Future<void> _handleCrop() async {
    if (_loadedImage == null || _isExporting) return;

    setState(() => _isExporting = true);

    try {
      const exportSize = 800.0;
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        const Rect.fromLTWH(0, 0, exportSize, exportSize),
      );

      final exportScale = exportSize / _cropDiameter;
      canvas.scale(exportScale, exportScale);

      final center = Offset(_viewportSize.width / 2, _viewportSize.height / 2);
      final cropLeft = center.dx - _cropDiameter / 2;
      final cropTop = center.dy - _cropDiameter / 2;

      canvas.translate(-cropLeft, -cropTop);
      canvas.translate(center.dx + _offset.dx, center.dy + _offset.dy);
      canvas.rotate(_rotationQuarterTurns * (math.pi / 2));
      canvas.scale(_scale, _scale);

      final imgW = _loadedImage!.width.toDouble();
      final imgH = _loadedImage!.height.toDouble();
      canvas.drawImage(
        _loadedImage!,
        Offset(-imgW / 2, -imgH / 2),
        Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.high,
      );

      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(
        exportSize.toInt(),
        exportSize.toInt(),
      );
      final byteData = await croppedImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('Failed to generate cropped image bytes');
      }

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = Directory.systemTemp;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final targetFile = File('${tempDir.path}/cropped_avatar_$timestamp.png');
      await targetFile.writeAsBytes(pngBytes);

      if (mounted) {
        Navigator.of(context).pop(targetFile);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error cropping image: ')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Crop photo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          if (!_isLoading && _loadedImage != null)
            TextButton(
              onPressed: _isExporting ? null : _handleCrop,
              child: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _loadedImage == null
          ? const Center(
              child: Text(
                'Could not load image',
                style: TextStyle(color: Colors.white),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(
                  constraints.maxWidth,
                  constraints.maxHeight - 90,
                );
                _initSizing(size);

                return Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onScaleStart: _onScaleStart,
                        onScaleUpdate: _onScaleUpdate,
                        child: ClipRect(
                          child: CustomPaint(
                            size: size,
                            painter: _CropperCanvasPainter(
                              image: _loadedImage!,
                              scale: _scale,
                              offset: _offset,
                              rotationQuarterTurns: _rotationQuarterTurns,
                              cropDiameter: _cropDiameter,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _buildControlsBar(),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildControlsBar() {
    return Container(
      height: 90,
      color: const Color(0xFF121212),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(
              Icons.rotate_left_rounded,
              color: Colors.white,
              size: 26,
            ),
            tooltip: 'Rotate left',
            onPressed: _rotateLeft,
          ),
          IconButton(
            icon: const Icon(
              Icons.zoom_out_rounded,
              color: Colors.white,
              size: 26,
            ),
            tooltip: 'Zoom out',
            onPressed: _zoomOut,
          ),
          IconButton(
            icon: const Icon(
              Icons.restart_alt_rounded,
              color: Colors.white70,
              size: 24,
            ),
            tooltip: 'Reset',
            onPressed: _resetTransform,
          ),
          IconButton(
            icon: const Icon(
              Icons.zoom_in_rounded,
              color: Colors.white,
              size: 26,
            ),
            tooltip: 'Zoom in',
            onPressed: _zoomIn,
          ),
          IconButton(
            icon: const Icon(
              Icons.rotate_right_rounded,
              color: Colors.white,
              size: 26,
            ),
            tooltip: 'Rotate right',
            onPressed: _rotateRight,
          ),
        ],
      ),
    );
  }
}

class _CropperCanvasPainter extends CustomPainter {
  final ui.Image image;
  final double scale;
  final Offset offset;
  final int rotationQuarterTurns;
  final double cropDiameter;

  _CropperCanvasPainter({
    required this.image,
    required this.scale,
    required this.offset,
    required this.rotationQuarterTurns,
    required this.cropDiameter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = cropDiameter / 2;
    final cropRect = Rect.fromCircle(center: center, radius: radius);

    // 1. Draw the image with center translation, rotation, and scaling
    canvas.save();
    canvas.translate(center.dx + offset.dx, center.dy + offset.dy);
    canvas.rotate(rotationQuarterTurns * (math.pi / 2));
    canvas.scale(scale, scale);

    final imgW = image.width.toDouble();
    final imgH = image.height.toDouble();
    canvas.drawImage(
      image,
      Offset(-imgW / 2, -imgH / 2),
      Paint()
        ..isAntiAlias = true
        ..filterQuality = FilterQuality.high,
    );
    canvas.restore();

    // 2. Draw darkened overlay around the circle
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final circlePath = Path()..addOval(cropRect);
    final dimmedPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      circlePath,
    );

    final dimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawPath(dimmedPath, dimPaint);

    // 3. Draw white circle border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, radius, borderPaint);

    // 4. Draw 3x3 Rule-of-thirds grid lines clipped inside circle
    canvas.save();
    canvas.clipPath(circlePath);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final oneThird = cropDiameter / 3;
    final left = cropRect.left;
    final top = cropRect.top;

    // Vertical lines
    canvas.drawLine(
      Offset(left + oneThird, top),
      Offset(left + oneThird, top + cropDiameter),
      gridPaint,
    );
    canvas.drawLine(
      Offset(left + oneThird * 2, top),
      Offset(left + oneThird * 2, top + cropDiameter),
      gridPaint,
    );

    // Horizontal lines
    canvas.drawLine(
      Offset(left, top + oneThird),
      Offset(left + cropDiameter, top + oneThird),
      gridPaint,
    );
    canvas.drawLine(
      Offset(left, top + oneThird * 2),
      Offset(left + cropDiameter, top + oneThird * 2),
      gridPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CropperCanvasPainter oldDelegate) {
    return oldDelegate.scale != scale ||
        oldDelegate.offset != offset ||
        oldDelegate.rotationQuarterTurns != rotationQuarterTurns ||
        oldDelegate.cropDiameter != cropDiameter ||
        oldDelegate.image != image;
  }
}
