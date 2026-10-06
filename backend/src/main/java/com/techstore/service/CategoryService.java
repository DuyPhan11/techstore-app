package com.techstore.service;

import com.techstore.dto.CategoryDto;
import com.techstore.dto.CategoryRequest;

import java.util.List;

public interface CategoryService {

    List<CategoryDto> getAllCategories(String status);

    CategoryDto getCategoryById(Long id);

    CategoryDto getCategoryBySlug(String slug);

    CategoryDto createCategory(CategoryRequest request);

    CategoryDto updateCategory(Long id, CategoryRequest request);

    void deleteCategory(Long id);
}


