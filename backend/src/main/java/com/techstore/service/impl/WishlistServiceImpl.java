package com.techstore.service.impl;

import com.techstore.dto.ProductSummaryDto;
import com.techstore.entity.Product;
import com.techstore.entity.User;
import com.techstore.entity.Wishlist;
import com.techstore.exception.ResourceNotFoundException;
import com.techstore.repository.InventoryRepository;
import com.techstore.repository.ProductRepository;
import com.techstore.repository.WishlistRepository;
import com.techstore.service.WishlistService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class WishlistServiceImpl implements WishlistService {

    private final WishlistRepository wishlistRepository;
    private final ProductRepository productRepository;
    private final InventoryRepository inventoryRepository;

    @Override
    @Transactional(readOnly = true)
    public List<ProductSummaryDto> getWishlistProducts(User user) {
        List<Wishlist> wishlists = wishlistRepository.findByUserOrderByCreatedAtDesc(user);
        return wishlists.stream()
                .map(w -> {
                    Product p = w.getProduct();
                    Integer stock = inventoryRepository.getTotalStockByProductId(p.getId());
                    return ProductSummaryDto.fromEntity(p, stock);
                })
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<Long> getWishlistProductIds(User user) {
        return wishlistRepository.findProductIdsByUserId(user.getId());
    }

    @Override
    @Transactional
    public boolean toggleWishlist(User user, Long productId) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy sản phẩm với ID: " + productId));

        Optional<Wishlist> existing = wishlistRepository.findByUserIdAndProductId(user.getId(), product.getId());
        if (existing.isPresent()) {
            wishlistRepository.delete(existing.get());
            return false; // Removed from wishlist
        } else {
            Wishlist wishlist = Wishlist.builder()
                    .user(user)
                    .product(product)
                    .build();
            wishlistRepository.save(wishlist);
            return true; // Added to wishlist
        }
    }

    @Override
    @Transactional
    public void addToWishlist(User user, Long productId) {
        if (wishlistRepository.existsByUserIdAndProductId(user.getId(), productId)) {
            return;
        }

        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy sản phẩm với ID: " + productId));

        Wishlist wishlist = Wishlist.builder()
                .user(user)
                .product(product)
                .build();
        wishlistRepository.save(wishlist);
    }

    @Override
    @Transactional
    public void removeFromWishlist(User user, Long productId) {
        wishlistRepository.deleteByUserIdAndProductId(user.getId(), productId);
    }

    @Override
    @Transactional(readOnly = true)
    public boolean isFavorite(User user, Long productId) {
        return wishlistRepository.existsByUserIdAndProductId(user.getId(), productId);
    }
}
