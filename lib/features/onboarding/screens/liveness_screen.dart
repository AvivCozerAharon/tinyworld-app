import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';
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
      await _submit(bytes);
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
      await _submit(await picked.readAsBytes());
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
      if (mounted) {
        context.go('/onboarding/avatar', extra: {
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
    return OnboardingScaffold(
      step: 5,
      totalSteps: 9,
      title: 'Verificação',
      subtitle: 'Precisamos confirmar que você é real. Uma selfie basta.',
      child: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (cameraReady)
                        CameraPreview(_cam!)
                      else
                        Center(
                          child: _cameraFailed
                              ? const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.camera_alt_outlined,
                                        size: 56, color: Color(0xFFD1D5DB)),
                                    SizedBox(height: 12),
                                    Text(
                                      'Câmera não disponível',
                                      style: TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 14),
                                    ),
                                  ],
                                )
                              : const CircularProgressIndicator(
                                  color: Color(0xFF1B76F2)),
                        ),
                      if (!_isCapturing)
                        Center(
                          child: Container(
                            width: 160,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(80),
                              border: Border.all(
                                  color: const Color(0xFF1B76F2)
                                      .withValues(alpha: 0.3),
                                  width: 2),
                            ),
                          ),
                        ),
                      if (_isCapturing)
                        Container(
                          color: Colors.white.withValues(alpha: 0.8),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                    color: Color(0xFF1B76F2)),
                                SizedBox(height: 12),
                                Text('Verificando...',
                                    style: TextStyle(
                                        color: Color(0xFF6B7280),
                                        fontSize: 14)),
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
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(_error!,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                if (cameraReady)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isCapturing ? null : _capture,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Tirar selfie'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1B76F2),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
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
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Escolher da galeria'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B7280),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
