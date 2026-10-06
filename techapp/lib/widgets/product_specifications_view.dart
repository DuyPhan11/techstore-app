import 'dart:convert';
import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class ProductSpecificationsView extends StatefulWidget {
  final String specifications;

  const ProductSpecificationsView({
    super.key,
    required this.specifications,
  });

  @override
  State<ProductSpecificationsView> createState() => _ProductSpecificationsViewState();
}

class _ProductSpecificationsViewState extends State<ProductSpecificationsView> {

  Map<String, String> _parseSpecs(String raw) {
    final Map<String, String> result = {};

    try {
      // Try JSON parsing
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        decoded.forEach((k, v) {
          result[k.toString().trim()] = v.toString().trim();
        });
        return result;
      }
    } catch (_) {
      // Not JSON, fall back to line-by-line parsing
    }

    // Try parsing lines with colon
    final lines = raw.split(RegExp(r'[\r\n]+'));
    for (final line in lines) {
      if (line.contains(':')) {
        final parts = line.split(':');
        final key = parts[0].replaceAll(RegExp(r'["{}\[\]]'), '').trim();
        final val = parts.sublist(1).join(':').replaceAll(RegExp(r'["{}\[\]]'), '').trim();
        if (key.isNotEmpty && val.isNotEmpty) {
          result[key] = val;
        }
      }
    }

    return result;
  }

  String _localizeSpecKey(String key) {
    final lower = key.trim().toLowerCase();
    switch (lower) {
      case 'screen':
      case 'display':
        return 'Màn hình';
      case 'cpu':
      case 'processor':
        return 'Vi xử lý (CPU)';
      case 'ram':
        return 'RAM';
      case 'storage':
      case 'rom':
      case 'internal storage':
        return 'Bộ nhớ trong';
      case 'battery':
      case 'battery capacity':
        return 'Dung lượng pin';
      case 'camera':
        return 'Camera';
      case 'rear camera':
      case 'main camera':
        return 'Camera sau';
      case 'front camera':
      case 'selfie camera':
        return 'Camera trước';
      case 'os':
      case 'operating system':
        return 'Hệ điều hành';
      case 'gpu':
        return 'Đồ họa (GPU)';
      case 'weight':
        return 'Trọng lượng';
      case 'dimensions':
        return 'Kích thước';
      case 'connectivity':
        return 'Kết nối';
      case 'warranty':
        return 'Bảo hành';
      case 'color':
      case 'colors':
        return 'Màu sắc';
      case 'resolution':
        return 'Độ phân giải';
      case 'refresh rate':
        return 'Tần số quét';
      case 'sim':
        return 'Thẻ SIM';
      case 'charging':
        return 'Công nghệ sạc';
      default:
        return key;
    }
  }

  IconData _getIconForSpec(String key) {
    final lower = key.toLowerCase();
    if (lower.contains('chip') || lower.contains('cpu') || lower.contains('vi xử lý') || lower.contains('processor')) {
      return Icons.memory_rounded;
    } else if (lower.contains('ram')) {
      return Icons.speed_rounded;
    } else if (lower.contains('bộ nhớ') || lower.contains('ổ cứng') || lower.contains('storage') || lower.contains('rom') || lower.contains('ssd')) {
      return Icons.storage_rounded;
    } else if (lower.contains('màn hình') || lower.contains('display') || lower.contains('screen')) {
      return Icons.screenshot_rounded;
    } else if (lower.contains('pin') || lower.contains('battery')) {
      return Icons.battery_charging_full_rounded;
    } else if (lower.contains('camera')) {
      return Icons.camera_alt_outlined;
    } else if (lower.contains('gpu') || lower.contains('đồ họa')) {
      return Icons.sports_esports_outlined;
    } else if (lower.contains('hệ điều hành') || lower.contains('os')) {
      return Icons.settings_system_daydream_rounded;
    }
    return Icons.tune_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final specsMap = _parseSpecs(widget.specifications);

    if (specsMap.isEmpty) {
      // Plain text fallback
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEAECEF)),
        ),
        child: Text(
          widget.specifications,
          style: const TextStyle(fontSize: 13, color: AppColors.textDark, height: 1.5),
        ),
      );
    }

    // Extract top 4 highlights for quick visual chips
    final highlightEntries = specsMap.entries.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top 4 Quick Spec Highlight Cards
        if (highlightEntries.length >= 2) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: highlightEntries.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final entry = highlightEntries[index];
              final icon = _getIconForSpec(entry.key);

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _localizeSpecKey(entry.key),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 12),
        ],

        // Detailed Specifications Table
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEAECEF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ...specsMap.entries.toList().asMap().entries.map((item) {
                final idx = item.key;
                final entry = item.value;
                final isEven = idx % 2 == 0;

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  color: isEven ? Colors.white : const Color(0xFFF9FAFC),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Spec Name / Key
                      SizedBox(
                        width: 110,
                        child: Row(
                          children: [
                            Icon(
                              _getIconForSpec(entry.key),
                              size: 15,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _localizeSpecKey(entry.key),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Spec Value
                      Expanded(
                        child: Text(
                          entry.value,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}
