import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tinyworld_app/core/api/rest_client.dart';

class AvatarPreview extends StatelessWidget {
  final String avatarUrl;
  final double size;

  const AvatarPreview({super.key, required this.avatarUrl, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final fullUrl = '${apiClient.baseUrl}$avatarUrl';
    if (avatarUrl.endsWith('.svg')) {
      return SvgPicture.network(fullUrl, width: size, height: size);
    }
    return Image.network(fullUrl, width: size, height: size);
  }
}
