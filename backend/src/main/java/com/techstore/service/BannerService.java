package com.techstore.service;

import com.techstore.dto.BannerResponseDto;
import com.techstore.dto.CreateBannerRequest;
import com.techstore.dto.UpdateBannerRequest;

import java.util.List;

public interface BannerService {

    List<BannerResponseDto> getActiveBanners();

    List<BannerResponseDto> getAllBanners();

    BannerResponseDto getBannerById(Long id);

    BannerResponseDto createBanner(CreateBannerRequest request);

    BannerResponseDto updateBanner(Long id, UpdateBannerRequest request);

    BannerResponseDto toggleStatus(Long id, boolean active);

    void deleteBanner(Long id);

    void seedDefaultBannersIfEmpty();
}
