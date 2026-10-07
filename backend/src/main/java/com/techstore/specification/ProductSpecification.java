package com.techstore.specification;

import com.techstore.dto.ProductFilterParams;
import com.techstore.entity.Product;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;

import java.util.ArrayList;
import java.util.List;

public final class ProductSpecification {

    private ProductSpecification() {
    }

    public static Specification<Product> filterBy(ProductFilterParams params) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (params.getKeyword() != null && !params.getKeyword().trim().isEmpty()) {
                String kw = "%" + params.getKeyword().trim().toLowerCase() + "%";
                Predicate nameLike = cb.like(cb.lower(root.get("name")), kw);
                Predicate skuLike = cb.like(cb.lower(root.get("sku")), kw);
                Predicate catLike = cb.like(cb.lower(root.get("category").get("name")), kw);
                Predicate brandLike = cb.like(cb.lower(root.get("brand").get("name")), kw);
                predicates.add(cb.or(nameLike, skuLike, catLike, brandLike));
            }

            if (params.getCategoryId() != null) {
                predicates.add(cb.equal(root.get("category").get("id"), params.getCategoryId()));
            }

            if (params.getBrandId() != null) {
                predicates.add(cb.equal(root.get("brand").get("id"), params.getBrandId()));
            }

            if (params.getMinPrice() != null) {
                predicates.add(cb.greaterThanOrEqualTo(root.get("price"), params.getMinPrice()));
            }

            if (params.getMaxPrice() != null) {
                predicates.add(cb.lessThanOrEqualTo(root.get("price"), params.getMaxPrice()));
            }

            if (params.getStatus() != null) {
                predicates.add(cb.equal(root.get("status"), params.getStatus()));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    public static Specification<Product> recommendationSpec(java.util.Set<Long> categoryIds, java.util.Set<Long> brandIds, List<Long> excludeIds) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("status"), com.techstore.enums.ProductStatus.ACTIVE));

            if (excludeIds != null && !excludeIds.isEmpty()) {
                predicates.add(cb.not(root.get("id").in(excludeIds)));
            }

            List<Predicate> orPredicates = new ArrayList<>();
            if (categoryIds != null && !categoryIds.isEmpty()) {
                orPredicates.add(root.get("category").get("id").in(categoryIds));
            }
            if (brandIds != null && !brandIds.isEmpty()) {
                orPredicates.add(root.get("brand").get("id").in(brandIds));
            }

            if (!orPredicates.isEmpty()) {
                predicates.add(cb.or(orPredicates.toArray(new Predicate[0])));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }

    public static Specification<Product> activeExcludingSpec(List<Long> excludeIds) {
        return (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.equal(root.get("status"), com.techstore.enums.ProductStatus.ACTIVE));
            if (excludeIds != null && !excludeIds.isEmpty()) {
                predicates.add(cb.not(root.get("id").in(excludeIds)));
            }
            return cb.and(predicates.toArray(new Predicate[0]));
        };
    }
}


