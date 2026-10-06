import 'package:flutter/material.dart';

class BannerModel {
  final int id;
  final String title;
  final String? subtitle;
  final String? badgeText1;
  final String? badgeText2;
  final String titleColor;
  final String backgroundColor;
  final String? backgroundGradientEnd;
  final String iconName;
  final String? imageUrl;
  final String linkType; // 'NONE', 'COUPON', 'PRODUCT', 'CATEGORY'
  final String? linkValue;
  final int displayOrder;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BannerModel({
    required this.id,
    required this.title,
    this.subtitle,
    this.badgeText1,
    this.badgeText2,
    required this.titleColor,
    required this.backgroundColor,
    this.backgroundGradientEnd,
    required this.iconName,
    this.imageUrl,
    required this.linkType,
    this.linkValue,
    required this.displayOrder,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return BannerModel(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      badgeText1: json['badgeText1'] as String?,
      badgeText2: json['badgeText2'] as String?,
      titleColor: json['titleColor'] as String? ?? '#FFEB3B',
      backgroundColor: json['backgroundColor'] as String? ?? '#581C87',
      backgroundGradientEnd: json['backgroundGradientEnd'] as String?,
      iconName: json['iconName'] as String? ?? 'devices_other',
      imageUrl: json['imageUrl'] as String?,
      linkType: json['linkType'] as String? ?? 'NONE',
      linkValue: json['linkValue'] as String?,
      displayOrder: json['displayOrder'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'subtitle': subtitle,
      'badgeText1': badgeText1,
      'badgeText2': badgeText2,
      'titleColor': titleColor,
      'backgroundColor': backgroundColor,
      'backgroundGradientEnd': backgroundGradientEnd,
      'iconName': iconName,
      'imageUrl': imageUrl,
      'linkType': linkType,
      'linkValue': linkValue,
      'displayOrder': displayOrder,
      'isActive': isActive,
    };
  }

  /// Helper parse hex color
  static Color parseHexColor(String? hexString, Color fallback) {
    if (hexString == null || hexString.isEmpty) return fallback;
    try {
      String cleanHex = hexString.replaceAll('#', '').trim();
      if (cleanHex.length == 6) {
        cleanHex = 'FF$cleanHex';
      }
      return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  Color get parsedTitleColor => parseHexColor(titleColor, const Color(0xFFFFEB3B));

  Color get parsedBgColor => parseHexColor(backgroundColor, const Color(0xFF581C87));

  Color? get parsedGradientEnd {
    if (backgroundGradientEnd == null || backgroundGradientEnd!.isEmpty) return null;
    return parseHexColor(backgroundGradientEnd, parsedBgColor);
  }

  IconData get parsedIcon {
    switch (iconName.toLowerCase()) {
      case 'bolt':
        return Icons.bolt_rounded;
      case 'local_offer':
        return Icons.local_offer_rounded;
      case 'local_shipping':
        return Icons.local_shipping_rounded;
      case 'phone_iphone':
        return Icons.phone_iphone_rounded;
      case 'laptop':
        return Icons.laptop_mac_rounded;
      case 'card_giftcard':
        return Icons.card_giftcard_rounded;
      case 'star':
        return Icons.star_rounded;
      case 'percent':
        return Icons.percent_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'headphones':
        return Icons.headphones_rounded;
      case 'watch':
        return Icons.watch_rounded;
      case 'devices_other':
      default:
        return Icons.devices_other_rounded;
    }
  }
}
