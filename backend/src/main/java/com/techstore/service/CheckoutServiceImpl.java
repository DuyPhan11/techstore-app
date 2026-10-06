package com.techstore.service;

import com.techstore.entity.Branch;
import com.techstore.repository.BranchRepository;
import com.techstore.entity.Cart;
import com.techstore.entity.CartItem;
import com.techstore.repository.CartItemRepository;
import com.techstore.repository.CartRepository;
import com.techstore.exception.BadRequestException;
import com.techstore.exception.ResourceNotFoundException;
import com.techstore.entity.Inventory;
import com.techstore.repository.InventoryRepository;
import com.techstore.dto.CheckoutRequest;
import com.techstore.dto.OrderResponseDto;
import com.techstore.entity.Order;
import com.techstore.entity.OrderItem;
import com.techstore.enums.OrderStatus;
import com.techstore.repository.OrderItemRepository;
import com.techstore.repository.OrderRepository;
import com.techstore.entity.Payment;
import com.techstore.enums.PaymentMethod;
import com.techstore.enums.PaymentStatus;
import com.techstore.repository.PaymentRepository;
import com.techstore.entity.Product;
import com.techstore.entity.ProductImage;
import com.techstore.enums.ProductStatus;
import com.techstore.repository.ProductRepository;
import com.techstore.dto.CouponValidationRequest;
import com.techstore.dto.CouponValidationResponse;
import com.techstore.entity.Coupon;
import com.techstore.entity.CouponUsage;
import com.techstore.enums.DiscountType;
import com.techstore.repository.CouponRepository;
import com.techstore.repository.CouponUsageRepository;
import com.techstore.entity.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Slf4j
@Service
@RequiredArgsConstructor
public class CheckoutServiceImpl implements CheckoutService {

    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;
    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final InventoryRepository inventoryRepository;
    private final BranchRepository branchRepository;
    private final CouponRepository couponRepository;
    private final CouponUsageRepository couponUsageRepository;
    private final PaymentRepository paymentRepository;
    private final NotificationService notificationService;
    private final ProductRepository productRepository;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public OrderResponseDto checkout(User user, CheckoutRequest request) {
        log.info("Processing checkout for user: {}, paymentMethod: {}", user.getEmail(), request.getPaymentMethod());

        // 1. Identify Products to checkout (Direct Buy or Cart)
        if (request.getPaymentMethod() == PaymentMethod.ONLINE_MOCK
                && !Boolean.TRUE.equals(request.getMockPaymentSuccess())) {
            throw new BadRequestException("Thanh toán thất bại. Giỏ hàng được giữ nguyên, vui lòng thử lại.");
        }

        boolean isDirectBuy = request.getDirectProductId() != null;
        Cart cart = null;
        List<Product> productsToOrder = new ArrayList<>();
        List<Integer> quantitiesToOrder = new ArrayList<>();
        List<CartItem> cartItemsToProcess = new ArrayList<>();

        if (isDirectBuy) {
            Product product = productRepository.findById(request.getDirectProductId())
                    .orElseThrow(() -> new BadRequestException("Sản phẩm mua ngay không tồn tại với ID: " + request.getDirectProductId()));
            int qty = (request.getDirectQuantity() != null && request.getDirectQuantity() > 0) ? request.getDirectQuantity() : 1;
            productsToOrder.add(product);
            quantitiesToOrder.add(qty);
        } else {
            cart = cartRepository.findByUserIdWithLock(user.getId())
                    .orElseThrow(() -> new BadRequestException("Không tìm thấy giỏ hàng của bạn."));

            List<CartItem> cartItems = cartItemRepository.findByCartId(cart.getId());
            if (cartItems.isEmpty()) {
                throw new BadRequestException("Giỏ hàng của bạn đang trống, không thể tiến hành đặt hàng.");
            }

            if (request.getSelectedCartItemIds() != null && !request.getSelectedCartItemIds().isEmpty()) {
                Set<Long> selectedSet = new HashSet<>(request.getSelectedCartItemIds());
                for (CartItem ci : cartItems) {
                    if (selectedSet.contains(ci.getId())) {
                        cartItemsToProcess.add(ci);
                    }
                }
                if (cartItemsToProcess.isEmpty()) {
                    throw new BadRequestException("Không tìm thấy các sản phẩm đã chọn trong giỏ hàng.");
                }
            } else {
                cartItemsToProcess.addAll(cartItems);
            }

            cartItemsToProcess.sort(java.util.Comparator.comparing(item -> item.getProduct().getId()));
            for (CartItem ci : cartItemsToProcess) {
                productsToOrder.add(ci.getProduct());
                quantitiesToOrder.add(ci.getQuantity());
            }
        }

        // 2. Identify Branch
        Long branchId = request.getBranchId() != null ? request.getBranchId() : 1L;
        Branch branch = branchRepository.findById(branchId)
                .orElseThrow(() -> new BadRequestException("Chi nhánh xuất kho không tồn tại với ID: " + branchId));

        if (!"ACTIVE".equalsIgnoreCase(branch.getStatus())) {
            throw new BadRequestException("Chi nhánh '" + branch.getName() + "' hiện đang tạm ngừng phục vụ.");
        }

        // 3. Validate Stock with Pessimistic Lock & Calculate Total Items Amount
        BigDecimal totalItemsAmount = BigDecimal.ZERO;
        List<Inventory> lockedInventories = new ArrayList<>();

        for (int i = 0; i < productsToOrder.size(); i++) {
            Product product = productsToOrder.get(i);
            int quantity = quantitiesToOrder.get(i);
            if (product.getStatus() != ProductStatus.ACTIVE) {
                throw new BadRequestException("Sản phẩm '" + product.getName() + "' hiện đã ngừng kinh doanh.");
            }

            Inventory inventory = inventoryRepository.findByProductIdAndBranchIdWithLock(product.getId(), branch.getId())
                    .orElseThrow(() -> new BadRequestException("Sản phẩm '" + product.getName() + "' không có tồn kho tại chi nhánh '" + branch.getName() + "'."));

            if (inventory.getQuantity() < quantity) {
                throw new BadRequestException("Sản phẩm '" + product.getName() + "' tại chi nhánh '" + branch.getName()
                        + "' không đủ tồn kho (yêu cầu: " + quantity + ", khả dụng: " + inventory.getQuantity() + ").");
            }

            lockedInventories.add(inventory);
            BigDecimal itemSubtotal = product.getPrice().multiply(BigDecimal.valueOf(quantity));
            totalItemsAmount = totalItemsAmount.add(itemSubtotal);
        }

        // 4. Validate and Apply Coupon
        Coupon coupon = null;
        BigDecimal discountAmount = BigDecimal.ZERO;
        if (request.getCouponCode() != null && !request.getCouponCode().trim().isEmpty()) {
            coupon = validateAndGetCoupon(user, request.getCouponCode().trim(), totalItemsAmount, true);
            discountAmount = calculateDiscount(coupon, totalItemsAmount);
        }

        // 4.1. Calculate Shipping Fee
        // Free shipping for in-store pickup OR orders >= 5,000,000 VND. Otherwise standard fee 30,000 VND.
        BigDecimal shippingFee = request.getShippingFee();
        if (shippingFee == null) {
            boolean isStorePickup = request.getShippingAddress() != null
                    && request.getShippingAddress().toLowerCase().contains("nhận tại cửa hàng");
            if (isStorePickup || totalItemsAmount.compareTo(new BigDecimal("5000000")) >= 0) {
                shippingFee = BigDecimal.ZERO;
            } else {
                shippingFee = new BigDecimal("30000");
            }
        } else if (shippingFee.compareTo(BigDecimal.ZERO) < 0) {
            shippingFee = BigDecimal.ZERO;
        }

        // 4.2. Calculate VAT (Value Added Tax)
        BigDecimal vatRate = request.getVatRate() != null ? request.getVatRate() : new BigDecimal("0.08");
        BigDecimal taxableAmount = totalItemsAmount.subtract(discountAmount);
        if (taxableAmount.compareTo(BigDecimal.ZERO) < 0) {
            taxableAmount = BigDecimal.ZERO;
        }
        BigDecimal taxAmount = taxableAmount.multiply(vatRate).setScale(0, RoundingMode.HALF_UP);

        // 4.3. Calculate Final Amount: Total = Subtotal - Discount + Shipping + VAT
        BigDecimal finalAmount = taxableAmount.add(shippingFee).add(taxAmount);
        if (finalAmount.compareTo(BigDecimal.ZERO) < 0) {
            finalAmount = BigDecimal.ZERO;
        }

        // 5. Generate unique order code
        String orderCode = "ORD-" + System.currentTimeMillis() + "-" + (int) (Math.random() * 9000 + 1000);

        // 6. Create Order entity
        OrderStatus orderStatus = OrderStatus.PENDING;
        PaymentStatus paymentStatus = PaymentStatus.UNPAID;

        if (request.getPaymentMethod() == PaymentMethod.ONLINE_MOCK) {
            paymentStatus = PaymentStatus.PAID;
        }

        Order order = Order.builder()
                .orderCode(orderCode)
                .user(user)
                .branch(branch)
                .recipientName(request.getRecipientName().trim())
                .recipientPhone(request.getRecipientPhone().trim())
                .shippingAddress(request.getShippingAddress().trim())
                .totalItemsAmount(totalItemsAmount)
                .discountAmount(discountAmount)
                .shippingFee(shippingFee)
                .taxAmount(taxAmount)
                .vatRate(vatRate)
                .finalAmount(finalAmount)
                .status(orderStatus)
                .paymentMethod(request.getPaymentMethod())
                .paymentStatus(paymentStatus)
                .coupon(coupon)
                .notes(request.getNotes())
                .items(new ArrayList<>())
                .build();

        Order savedOrder = orderRepository.save(order);

        // 7. Create OrderItems and Decrease Inventory
        for (int i = 0; i < productsToOrder.size(); i++) {
            Product product = productsToOrder.get(i);
            int quantity = quantitiesToOrder.get(i);
            Inventory inventory = lockedInventories.get(i);

            String primaryImage = null;
            if (product.getImages() != null && !product.getImages().isEmpty()) {
                primaryImage = product.getImages().stream()
                        .filter(img -> Boolean.TRUE.equals(img.getIsPrimary()))
                        .findFirst()
                        .map(ProductImage::getImageUrl)
                        .orElseGet(() -> product.getImages().get(0).getImageUrl());
            }

            BigDecimal itemSubtotal = product.getPrice().multiply(BigDecimal.valueOf(quantity));

            OrderItem orderItem = OrderItem.builder()
                    .order(savedOrder)
                    .product(product)
                    .productName(product.getName())
                    .productSku(product.getSku())
                    .productImage(primaryImage)
                    .unitPrice(product.getPrice())
                    .quantity(quantity)
                    .subtotalAmount(itemSubtotal)
                    .build();

            orderItemRepository.save(orderItem);
            savedOrder.getItems().add(orderItem);

            // Deduct stock
            inventory.setQuantity(inventory.getQuantity() - quantity);
            inventoryRepository.save(inventory);
        }

        // 8. Create Payment record
        String transactionCode = (request.getPaymentMethod() == PaymentMethod.COD)
                ? "COD-" + savedOrder.getOrderCode()
                : "MOCK-" + UUID.randomUUID().toString().replace("-", "").substring(0, 12).toUpperCase();

        Payment payment = Payment.builder()
                .order(savedOrder)
                .paymentMethod(request.getPaymentMethod())
                .transactionCode(transactionCode)
                .amount(finalAmount)
                .status(paymentStatus)
                .paidAt((paymentStatus == PaymentStatus.PAID) ? LocalDateTime.now() : null)
                .build();

        paymentRepository.save(payment);
        savedOrder.setPayment(payment);

        // 9. Record Coupon Usage
        if (coupon != null) {
            coupon.setUsedCount(coupon.getUsedCount() + 1);
            couponRepository.save(coupon);

            CouponUsage couponUsage = CouponUsage.builder()
                    .coupon(coupon)
                    .user(user)
                    .order(savedOrder)
                    .build();
            couponUsageRepository.save(couponUsage);
        }

        // 10. Clear Cart (only if checking out from cart)
        if (!isDirectBuy && cart != null) {
            if (request.getSelectedCartItemIds() != null && !request.getSelectedCartItemIds().isEmpty()) {
                cartItemRepository.deleteAll(cartItemsToProcess);
            } else {
                cartItemRepository.deleteByCartId(cart.getId());
            }
        }
        log.info("Checkout successful! Order ID: {}, Order Code: {}", savedOrder.getId(), savedOrder.getOrderCode());

        // 11. Send in-app notification
        try {
            notificationService.createNotification(
                    user,
                    "Đặt hàng thành công #" + savedOrder.getOrderCode(),
                    "Đơn hàng của bạn đã được tiếp nhận và đang chờ xác nhận. Tổng thanh toán " + String.format("%,.0f", savedOrder.getFinalAmount().doubleValue()) + " đ. Cảm ơn bạn đã mua hàng tại TechStore!",
                    com.techstore.enums.NotificationType.ORDER,
                    savedOrder.getId().toString()
            );
        } catch (Exception e) {
            log.warn("Failed to create order notification: {}", e.getMessage());
        }

        return OrderResponseDto.fromEntity(savedOrder);
    }

