import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/features/onboarding/onboarding_controller.dart';
import 'package:tinyworld_app/shared/widgets/onboarding_scaffold.dart';

class PhotosScreen extends ConsumerStatefulWidget {
  const PhotosScreen({super.key});

  @override
  ConsumerState<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends ConsumerState<PhotosScreen> {
  final List<String?> _slots = [null, null, null];
  final List<bool> _uploading = [false, false, false];
  final _picker = ImagePicker();

  bool get _canContinue => _slots.any((s) => s != null);

  Future<Uint8List> _compress(Uint8List bytes) async {
    if (kIsWeb) return bytes;
    return await FlutterImageCompress.compressWithList(
      bytes,
      minWidth: 800,
      minHeight: 800,
      quality: 80,
      format: CompressFormat.jpeg,
    );
  }

  Future<void> _pickPhoto(int index) async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => _uploading[index] = true);
    try {
      final bytes = await file.readAsBytes();
      final compressed = await _compress(bytes);
      setState(() => _slots[index] = base64Encode(compressed));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading[index] = false);
    }
  }

  void _removePhoto(int index) => setState(() => _slots[index] = null);

  Future<void> _continue() async {
    final photos = _slots.whereType<String>().toList();
    final ok = await ref.read(onboardingControllerProvider.notifier).savePhotos(photos);
    if (ok && mounted) context.push('/onboarding/hobbies');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    return OnboardingScaffold(
      step: 7,
      totalSteps: 9,
      title: 'Suas fotos',
      subtitle: 'Só visíveis para quem você humanizar. Mínimo 1 foto.',
      bottom: OnboardingButton(
        onPressed: _canContinue ? _continue : null,
        isLoading: state.isLoading,
        child: const Text('Continuar'),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(3, (i) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: i == 0 ? 0 : 6,
                right: i == 2 ? 0 : 6,
              ),
              child: _PhotoSlot(
                base64: _slots[i],
                isLoading: _uploading[i],
                isRequired: i == 0,
                onTap: () => _pickPhoto(i),
                onRemove: () => _removePhoto(i),
              ),
            ),
          )),
        ),
      ),
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  final String? base64;
  final bool isLoading;
  final bool isRequired;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PhotoSlot({
    required this.base64,
    required this.isLoading,
    required this.isRequired,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.75,
      child: GestureDetector(
        onTap: base64 == null && !isLoading ? onTap : null,
        child: Container(
          decoration: BoxDecoration(
            color: TwColors.card,
            borderRadius: BorderRadius.circular(TwRadius.lg),
            border: Border.all(
              color: isRequired && base64 == null
                  ? TwColors.primary.withValues(alpha: 0.4)
                  : TwColors.border,
              width: isRequired && base64 == null ? 1.5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(TwRadius.lg - 1),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (base64 != null)
                  Image.memory(base64Decode(base64!), fit: BoxFit.cover)
                else if (isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: TwColors.primary,
                    ),
                  )
                else
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 28,
                        color: isRequired ? TwColors.primary : TwColors.muted,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        isRequired ? 'Obrigatório' : 'Opcional',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isRequired ? TwColors.primary : TwColors.muted,
                        ),
                      ),
                    ],
                  ),
                if (base64 != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: onRemove,
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close, size: 14, color: Colors.white),
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
