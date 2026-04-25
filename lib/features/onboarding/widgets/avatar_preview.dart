import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';

class AvatarPreview extends StatelessWidget {
  final String avatarUrl;
  final double size;

  const AvatarPreview({super.key, required this.avatarUrl, this.size = 120});

  bool get _isSvg => avatarUrl.contains('.svg') || avatarUrl.contains('/svg');

  @override
  Widget build(BuildContext context) {
    final fullUrl = avatarUrl.startsWith('http')
        ? avatarUrl
        : '${apiClient.baseUrl}$avatarUrl';

    final fallback = _AvatarFallback(size: size);

    if (_isSvg) {
      return _SafeSvgAvatar(url: fullUrl, size: size, fallback: fallback);
    }
    return Image.network(
      fullUrl,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final double size;
  const _AvatarFallback({required this.size});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF1B76F2).withValues(alpha: 0.25),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person, color: Colors.white, size: size * 0.5),
      );
}

class _SafeSvgAvatar extends StatefulWidget {
  final String url;
  final double size;
  final Widget fallback;

  const _SafeSvgAvatar({
    required this.url,
    required this.size,
    required this.fallback,
  });

  @override
  State<_SafeSvgAvatar> createState() => _SafeSvgAvatarState();
}

class _SafeSvgAvatarState extends State<_SafeSvgAvatar> {
  late Future<Uint8List?> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchBytes(widget.url);
  }

  @override
  void didUpdateWidget(_SafeSvgAvatar old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _future = _fetchBytes(widget.url);
    }
  }

  static Future<Uint8List?> _fetchBytes(String url) async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final resp = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (resp.statusCode == 200 && resp.data != null) {
        return Uint8List.fromList(resp.data!);
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _future,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: const CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Color(0xFF1B76F2),
            ),
          );
        }
        final bytes = snap.data;
        if (bytes == null) return widget.fallback;
        try {
          return SvgPicture.memory(
            bytes,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.contain,
          );
        } catch (_) {
          return widget.fallback;
        }
      },
    );
  }
}