    @Override
    @Transactional(readOnly = true)
    public CouponValidationResponse validateCoupon(User user, CouponValidationRequest request) {
        try {
            Coupon coupon = validateAndGetCoupon(user, request.getCouponCode().trim(), request.getOrderAmount());
            BigDecimal discount = calculateDiscount(coupon, request.getOrderAmount());
            BigDecimal finalAmount = request.getOrderAmount().subtract(discount);
            if (finalAmount.compareTo(BigDecimal.ZERO) < 0) {
                finalAmount = BigDecimal.ZERO;
            }

            return CouponValidationResponse.builder()
                    .valid(true)
                    .message("Áp dụng mã giảm giá thành công!")
                    .couponCode(coupon.getCode())
                    .discountType(coupon.getDiscountType())
                    .discountValue(coupon.getDiscountValue())
                    .discountAmount(discount)
                    .finalAmount(finalAmount)
                    .build();
        } catch (BadRequestException ex) {
            return CouponValidationResponse.builder()
                    .valid(false)
                    .message(ex.getMessage())
                    .couponCode(request.getCouponCode())
                    .discountAmount(BigDecimal.ZERO)
                    .finalAmount(request.getOrderAmount())
                    .build();
        }
    }

    private Coupon validateAndGetCoupon(User user, String code, BigDecimal orderAmount) {
        return validateAndGetCoupon(user, code, orderAmount, false);
    }

