import 'package:flutter/material.dart';

class ItemImageView extends StatelessWidget {
  const ItemImageView({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('data:image/')) {
      final bytes = UriData.parse(imageUrl).contentAsBytes();
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
      );
    }

    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: const Color(0xFFF3EFE7),
        alignment: Alignment.center,
        child: const Text('이미지 없음'),
      ),
    );
  }
}
