package com.techstore.service;

import com.techstore.dto.AddToCartRequest;
import com.techstore.dto.CartDto;
import com.techstore.entity.User;

public interface CartService {

    CartDto getCartForUser(User user);

    CartDto addToCart(User user, AddToCartRequest request);

    CartDto updateItemQuantity(User user, Long productId, Integer quantity);

    CartDto removeItem(User user, Long productId);

    void clearCart(User user);
}


