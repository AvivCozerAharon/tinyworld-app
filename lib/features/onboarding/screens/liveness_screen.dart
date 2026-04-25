import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/features/onboarding/onboarding_controller.dart';
import 'package:tinyworld_app/shared/widgets/onboarding_scaffold.dart';

class LivenessScreen extends ConsumerStatefulWidget {
  const LivenessScreen({super.key});
  @override
  ConsumerState<LivenessScreen> createState() => _LivenessScreenState();
}

class _LivenessScreenState extends ConsumerState<LivenessScreen> {
  CameraController? _cam;
  bool _isCapturing = false;
  bool _cameraFailed = false;
  String? _error;
  Uint8List? _capturedBytes;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _cameraFailed = true);
        return;
      }
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _cam = CameraController(front, ResolutionPreset.medium);
      await _cam!.initialize();
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) setState(() => _cameraFailed = true);
    }
  }

  Future<void> _capture() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      Uint8List bytes;
      if (_cam != null && _cam!.value.isInitialized) {
        final img = await _cam!.takePicture();
        bytes = await img.readAsBytes();
      } else {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 640,
          maxHeight: 640,
          imageQuality: 85,
        );
        if (picked == null) {
          setState(() => _isCapturing = false);
          return;
        }
        bytes = await picked.readAsBytes();
      }
      setState(() {
        _capturedBytes = bytes;
        _isCapturing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isCapturing = false;
      });
    }
  }

  Future<void> _pickGallery() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 640,
        maxHeight: 640,
        imageQuality: 85,
      );
      if (picked == null) {
        setState(() => _isCapturing = false);
        return;
      }
      final bytes = await picked.readAsBytes();
      setState(() {
        _capturedBytes = bytes;
        _isCapturing = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isCapturing = false;
      });
    }
  }

  Future<void> _submit(Uint8List bytes) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final state = ref.read(onboardingControllerProvider);
    final formData = FormData.fromMap({
      if (state.userId != null) 'user_id': state.userId,
      'file': MultipartFile.fromBytes(bytes, filename: 'liveness.jpg'),
    });
    try {
      final resp =
          await apiClient.postFormData('/onboarding/liveness', formData);
      final data = resp.data as Map<String, dynamic>;
      if (!(data['is_live'] as bool)) {
        setState(() {
          _error = 'Verificação falhou. Tente novamente.';
          _isCapturing = false;
        });
        return;
      }
      ref
          .read(onboardingControllerProvider.notifier)
          .setAppearance(data['appearance'] as Map<String, dynamic>);
      await _cam?.dispose();
      _cam = null;
      if (mounted) {
        context.push('/onboarding/avatar', extra: {
          'variations': data['variations'],
          'appearance': data['appearance'],
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isCapturing = false;
      });
    }
  }

  @override
  void dispose() {
    _cam?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cameraReady = _cam?.value.isInitialized ?? false;
    final confirming = _capturedBytes != null && !_isCapturing;
    return OnboardingScaffold(
      step: 5,
      totalSteps: 9,
      title: 'Verificação',
      subtitle: confirming
          ? 'Boa foto? Confirme para continuar.'
          : 'Precisamos confirmar que você é real. Uma selfie basta.',
      child: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: TwColors.card,
                  borderRadius: BorderRadius.circular(TwRadius.xl),
                  border: Border.all(color: TwColors.border),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(TwRadius.xl),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Captured photo preview
                      if (confirming)
                        Image.memory(_capturedBytes!, fit: BoxFit.cover)
                      else if (cameraReady)
                        CameraPreview(_cam!)
                      else
                        Center(
                          child: _cameraFailed
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: TwColors.surface,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: TwColors.border),
                                      ),
                                      child: const Icon(
                                          Icons.camera_alt_outlined,
                                          size: 32,
                                          color: TwColors.muted),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Câmera não disponível',
                                      style: GoogleFonts.spaceGrotesk(
                                          color: TwColors.muted, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Use a galeria abaixo',
                                      style: GoogleFonts.spaceGrotesk(
                                          color: TwColors.muted.withValues(alpha: 0.6),
                                          fontSize: 12),
                                    ),
                                  ],
                                )
                              : const CircularProgressIndicator(
                                  color: TwColors.primary),
                        ),
                      // Face oval overlay (only when camera live)
                      if (!_isCapturing && !confirming)
                        Center(
                          child: Container(
                            width: 160,
                            height: 210,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(80),
                              border: Border.all(
                                  color:
                                      TwColors.primary.withValues(alpha: 0.5),
                                  width: 2),
                            ),
                          ),
                        ),
                      // Processing overlay
                      if (_isCapturing)
                        Container(
                          color: TwColors.bg.withValues(alpha: 0.85),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                    color: TwColors.primary),
                                const SizedBox(height: 16),
                                Text(
                                  'Verificando...',
                                  style: GoogleFonts.spaceGrotesk(
                                      color: TwColors.onSurface, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TwColors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(TwRadius.md),
                  border: Border.all(
                      color: TwColors.error.withValues(alpha: 0.3)),
                ),
                child: Text(_error!,
                    style: GoogleFonts.spaceGrotesk(
                        color: TwColors.error, fontSize: 13)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                if (confirming) ...[
                  // Confirm button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: TwGradients.primary,
                        borderRadius: BorderRadius.circular(TwRadius.lg),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _submit(_capturedBytes!),
                          borderRadius: BorderRadius.circular(TwRadius.lg),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_outline,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Usar essa foto',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Retake button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _capturedBytes = null),
                      icon: const Icon(Icons.camera_alt_outlined,
                          color: TwColors.primary),
                      label: Text(
                        'Tirar novamente',
                        style: GoogleFonts.spaceGrotesk(
                            color: TwColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: TwColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(TwRadius.lg)),
                      ),
                    ),
                  ),
                ] else ...[
                  if (cameraReady)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: TwGradients.primary,
                          borderRadius: BorderRadius.circular(TwRadius.lg),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isCapturing ? null : _capture,
                            borderRadius: BorderRadius.circular(TwRadius.lg),
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.camera_alt_outlined,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tirar selfie',
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_cameraFailed || kIsWeb) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isCapturing ? null : _pickGallery,
                        icon: const Icon(Icons.photo_library_outlined,
                            color: TwColors.primary),
                        label: Text(
                          'Escolher da galeria',
                          style: GoogleFonts.spaceGrotesk(
                              color: TwColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: TwColors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(TwRadius.lg)),
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
