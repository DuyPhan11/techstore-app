package com.techstore.repository;

import com.techstore.entity.Product;
import com.techstore.enums.ProductStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ProductRepository extends JpaRepository<Product, Long>, JpaSpecificationExecutor<Product> {

    @Override
    @EntityGraph(attributePaths = {"category", "brand"})
    Page<Product> findAll(Specification<Product> spec, Pageable pageable);

    @Override
    @EntityGraph(attributePaths = {"category", "brand"})
    List<Product> findAll(Specification<Product> spec);

    @Override
    @EntityGraph(attributePaths = {"category", "brand"})
    List<Product> findAllById(Iterable<Long> ids);

    @Override
    @EntityGraph(attributePaths = {"category", "brand"})
    Optional<Product> findById(Long id);

    @EntityGraph(attributePaths = {"category", "brand"})
    Optional<Product> findBySlug(String slug);

    @EntityGraph(attributePaths = {"category", "brand"})
    Optional<Product> findBySku(String sku);

    boolean existsBySku(String sku);
    boolean existsBySlug(String slug);
    Page<Product> findByStatus(ProductStatus status, Pageable pageable);
    Page<Product> findByCategoryIdAndStatus(Long categoryId, ProductStatus status, Pageable pageable);
    Page<Product> findByBrandIdAndStatus(Long brandId, ProductStatus status, Pageable pageable);
}


