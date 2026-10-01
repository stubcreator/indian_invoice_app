import 'dart:convert';
import 'package:flutter/material.dart';

class CountryFlagWidget extends StatelessWidget {
  final String? flag;
  final double width;
  final double height;
  final double borderRadius;

  const CountryFlagWidget({
    super.key,
    required this.flag,
    this.width = 36,
    this.height = 24,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    final flagStr = flag?.trim() ?? '';

    if (flagStr.isEmpty) {
      return _buildFallback();
    }

    // Check if it's an emoji (short string, not base64 starting with iVBOR)
    if (flagStr.length <= 8 && !flagStr.startsWith('iVBOR')) {
      return SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Text(
            flagStr,
            style: TextStyle(fontSize: height * 0.8),
          ),
        ),
      );
    }

    // Attempt Base64 image decoding
    try {
      final bytes = base64Decode(flagStr);
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(),
        ),
      );
    } catch (_) {
      return _buildFallback();
    }
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
      ),
      child: const Icon(Icons.flag_rounded, size: 16, color: Colors.grey),
    );
  }
}
