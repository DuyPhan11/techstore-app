package com.techstore.service;

import com.techstore.dto.AddToCartRequest;
import com.techstore.dto.CartDto;
import com.techstore.dto.CartItemDto;
import com.techstore.entity.Cart;
import com.techstore.entity.CartItem;
import com.techstore.repository.CartItemRepository;
import com.techstore.repository.CartRepository;
import com.techstore.exception.BadRequestException;
import com.techstore.exception.ResourceNotFoundException;
import com.techstore.repository.InventoryRepository;
import com.techstore.entity.Product;
import com.techstore.enums.ProductStatus;
import com.techstore.repository.ProductRepository;
import com.techstore.entity.User;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CartServiceImpl implements CartService {

    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;
    private final ProductRepository productRepository;
    private final InventoryRepository inventoryRepository;

    @Transactional
    public Cart getOrCreateCart(User user) {
        return cartRepository.findByUserIdWithLock(user.getId())
                .orElseGet(() -> {
                    Cart newCart = Cart.builder()
                            .user(user)
                            .build();
                    return cartRepository.save(newCart);
                });
    }

    @Override
    @Transactional
    public CartDto getCartForUser(User user) {
        Cart cart = getOrCreateCart(user);
        List<CartItem> items = cartItemRepository.findByCartId(cart.getId());

        List<CartItemDto> itemDtos = items.stream()
                .map(item -> {
                    Integer stock = inventoryRepository.getTotalStockByProductId(item.getProduct().getId());
                    return CartItemDto.fromEntity(item, stock);
                })
                .collect(Collectors.toList());

        return CartDto.of(cart.getId(), itemDtos);
    }

    @Override
    @Transactional
    public CartDto addToCart(User user, AddToCartRequest request) {
        Product product = productRepository.findById(request.getProductId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy sản phẩm với ID: " + request.getProductId()));

        if (product.getStatus() != ProductStatus.ACTIVE) {
            throw new BadRequestException("Sản phẩm hiện không hoạt động hoặc đã ngừng kinh doanh");
        }

        Integer totalStock = inventoryRepository.getTotalStockByProductId(product.getId());
        int availableStock = (totalStock != null) ? totalStock : 0;
        if (availableStock <= 0) {
            throw new BadRequestException("Sản phẩm đã hết hàng trong toàn bộ chi nhánh");
        }

        Cart cart = getOrCreateCart(user);
        Optional<CartItem> existingItemOpt = cartItemRepository.findByCartIdAndProductId(cart.getId(), product.getId());

        if (existingItemOpt.isPresent()) {
            CartItem existingItem = existingItemOpt.get();
            int newQuantity = existingItem.getQuantity() + request.getQuantity();
            if (newQuantity > availableStock) {
                throw new BadRequestException("Số lượng yêu cầu (" + newQuantity + ") vượt quá số lượng tồn kho khả dụng (" + availableStock + ")");
            }
            existingItem.setQuantity(newQuantity);
            cartItemRepository.save(existingItem);
        } else {
            if (request.getQuantity() > availableStock) {
                throw new BadRequestException("Số lượng yêu cầu (" + request.getQuantity() + ") vượt quá số lượng tồn kho khả dụng (" + availableStock + ")");
            }
            CartItem newItem = CartItem.builder()
                    .cart(cart)
                    .product(product)
                    .quantity(request.getQuantity())
                    .build();
            cartItemRepository.save(newItem);
        }

        return getCartForUser(user);
    }

    @Override
    @Transactional
    public CartDto updateItemQuantity(User user, Long productId, Integer quantity) {
        Cart cart = getOrCreateCart(user);
        CartItem item = cartItemRepository.findByCartIdAndProductId(cart.getId(), productId)
                .orElseThrow(() -> new ResourceNotFoundException("Sản phẩm không có trong giỏ hàng"));

        if (quantity <= 0) {
            cartItemRepository.delete(item);
        } else {
            Product product = item.getProduct();
            if (product.getStatus() != ProductStatus.ACTIVE) {
                throw new BadRequestException("Sản phẩm hiện không còn kinh doanh");
            }
            Integer totalStock = inventoryRepository.getTotalStockByProductId(product.getId());
            int availableStock = (totalStock != null) ? totalStock : 0;
            if (quantity > availableStock) {
                throw new BadRequestException("Số lượng yêu cầu (" + quantity + ") vượt quá số lượng tồn kho khả dụng (" + availableStock + ")");
            }
            item.setQuantity(quantity);
            cartItemRepository.save(item);
        }

        return getCartForUser(user);
    }

    @Override
    @Transactional
    public CartDto removeItem(User user, Long productId) {
        Cart cart = getOrCreateCart(user);
        cartItemRepository.deleteByCartIdAndProductId(cart.getId(), productId);
        return getCartForUser(user);
    }

    @Override
    @Transactional
    public void clearCart(User user) {
        Cart cart = getOrCreateCart(user);
        cartItemRepository.deleteByCartId(cart.getId());
    }
}


