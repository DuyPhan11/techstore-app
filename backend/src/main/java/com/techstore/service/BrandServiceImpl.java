package com.techstore.service;

import com.techstore.dto.BrandDto;
import com.techstore.dto.BrandRequest;
import com.techstore.entity.Brand;
import com.techstore.repository.BrandRepository;
import com.techstore.exception.ConflictException;
import com.techstore.exception.ResourceNotFoundException;
import com.techstore.util.SlugUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BrandServiceImpl implements BrandService {

    private final BrandRepository brandRepository;

    @Override
    @Transactional(readOnly = true)
    public List<BrandDto> getAllBrands(String status) {
        List<Brand> brands;
        if (status != null && !status.trim().isEmpty()) {
            brands = brandRepository.findByStatus(status.trim().toUpperCase());
        } else {
            brands = brandRepository.findAll();
        }
        return brands.stream()
                .map(BrandDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public BrandDto getBrandById(Long id) {
        Brand brand = brandRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thương hiệu với ID: " + id));
        return BrandDto.fromEntity(brand);
    }

    @Override
    @Transactional(readOnly = true)
    public BrandDto getBrandBySlug(String slug) {
        Brand brand = brandRepository.findBySlug(slug)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thương hiệu với slug: " + slug));
        return BrandDto.fromEntity(brand);
    }

    @Override
    @Transactional
    public BrandDto createBrand(BrandRequest request) {
        String slug = (request.getSlug() != null && !request.getSlug().trim().isEmpty())
                ? SlugUtil.toSlug(request.getSlug())
                : SlugUtil.toSlug(request.getName());

        if (brandRepository.existsBySlug(slug)) {
            throw new ConflictException("Slug thương hiệu '" + slug + "' đã tồn tại");
        }

        Brand brand = Brand.builder()
                .name(request.getName().trim())
                .slug(slug)
                .logoUrl(request.getLogoUrl())
                .description(request.getDescription())
                .status(request.getStatus() != null ? request.getStatus().toUpperCase() : "ACTIVE")
                .build();

        Brand saved = brandRepository.save(brand);
        return BrandDto.fromEntity(saved);
    }

    @Override
    @Transactional
    public BrandDto updateBrand(Long id, BrandRequest request) {
        Brand brand = brandRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thương hiệu với ID: " + id));

        String targetSlug = (request.getSlug() != null && !request.getSlug().trim().isEmpty())
                ? SlugUtil.toSlug(request.getSlug())
                : SlugUtil.toSlug(request.getName());

        if (!targetSlug.equals(brand.getSlug()) && brandRepository.existsBySlug(targetSlug)) {
            throw new ConflictException("Slug thương hiệu '" + targetSlug + "' đã tồn tại");
        }

        brand.setName(request.getName().trim());
        brand.setSlug(targetSlug);
        brand.setLogoUrl(request.getLogoUrl());
        brand.setDescription(request.getDescription());
        if (request.getStatus() != null) {
            brand.setStatus(request.getStatus().toUpperCase());
        }

        Brand updated = brandRepository.save(brand);
        return BrandDto.fromEntity(updated);
    }

    @Override
    @Transactional
    public void deleteBrand(Long id) {
        Brand brand = brandRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thương hiệu với ID: " + id));
        brand.setStatus("INACTIVE");
        brandRepository.save(brand);
    }
}


