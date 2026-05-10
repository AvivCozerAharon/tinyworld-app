import 'dart:typed_data';
import 'package:flutter/material.dart';

class PhotoViewer extends StatefulWidget {
  final Uint8List imageBytes;
  final String? heroTag;

  const PhotoViewer({
    super.key,
    required this.imageBytes,
    this.heroTag,
  });

  static Future<void> show(BuildContext context, Uint8List bytes, {String? heroTag}) {
    return Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (ctx, anim, secAnim) => FadeTransition(
          opacity: anim,
          child: PhotoViewer(imageBytes: bytes, heroTag: heroTag),
        ),
      ),
    );
  }

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  final TransformationController _transformCtrl = TransformationController();

  @override
  void dispose() {
    _transformCtrl.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    final matrix = _transformCtrl.value;
    final scale = matrix.getMaxScaleOnAxis();
    if (scale > 1.0) {
      _transformCtrl.value = Matrix4.identity();
    } else {
      _transformCtrl.value = Matrix4.identity()..scale(3.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: GestureDetector(
          onDoubleTap: _onDoubleTap,
          child: InteractiveViewer(
            transformationController: _transformCtrl,
            minScale: 0.5,
            maxScale: 5.0,
            child: widget.heroTag != null
                ? Hero(
                    tag: widget.heroTag!,
                    child: Image.memory(
                      widget.imageBytes,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
                  )
                : Image.memory(
                    widget.imageBytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
