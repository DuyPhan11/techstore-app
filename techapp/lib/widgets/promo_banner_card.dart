import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/banner_model.dart';
import 'safe_network_image.dart';

class PromoBannerCard extends StatelessWidget {
  final BannerModel banner;
  final VoidCallback? onTap;

  const PromoBannerCard({
    super.key,
    required this.banner,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = banner.imageUrl != null && banner.imageUrl!.trim().isNotEmpty;
    final primaryBg = banner.parsedBgColor;
    final gradientEnd = banner.parsedGradientEnd ?? _computeGradientEnd(primaryBg);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [primaryBg, gradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryBg.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Decorative background glowing accents
            Positioned(
              right: -25,
              top: -25,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
            ),
            Positioned(
              right: 40,
              bottom: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 2,
                  ),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),

            // Main Content Row: Left Column (Text & Badges & CTA) + Right (Product Image / Icon)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Badges Row
                        if ((banner.badgeText1 != null && banner.badgeText1!.isNotEmpty) ||
                            (banner.badgeText2 != null && banner.badgeText2!.isNotEmpty)) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (banner.badgeText1 != null && banner.badgeText1!.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    banner.badgeText1!,
                                    style: TextStyle(
                                      color: primaryBg,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              if (banner.badgeText2 != null && banner.badgeText2!.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.freeShipping,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.bolt_rounded, size: 10, color: Colors.white),
                                      const SizedBox(width: 1),
                                      Text(
                                        banner.badgeText2!,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 9.5,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 7),
                        ],

                        // Title
                        Text(
                          banner.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            letterSpacing: 0.2,
                            color: banner.parsedTitleColor,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),

                        // Subtitle
                        if (banner.subtitle != null && banner.subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            banner.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.88),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                          ),
                        ],

                        const SizedBox(height: 10),

                        // Interactive CTA Button Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getCtaText(banner.linkType),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10.5,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 11,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Right Side: Product Image Showcase OR Ambient Icon Badge
                  if (hasImage)
                    _buildProductImageShowcase(banner)
                  else
                    _buildIconShowcase(banner),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Color _computeGradientEnd(Color start) {
    final hsl = HSLColor.fromColor(start);
    final darker = hsl.withLightness((hsl.lightness - 0.12).clamp(0.0, 1.0));
    return darker.toColor();
  }

  static String _getCtaText(String linkType) {
    switch (linkType) {
      case 'COUPON':
        return 'Lấy mã ngay';
      case 'PRODUCT':
        return 'Xem sản phẩm';
      case 'CATEGORY':
        return 'Xem danh mục';
      default:
        return 'Khám phá ngay';
    }
  }

  Widget _buildProductImageShowcase(BannerModel banner) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(7),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SafeNetworkImage(
          imageUrl: banner.imageUrl,
          fit: BoxFit.contain,
          fallbackIcon: banner.parsedIcon,
          fallbackIconSize: 42,
        ),
      ),
    );
  }

  Widget _buildIconShowcase(BannerModel banner) {
    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          banner.parsedIcon,
          size: 44,
          color: Colors.white.withValues(alpha: 0.95),
        ),
      ),
    );
  }
}
