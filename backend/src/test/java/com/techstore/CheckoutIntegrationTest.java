package com.techstore;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.techstore.dto.LoginRequest;
import com.techstore.dto.AddToCartRequest;
import com.techstore.entity.Inventory;
import com.techstore.repository.InventoryRepository;
import com.techstore.dto.CheckoutRequest;
import com.techstore.repository.OrderRepository;
import com.techstore.enums.PaymentMethod;
import com.techstore.enums.PaymentStatus;
import com.techstore.entity.Coupon;
import com.techstore.enums.DiscountType;
import com.techstore.repository.CouponRepository;
import com.techstore.repository.CouponUsageRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class CheckoutIntegrationTest {
    @Test
    void failedPaymentPreservesCartStockCouponAndOrders() throws Exception {
        mockMvc.perform(post("/api/v1/cart/items").header("Authorization", "Bearer " + customerToken)
                .contentType(MediaType.APPLICATION_JSON).content("{\"productId\":1,\"quantity\":1}"))
                .andExpect(status().isOk());
        int stock = inventoryRepository.findByProductIdAndBranchId(1L, 1L).orElseThrow().getQuantity();
        int used = couponRepository.findByCode("TECH10").orElseThrow().getUsedCount();
        long orders = orderRepository.count();
        long usages = couponUsageRepository.count();
        CheckoutRequest request = CheckoutRequest.builder().recipientName("Test Buyer")
                .recipientPhone("0912345678").shippingAddress("Test address").branchId(1L)
                .couponCode("TECH10").paymentMethod(PaymentMethod.ONLINE_MOCK).mockPaymentSuccess(false).build();
        mockMvc.perform(post("/api/v1/checkout").header("Authorization", "Bearer " + customerToken)
                .contentType(MediaType.APPLICATION_JSON).content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
        assertEquals(stock, inventoryRepository.findByProductIdAndBranchId(1L, 1L).orElseThrow().getQuantity());
        assertEquals(used, couponRepository.findByCode("TECH10").orElseThrow().getUsedCount());
        assertEquals(orders, orderRepository.count());
        assertEquals(usages, couponUsageRepository.count());
        mockMvc.perform(get("/api/v1/cart").header("Authorization", "Bearer " + customerToken))
                .andExpect(jsonPath("$.data.totalItems", is(1)));
        request.setMockPaymentSuccess(true);
        mockMvc.perform(post("/api/v1/checkout").header("Authorization", "Bearer " + customerToken)
                .contentType(MediaType.APPLICATION_JSON).content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated());
        mockMvc.perform(post("/api/v1/checkout").header("Authorization", "Bearer " + customerToken)
                .contentType(MediaType.APPLICATION_JSON).content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest());
        assertEquals(orders + 1, orderRepository.count());
    }

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private InventoryRepository inventoryRepository;

    @Autowired
    private CouponRepository couponRepository;

    @Autowired
    private CouponUsageRepository couponUsageRepository;

    private String customerToken;

    @BeforeEach
    void setUp() throws Exception {
        LoginRequest customerLogin = LoginRequest.builder()
                .username("customer2@gmail.com")
                .password("password123")
                .build();

        MvcResult custRes = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(customerLogin)))
                .andExpect(status().isOk())
                .andReturn();

        customerToken = objectMapper.readTree(custRes.getResponse().getContentAsString())
                .get("data").get("token").asText();

        // Ensure cart is clear before each test
        mockMvc.perform(delete("/api/v1/cart")
                .header("Authorization", "Bearer " + customerToken));
    }

    @Test
    @DisplayName("Test 1: Unauthenticated checkout should return 401 Unauthorized")
    void checkout_unauthenticated_shouldReturn401() throws Exception {
        CheckoutRequest request = CheckoutRequest.builder()
                .recipientName("Test Recipient")
                .recipientPhone("0901234567")
                .shippingAddress("123 Street")
                .paymentMethod(PaymentMethod.COD)
                .build();

        mockMvc.perform(post("/api/v1/checkout")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Test 2: Checkout with empty cart should return 400 Bad Request")
    void checkout_emptyCart_shouldReturn400() throws Exception {
        CheckoutRequest request = CheckoutRequest.builder()
                .recipientName("Test Recipient")
                .recipientPhone("0901234567")
                .shippingAddress("123 Street")
                .paymentMethod(PaymentMethod.COD)
                .build();

        mockMvc.perform(post("/api/v1/checkout")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.message", containsString("Giỏ hàng của bạn đang trống")));
    }

    @Test
    @DisplayName("Test 3: Insufficient stock at branch - Should return 400 Bad Request and rollback transaction")
    void checkout_insufficientStock_shouldReturn400AndRollback() throws Exception {
        // Product 1 has total stock = 90 (50 at Branch 1, 40 at Branch 2).
        // Add 60 items to cart (which is valid across all branches <= 90)
        AddToCartRequest addReq = AddToCartRequest.builder()
                .productId(1L)
                .quantity(60)
                .build();

        mockMvc.perform(post("/api/v1/cart/items")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(addReq)))
                .andExpect(status().isOk());

        long ordersCountBefore = orderRepository.count();
        Inventory invBranch1Before = inventoryRepository.findByProductIdAndBranchId(1L, 1L).orElseThrow();
        int stockBefore = invBranch1Before.getQuantity(); // 50

        // Checkout specifically from Branch 1 (which only has 50 items < 60 requested)
        CheckoutRequest checkoutReq = CheckoutRequest.builder()
                .recipientName("Nguyen Van A")
                .recipientPhone("0987654321")
                .shippingAddress("Hanoi, Vietnam")
                .branchId(1L)
                .paymentMethod(PaymentMethod.COD)
                .build();

        mockMvc.perform(post("/api/v1/checkout")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkoutReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.message", containsString("không đủ tồn kho")));

        // Verify Transaction Rollback
        assertEquals(ordersCountBefore, orderRepository.count(), "Order must not be created on failure");
        Inventory invBranch1After = inventoryRepository.findByProductIdAndBranchId(1L, 1L).orElseThrow();
        assertEquals(stockBefore, invBranch1After.getQuantity(), "Stock must remain unchanged due to rollback");

        // Verify cart items were not deleted
        mockMvc.perform(get("/api/v1/cart")
                        .header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalItems", is(60)));
    }

    @Test
    @DisplayName("Test 4: Expired coupon should return 400 Bad Request")
    void checkout_expiredCoupon_shouldReturn400() throws Exception {
        // Add product to cart
        mockMvc.perform(post("/api/v1/cart/items")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(AddToCartRequest.builder().productId(1L).quantity(1).build())))
                .andExpect(status().isOk());

        // Create an expired coupon
        Coupon expiredCoupon = Coupon.builder()
                .code("EXPIRED_SALE")
                .discountType(DiscountType.PERCENTAGE)
                .discountValue(new BigDecimal("20.00"))
                .minOrderAmount(BigDecimal.ZERO)
                .startDate(LocalDateTime.now().minusDays(10))
                .endDate(LocalDateTime.now().minusDays(1)) // Expired yesterday
                .isActive(true)
                .usageLimit(50)
                .usedCount(0)
                .build();
        couponRepository.saveAndFlush(expiredCoupon);

        CheckoutRequest checkoutReq = CheckoutRequest.builder()
                .recipientName("Nguyen Van A")
                .recipientPhone("0987654321")
                .shippingAddress("Hanoi, Vietnam")
                .couponCode("EXPIRED_SALE")
                .paymentMethod(PaymentMethod.COD)
                .build();

        mockMvc.perform(post("/api/v1/checkout")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkoutReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.message", containsString("hết hạn")));
    }

    @Test
    @DisplayName("Test 5: Coupon minimum order amount not met should return 400 Bad Request")
    void checkout_couponMinOrderNotMet_shouldReturn400() throws Exception {
        // Product 5: AirPods Pro 2, price = 5,690,000
        mockMvc.perform(post("/api/v1/cart/items")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(AddToCartRequest.builder().productId(5L).quantity(1).build())))
                .andExpect(status().isOk());

        // Create coupon requiring minimum 20,000,000
        Coupon bigOrderCoupon = Coupon.builder()
                .code("BIG_ORDER_VIP")
                .discountType(DiscountType.FIXED_AMOUNT)
                .discountValue(new BigDecimal("1000000.00"))
                .minOrderAmount(new BigDecimal("20000000.00"))
                .startDate(LocalDateTime.now().minusDays(1))
                .endDate(LocalDateTime.now().plusDays(30))
                .isActive(true)
                .usageLimit(100)
                .usedCount(0)
                .build();
        couponRepository.saveAndFlush(bigOrderCoupon);

        CheckoutRequest checkoutReq = CheckoutRequest.builder()
                .recipientName("Nguyen Van A")
                .recipientPhone("0987654321")
                .shippingAddress("Hanoi, Vietnam")
                .couponCode("BIG_ORDER_VIP")
                .paymentMethod(PaymentMethod.COD)
                .build();

        mockMvc.perform(post("/api/v1/checkout")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkoutReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.message", containsString("chưa đạt giá trị tối thiểu")));
    }

    @Test
    @DisplayName("Test 6: Successful Checkout with COD - Decreases inventory, clears cart, creates UNPAID payment")
    void checkout_success_cod() throws Exception {
        // Add 2 units of Product 1 (iPhone 15 PM)
        mockMvc.perform(post("/api/v1/cart/items")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(AddToCartRequest.builder().productId(1L).quantity(2).build())))
                .andExpect(status().isOk());

        Inventory invBefore = inventoryRepository.findByProductIdAndBranchId(1L, 1L).orElseThrow();
        int stockBefore = invBefore.getQuantity();

        CheckoutRequest checkoutReq = CheckoutRequest.builder()
                .recipientName("Trần Khách Hàng")
                .recipientPhone("0912345678")
                .shippingAddress("789 Cầu Giấy, Hà Nội")
                .branchId(1L)
                .paymentMethod(PaymentMethod.COD)
                .notes("Giao giờ hành chính")
                .build();

        mockMvc.perform(post("/api/v1/checkout")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkoutReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.orderCode", startsWith("ORD-")))
                .andExpect(jsonPath("$.data.recipientName", is("Trần Khách Hàng")))
                .andExpect(jsonPath("$.data.paymentMethod", is("COD")))
                .andExpect(jsonPath("$.data.paymentStatus", is("UNPAID")))
                .andExpect(jsonPath("$.data.status", is("CONFIRMED")))
                .andExpect(jsonPath("$.data.totalItemsAmount", is(59980000.0)))
                .andExpect(jsonPath("$.data.shippingFee", is(0.0)))
                .andExpect(jsonPath("$.data.taxAmount", is(4798400.0)))
                .andExpect(jsonPath("$.data.finalAmount", is(64778400.0)))
                .andExpect(jsonPath("$.data.items", hasSize(1)));

        // Verify inventory was decreased by 2
        Inventory invAfter = inventoryRepository.findByProductIdAndBranchId(1L, 1L).orElseThrow();
        assertEquals(stockBefore - 2, invAfter.getQuantity());

        // Verify cart is now empty
        mockMvc.perform(get("/api/v1/cart")
                        .header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalItems", is(0)));
    }

    @Test
    @DisplayName("Test 7: Successful Checkout with ONLINE_MOCK - Status PAID with mock transaction code")
    void checkout_success_onlineMock() throws Exception {
        // Add 1 unit of Product 2 (MacBook Pro)
        mockMvc.perform(post("/api/v1/cart/items")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(AddToCartRequest.builder().productId(2L).quantity(1).build())))
                .andExpect(status().isOk());

        CheckoutRequest checkoutReq = CheckoutRequest.builder()
                .recipientName("Lê Mua Sắm")
                .recipientPhone("0988889999")
                .shippingAddress("123 Nguyễn Huệ, TP.HCM")
                .branchId(2L)
                .paymentMethod(PaymentMethod.ONLINE_MOCK)
                .mockPaymentSuccess(true)
                .build();

        mockMvc.perform(post("/api/v1/checkout")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkoutReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.paymentMethod", is("ONLINE_MOCK")))
                .andExpect(jsonPath("$.data.paymentStatus", is("PAID")))
                .andExpect(jsonPath("$.data.transactionCode", startsWith("MOCK-")))
                .andExpect(jsonPath("$.data.status", is("CONFIRMED")));
    }

    @Test
    @DisplayName("Test 8: Successful Checkout with Coupon - Calculates discount, increases usedCount and records CouponUsage")
    void checkout_success_withCoupon() throws Exception {
        // Add Product 1 (iPhone 15 PM, price 29,990,000)
        mockMvc.perform(post("/api/v1/cart/items")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(AddToCartRequest.builder().productId(1L).quantity(1).build())))
                .andExpect(status().isOk());

        // Coupon TECH10: 10% discount on min 5,000,000, max discount 5,000,000
        // 10% of 29,990,000 is 2,999,000
        Coupon tech10Before = couponRepository.findByCode("TECH10").orElseThrow();
        int usedCountBefore = tech10Before.getUsedCount();

        CheckoutRequest checkoutReq = CheckoutRequest.builder()
                .recipientName("Khách Hàng Voucher")
                .recipientPhone("0977112233")
                .shippingAddress("456 Hoàng Quốc Việt, Hà Nội")
                .branchId(1L)
                .couponCode("TECH10")
                .paymentMethod(PaymentMethod.COD)
                .build();

        mockMvc.perform(post("/api/v1/checkout")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkoutReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.totalItemsAmount", is(29990000.0)))
                .andExpect(jsonPath("$.data.discountAmount", is(2000000.0))) // Capped at maxDiscountAmount (2,000,000)
                .andExpect(jsonPath("$.data.shippingFee", is(0.0)))
                .andExpect(jsonPath("$.data.taxAmount", is(2239200.0)))
                .andExpect(jsonPath("$.data.finalAmount", is(30229200.0)))
                .andExpect(jsonPath("$.data.couponCode", is("TECH10")));

        // Verify coupon used count increased
        Coupon tech10After = couponRepository.findByCode("TECH10").orElseThrow();
        assertEquals(usedCountBefore + 1, tech10After.getUsedCount());
    }
}


