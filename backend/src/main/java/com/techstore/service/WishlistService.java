package com.techstore.service;

import com.techstore.dto.ProductSummaryDto;
import com.techstore.entity.User;

import java.util.List;

public interface WishlistService {

    List<ProductSummaryDto> getWishlistProducts(User user);

    List<Long> getWishlistProductIds(User user);

    boolean toggleWishlist(User user, Long productId);

    void addToWishlist(User user, Long productId);

    void removeFromWishlist(User user, Long productId);

    boolean isFavorite(User user, Long productId);
}
