package com.techstore.service;

import com.techstore.dto.BrandDto;
import com.techstore.dto.BrandRequest;

import java.util.List;

public interface BrandService {

    List<BrandDto> getAllBrands(String status);

    BrandDto getBrandById(Long id);

    BrandDto getBrandBySlug(String slug);

    BrandDto createBrand(BrandRequest request);

    BrandDto updateBrand(Long id, BrandRequest request);

    void deleteBrand(Long id);
}