    private Coupon validateAndGetCoupon(User user, String code, BigDecimal orderAmount, boolean lock) {
        Coupon coupon = (lock ? couponRepository.findByCodeWithLock(code.toUpperCase(java.util.Locale.ROOT))
                : couponRepository.findByCode(code.toUpperCase(java.util.Locale.ROOT)))
                .orElseThrow(() -> new BadRequestException("Mã giảm giá '" + code + "' không tồn tại."));

        if (!Boolean.TRUE.equals(coupon.getIsActive())) {
            throw new BadRequestException("Mã giảm giá '" + code + "' đã bị vô hiệu hóa.");
        }

        LocalDateTime now = LocalDateTime.now();
        if (now.isBefore(coupon.getStartDate()) || now.isAfter(coupon.getEndDate())) {
            throw new BadRequestException("Mã giảm giá '" + code + "' đã hết hạn hoặc chưa có hiệu lực.");
        }

        if (coupon.getUsedCount() >= coupon.getUsageLimit()) {
            throw new BadRequestException("Mã giảm giá '" + code + "' đã hết lượt sử dụng.");
        }

        if (orderAmount.compareTo(coupon.getMinOrderAmount()) < 0) {
            throw new BadRequestException("Đơn hàng chưa đạt giá trị tối thiểu "
                    + coupon.getMinOrderAmount() + " ₫ để áp dụng mã '" + code + "'.");
        }

        if (couponUsageRepository.existsByCouponIdAndUserId(coupon.getId(), user.getId())) {
            throw new BadRequestException("Bạn đã sử dụng mã giảm giá '" + code + "' này rồi.");
        }

        return coupon;
    }

    private BigDecimal calculateDiscount(Coupon coupon, BigDecimal totalAmount) {
        if (coupon.getDiscountType() == DiscountType.PERCENTAGE) {
            BigDecimal discount = totalAmount.multiply(coupon.getDiscountValue())
                    .divide(BigDecimal.valueOf(100), 2, RoundingMode.HALF_UP);

            if (coupon.getMaxDiscountAmount() != null && discount.compareTo(coupon.getMaxDiscountAmount()) > 0) {
                return coupon.getMaxDiscountAmount();
            }
            return discount;
        } else if (coupon.getDiscountType() == DiscountType.FIXED_AMOUNT) {
            if (coupon.getDiscountValue().compareTo(totalAmount) > 0) {
                return totalAmount;
            }
            return coupon.getDiscountValue();
        }
        return BigDecimal.ZERO;
    }
}


