package com.techstore.repository;

import com.techstore.entity.ProductImage;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ProductImageRepository extends JpaRepository<ProductImage, Long> {
    List<ProductImage> findByProductIdOrderByDisplayOrderAsc(Long productId);
    void deleteByProductId(Long productId);

    @org.springframework.data.jpa.repository.Query("SELECT img FROM ProductImage img JOIN FETCH img.product WHERE img.product.id IN :productIds ORDER BY img.displayOrder ASC")
    List<ProductImage> findByProductIdInOrderByDisplayOrderAsc(@org.springframework.data.repository.query.Param("productIds") List<Long> productIds);
}


