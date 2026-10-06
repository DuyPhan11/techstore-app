package com.techstore.service.impl;

import com.techstore.dto.BannerResponseDto;
import com.techstore.dto.CreateBannerRequest;
import com.techstore.dto.UpdateBannerRequest;
import com.techstore.entity.Banner;
import com.techstore.exception.ResourceNotFoundException;
import com.techstore.repository.BannerRepository;
import com.techstore.service.BannerService;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class BannerServiceImpl implements BannerService {

    private final BannerRepository bannerRepository;

    @PostConstruct
    public void init() {
        try {
            seedDefaultBannersIfEmpty();
        } catch (Exception e) {
            log.warn("Failed to auto-seed banners on startup: {}", e.getMessage());
        }
    }

    @Override
    @Transactional(readOnly = true)
    public List<BannerResponseDto> getActiveBanners() {
        return bannerRepository.findByIsActiveTrueOrderByDisplayOrderAscCreatedAtDesc()
                .stream()
                .map(BannerResponseDto::fromEntity)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public List<BannerResponseDto> getAllBanners() {
        return bannerRepository.findAllByOrderByDisplayOrderAscCreatedAtDesc()
                .stream()
                .map(BannerResponseDto::fromEntity)
                .toList();
    }

    @Override
    @Transactional(readOnly = true)
    public BannerResponseDto getBannerById(Long id) {
        Banner banner = bannerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy banner với ID: " + id));
        return BannerResponseDto.fromEntity(banner);
    }

    @Override
    @Transactional
    public BannerResponseDto createBanner(CreateBannerRequest request) {
        Banner banner = Banner.builder()
                .title(request.getTitle().trim())
                .subtitle(request.getSubtitle() != null ? request.getSubtitle().trim() : null)
                .badgeText1(request.getBadgeText1() != null ? request.getBadgeText1().trim() : null)
                .badgeText2(request.getBadgeText2() != null ? request.getBadgeText2().trim() : null)
                .titleColor(request.getTitleColor() != null && !request.getTitleColor().isBlank() ? request.getTitleColor() : "#FFEB3B")
                .backgroundColor(request.getBackgroundColor() != null && !request.getBackgroundColor().isBlank() ? request.getBackgroundColor() : "#581C87")
                .backgroundGradientEnd(request.getBackgroundGradientEnd())
                .iconName(request.getIconName() != null && !request.getIconName().isBlank() ? request.getIconName() : "devices_other")
                .imageUrl(request.getImageUrl() != null && !request.getImageUrl().isBlank() ? request.getImageUrl() : null)
                .linkType(request.getLinkType() != null && !request.getLinkType().isBlank() ? request.getLinkType() : "NONE")
                .linkValue(request.getLinkValue() != null ? request.getLinkValue().trim() : null)
                .displayOrder(request.getDisplayOrder() != null ? request.getDisplayOrder() : 0)
                .isActive(request.getIsActive() != null ? request.getIsActive() : true)
                .build();

        Banner saved = bannerRepository.save(banner);
        log.info("Banner created: id={}, title={}", saved.getId(), saved.getTitle());
        return BannerResponseDto.fromEntity(saved);
    }

    @Override
    @Transactional
    public BannerResponseDto updateBanner(Long id, UpdateBannerRequest request) {
        Banner banner = bannerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy banner với ID: " + id));

        banner.setTitle(request.getTitle().trim());
        banner.setSubtitle(request.getSubtitle() != null ? request.getSubtitle().trim() : null);
        banner.setBadgeText1(request.getBadgeText1() != null ? request.getBadgeText1().trim() : null);
        banner.setBadgeText2(request.getBadgeText2() != null ? request.getBadgeText2().trim() : null);
        if (request.getTitleColor() != null && !request.getTitleColor().isBlank()) {
            banner.setTitleColor(request.getTitleColor());
        }
        if (request.getBackgroundColor() != null && !request.getBackgroundColor().isBlank()) {
            banner.setBackgroundColor(request.getBackgroundColor());
        }
        banner.setBackgroundGradientEnd(request.getBackgroundGradientEnd());
        if (request.getIconName() != null && !request.getIconName().isBlank()) {
            banner.setIconName(request.getIconName());
        }
        banner.setImageUrl(request.getImageUrl() != null && !request.getImageUrl().isBlank() ? request.getImageUrl() : null);
        if (request.getLinkType() != null && !request.getLinkType().isBlank()) {
            banner.setLinkType(request.getLinkType());
        }
        banner.setLinkValue(request.getLinkValue() != null ? request.getLinkValue().trim() : null);
        if (request.getDisplayOrder() != null) {
            banner.setDisplayOrder(request.getDisplayOrder());
        }
        if (request.getIsActive() != null) {
            banner.setIsActive(request.getIsActive());
        }

        Banner updated = bannerRepository.save(banner);
        log.info("Banner updated: id={}, title={}", updated.getId(), updated.getTitle());
        return BannerResponseDto.fromEntity(updated);
    }

    @Override
    @Transactional
    public BannerResponseDto toggleStatus(Long id, boolean active) {
        Banner banner = bannerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy banner với ID: " + id));

        banner.setIsActive(active);
        Banner updated = bannerRepository.save(banner);
        log.info("Banner status toggled: id={}, active={}", updated.getId(), active);
        return BannerResponseDto.fromEntity(updated);
    }

    @Override
    @Transactional
    public void deleteBanner(Long id) {
        Banner banner = bannerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy banner với ID: " + id));

        bannerRepository.delete(banner);
        log.info("Banner deleted: id={}", id);
    }

    @Override
    @Transactional
    public void seedDefaultBannersIfEmpty() {
        if (bannerRepository.count() > 0) return;

        List<Banner> defaults = List.of(
                Banner.builder()
                        .title("CYBER\nTECHSTORE")
                        .subtitle("cho thiết bị công nghệ & phụ kiện thông minh")
                        .badgeText1("GIẢM 40%")
                        .badgeText2("FREESHIP")
                        .titleColor("#FFEB3B")
                        .backgroundColor("#581C87")
                        .backgroundGradientEnd("#3B0764")
                        .iconName("devices_other")
                        .linkType("CATEGORY")
                        .displayOrder(1)
                        .isActive(true)
                        .build(),
                Banner.builder()
                        .title("SIÊU SALE\nƯU ĐÃI KHỦNG")
                        .subtitle("Nhập mã TECH10 giảm ngay 10% cho đơn hàng bất kỳ")
                        .badgeText1("VOUCHER 10%")
                        .badgeText2("HOT DEAL")
                        .titleColor("#FFFFFF")
                        .backgroundColor("#DC2626")
                        .backgroundGradientEnd("#991B1B")
                        .iconName("local_offer")
                        .linkType("COUPON")
                        .linkValue("TECH10")
                        .displayOrder(2)
                        .isActive(true)
                        .build(),
                Banner.builder()
                        .title("FREESHIP 0Đ\nTOÀN QUỐC")
                        .subtitle("Giao hỏa tốc 2H - Miễn phí vận chuyển cho đơn từ 5 triệu")
                        .badgeText1("GIAO 2H")
                        .badgeText2("0Đ PHÍ SHIP")
                        .titleColor("#FFFFFF")
                        .backgroundColor("#059669")
                        .backgroundGradientEnd("#065F46")
                        .iconName("local_shipping")
                        .linkType("NONE")
                        .displayOrder(3)
                        .isActive(true)
                        .build(),
                Banner.builder()
                        .title("FLAGSHIP\nIPHONE 15 PRO")
                        .subtitle("Titan Tự Nhiên - Trả góp 0% lãi suất ngay hôm nay")
                        .badgeText1("MỚI 2026")
                        .badgeText2("TRẢ GÓP 0%")
                        .titleColor("#38BDF8")
                        .backgroundColor("#0F172A")
                        .backgroundGradientEnd("#1E293B")
                        .iconName("phone_iphone")
                        .linkType("PRODUCT")
                        .linkValue("1")
                        .displayOrder(4)
                        .isActive(true)
                        .build()
        );

        bannerRepository.saveAll(defaults);
        log.info("Seeded {} default marketing banners.", defaults.size());
    }
}
