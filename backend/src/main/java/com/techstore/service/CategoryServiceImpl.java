package com.techstore.service;

import com.techstore.dto.CategoryDto;
import com.techstore.dto.CategoryRequest;
import com.techstore.entity.Category;
import com.techstore.repository.CategoryRepository;
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
public class CategoryServiceImpl implements CategoryService {

    private final CategoryRepository categoryRepository;

    @Override
    @Transactional(readOnly = true)
    public List<CategoryDto> getAllCategories(String status) {
        List<Category> categories;
        if (status != null && !status.trim().isEmpty()) {
            categories = categoryRepository.findByStatus(status.trim().toUpperCase());
        } else {
            categories = categoryRepository.findAll();
        }
        return categories.stream()
                .map(CategoryDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public CategoryDto getCategoryById(Long id) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy danh mục với ID: " + id));
        return CategoryDto.fromEntity(category);
    }

    @Override
    @Transactional(readOnly = true)
    public CategoryDto getCategoryBySlug(String slug) {
        Category category = categoryRepository.findBySlug(slug)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy danh mục với slug: " + slug));
        return CategoryDto.fromEntity(category);
    }

    @Override
    @Transactional
    public CategoryDto createCategory(CategoryRequest request) {
        String slug = (request.getSlug() != null && !request.getSlug().trim().isEmpty())
                ? SlugUtil.toSlug(request.getSlug())
                : SlugUtil.toSlug(request.getName());

        if (categoryRepository.existsBySlug(slug)) {
            throw new ConflictException("Slug danh mục '" + slug + "' đã tồn tại");
        }

        Category category = Category.builder()
                .name(request.getName().trim())
                .slug(slug)
                .description(request.getDescription())
                .imageUrl(request.getImageUrl())
                .status(request.getStatus() != null ? request.getStatus().toUpperCase() : "ACTIVE")
                .build();

        Category saved = categoryRepository.save(category);
        return CategoryDto.fromEntity(saved);
    }

    @Override
    @Transactional
    public CategoryDto updateCategory(Long id, CategoryRequest request) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy danh mục với ID: " + id));

        String targetSlug = (request.getSlug() != null && !request.getSlug().trim().isEmpty())
                ? SlugUtil.toSlug(request.getSlug())
                : SlugUtil.toSlug(request.getName());

        if (!targetSlug.equals(category.getSlug()) && categoryRepository.existsBySlug(targetSlug)) {
            throw new ConflictException("Slug danh mục '" + targetSlug + "' đã tồn tại");
        }

        category.setName(request.getName().trim());
        category.setSlug(targetSlug);
        category.setDescription(request.getDescription());
        category.setImageUrl(request.getImageUrl());
        if (request.getStatus() != null) {
            category.setStatus(request.getStatus().toUpperCase());
        }

        Category updated = categoryRepository.save(category);
        return CategoryDto.fromEntity(updated);
    }

    @Override
    @Transactional
    public void deleteCategory(Long id) {
        Category category = categoryRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy danh mục với ID: " + id));
        category.setStatus("INACTIVE");
        categoryRepository.save(category);
    }
}


