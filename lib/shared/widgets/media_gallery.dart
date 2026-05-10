import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';
import 'package:tinyworld_app/core/theme/styles.dart';
import 'package:tinyworld_app/shared/widgets/photo_viewer.dart';

class MediaGallery extends StatefulWidget {
  final String simId;

  const MediaGallery({super.key, required this.simId});

  @override
  State<MediaGallery> createState() => _MediaGalleryState();
}

class _MediaGalleryState extends State<MediaGallery> {
  List<Map<String, dynamic>> _media = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    try {
      final resp = await apiClient.get('/chats/${widget.simId}/media');
      final data = resp.data as Map<String, dynamic>;
      setState(() {
        _media = (data['media'] as List?)
                ?.map((e) => e as Map<String, dynamic>)
                .toList() ??
            [];
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TwColors.bg,
      appBar: AppBar(
        backgroundColor: TwColors.surface,
        title: Text(
          'Mídia compartilhada',
          style: TextStyle(color: TwColors.onBg, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: TwColors.muted),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(TwColors.primary),
              ),
            )
          : _media.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library_outlined,
                          size: 64, color: TwColors.muted),
                      SizedBox(height: 12),
                      Text(
                        'Nenhuma mídia compartilhada',
                        style: TextStyle(color: TwColors.muted, fontSize: 15),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(4),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: _media.length,
                  itemBuilder: (ctx, i) {
                    final photo = _media[i]['photo'] as String? ?? '';
                    final bytes = base64Decode(photo);
                    return GestureDetector(
                      onTap: () =>
                          PhotoViewer.show(context, bytes),
                      child: Image.memory(
                        bytes,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: TwColors.surface,
                          child: const Icon(Icons.broken_image,
                              color: TwColors.muted),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
