import 'package:flutter/material.dart';

/// Biểu tượng nhiều ngôi sao AI màu xanh (Google Gemini / AI Sparkles style)
class AiSparklesIcon extends StatelessWidget {
  final double size;
  final Color? solidColor;
  final List<Color>? gradientColors;

  const AiSparklesIcon({
    super.key,
    this.size = 22,
    this.solidColor,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    if (solidColor != null) {
      return Icon(
        Icons.auto_awesome,
        size: size,
        color: solidColor,
      );
    }

    final colors = gradientColors ?? const [
      Color(0xFF24BFAD), // Xanh ngọc / Cyan (ngôi sao trên bên trái)
      Color(0xFF2780FB), // Xanh dương tươi / Azure Blue (ngôi sao chính)
      Color(0xFF1D4ED8), // Xanh dương đậm / Deep Blue (ngôi sao nhỏ)
    ];

    return ShaderMask(
      shaderCallback: (Rect bounds) {
        return LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(bounds);
      },
      blendMode: BlendMode.srcIn,
      child: Icon(
        Icons.auto_awesome,
        size: size,
        color: Colors.white,
      ),
    );
  }
}
