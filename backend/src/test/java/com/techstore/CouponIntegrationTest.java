package com.techstore;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.techstore.dto.LoginRequest;
import com.techstore.dto.AddToCartRequest;
import com.techstore.dto.CheckoutRequest;
import com.techstore.enums.PaymentMethod;
import com.techstore.dto.CreateCouponRequest;
import com.techstore.dto.UpdateCouponRequest;
import com.techstore.entity.Coupon;
import com.techstore.enums.DiscountType;
import com.techstore.repository.CouponRepository;
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
import java.util.Map;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class CouponIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private CouponRepository couponRepository;

    private String staffToken;
    private String adminToken;
    private String customerToken;

    @BeforeEach
    void setUp() throws Exception {
        staffToken = loginAndGetToken("staff@techstore.com", "password123");
        adminToken = loginAndGetToken("admin@techstore.com", "password123");
        customerToken = loginAndGetToken("customer1@gmail.com", "password123");

        // Clear cart for customer
        mockMvc.perform(delete("/api/v1/cart").header("Authorization", "Bearer " + customerToken));
    }

    private String loginAndGetToken(String username, String password) throws Exception {
        LoginRequest loginRequest = LoginRequest.builder()
                .username(username)
                .password(password)
                .build();

        MvcResult res = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andReturn();

        return objectMapper.readTree(res.getResponse().getContentAsString())
                .get("data").get("token").asText();
    }

    @Test
    @DisplayName("Test 1: Staff creates percentage coupon with max discount limit successfully (201 Created)")
    void staff_createPercentageCoupon_success() throws Exception {
        CreateCouponRequest req = CreateCouponRequest.builder()
                .code("SUMMER15")
                .discountType(DiscountType.PERCENTAGE)
                .discountValue(BigDecimal.valueOf(15))
                .minOrderAmount(BigDecimal.valueOf(10000000))
                .maxDiscountAmount(BigDecimal.valueOf(2000000))
                .usageLimit(50)
                .startDate(LocalDateTime.now().minusDays(1))
                .endDate(LocalDateTime.now().plusDays(30))
                .isActive(true)
                .build();

        mockMvc.perform(post("/api/v1/admin/coupons")
                        .header("Authorization", "Bearer " + staffToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.code", is("SUMMER15")))
                .andExpect(jsonPath("$.data.discountType", is("PERCENTAGE")))
                .andExpect(jsonPath("$.data.discountValue", is(15)))
                .andExpect(jsonPath("$.data.maxDiscountAmount", is(2000000)))
                .andExpect(jsonPath("$.data.usageLimit", is(50)))
                .andExpect(jsonPath("$.data.usedCount", is(0)))
                .andExpect(jsonPath("$.data.isActive", is(true)));
    }

    @Test
    @DisplayName("Test 2: Staff creates fixed amount coupon successfully (201 Created)")
    void staff_createFixedAmountCoupon_success() throws Exception {
        CreateCouponRequest req = CreateCouponRequest.builder()
                .code("DISCOUNT500K")
                .discountType(DiscountType.FIXED_AMOUNT)
                .discountValue(BigDecimal.valueOf(500000))
                .minOrderAmount(BigDecimal.valueOf(5000000))
                .usageLimit(100)
                .startDate(LocalDateTime.now().minusDays(1))
                .endDate(LocalDateTime.now().plusDays(15))
                .isActive(true)
                .build();

        mockMvc.perform(post("/api/v1/admin/coupons")
                        .header("Authorization", "Bearer " + staffToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.code", is("DISCOUNT500K")))
                .andExpect(jsonPath("$.data.discountType", is("FIXED_AMOUNT")))
                .andExpect(jsonPath("$.data.discountValue", is(500000)));
    }

    @Test
    @DisplayName("Test 3: Creating duplicate coupon code should return 409 Conflict")
    void createDuplicateCoupon_shouldReturn409() throws Exception {
        CreateCouponRequest req = CreateCouponRequest.builder()
                .code("TECH10") // Already in seed data
                .discountType(DiscountType.PERCENTAGE)
                .discountValue(BigDecimal.valueOf(10))
                .minOrderAmount(BigDecimal.ZERO)
                .usageLimit(10)
                .startDate(LocalDateTime.now().minusDays(1))
                .endDate(LocalDateTime.now().plusDays(10))
                .isActive(true)
                .build();

        mockMvc.perform(post("/api/v1/admin/coupons")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.message", containsString("đã tồn tại trong hệ thống")));
    }

    @Test
    @DisplayName("Test 4: Invalid parameters (percentage > 100% or end date before start date) return 400")
    void createCoupon_invalidParams_shouldReturn400() throws Exception {
        // Percentage > 100%
        CreateCouponRequest reqOver100 = CreateCouponRequest.builder()
                .code("OVER100")
                .discountType(DiscountType.PERCENTAGE)
                .discountValue(BigDecimal.valueOf(150))
                .usageLimit(10)
                .startDate(LocalDateTime.now())
                .endDate(LocalDateTime.now().plusDays(5))
                .isActive(true)
                .build();

        mockMvc.perform(post("/api/v1/admin/coupons")
                        .header("Authorization", "Bearer " + staffToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(reqOver100)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("không được vượt quá 100%")));

        // End date before start date
        CreateCouponRequest reqBadDate = CreateCouponRequest.builder()
                .code("BADDATE")
                .discountType(DiscountType.FIXED_AMOUNT)
                .discountValue(BigDecimal.valueOf(100000))
                .usageLimit(10)
                .startDate(LocalDateTime.now().plusDays(5))
                .endDate(LocalDateTime.now().plusDays(1))
                .isActive(true)
                .build();

        mockMvc.perform(post("/api/v1/admin/coupons")
                        .header("Authorization", "Bearer " + staffToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(reqBadDate)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("sau thời gian bắt đầu")));
    }

    @Test
    @DisplayName("Test 5: Staff updates existing coupon successfully (200 OK)")
    void staff_updateCoupon_success() throws Exception {
        Coupon coupon = couponRepository.findByCode("TECH10").orElseThrow();

        UpdateCouponRequest updateReq = UpdateCouponRequest.builder()
                .discountType(DiscountType.PERCENTAGE)
                .discountValue(BigDecimal.valueOf(12))
                .minOrderAmount(BigDecimal.valueOf(6000000))
                .maxDiscountAmount(BigDecimal.valueOf(3000000))
                .usageLimit(200)
                .startDate(coupon.getStartDate())
                .endDate(coupon.getEndDate())
                .isActive(true)
                .build();

        mockMvc.perform(put("/api/v1/admin/coupons/" + coupon.getId())
                        .header("Authorization", "Bearer " + staffToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.discountValue", is(12)))
                .andExpect(jsonPath("$.data.minOrderAmount", is(6000000)))
                .andExpect(jsonPath("$.data.usageLimit", is(200)));
    }

    @Test
    @DisplayName("Test 6: Disabled coupon cannot be applied in checkout (400 Bad Request)")
    void disabledCoupon_cannotBeAppliedInCheckout() throws Exception {
        Coupon coupon = couponRepository.findByCode("TECH10").orElseThrow();

        // Staff disables the coupon
        mockMvc.perform(patch("/api/v1/admin/coupons/" + coupon.getId() + "/status")
                        .header("Authorization", "Bearer " + staffToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("active", false))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.isActive", is(false)));

        // Customer attempts to checkout with this disabled coupon
        mockMvc.perform(post("/api/v1/cart/items")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(AddToCartRequest.builder().productId(1L).quantity(1).build())))
                .andExpect(status().isOk());

        CheckoutRequest checkoutReq = CheckoutRequest.builder()
                .recipientName("Nguyen Van A")
                .recipientPhone("0987654321")
                .shippingAddress("123 Street")
                .branchId(1L)
                .paymentMethod(PaymentMethod.COD)
                .couponCode("TECH10")
                .build();

        mockMvc.perform(post("/api/v1/checkout")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkoutReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("đã bị vô hiệu hóa")));
    }

    @Test
    @DisplayName("Test 7: Coupon minimum order amount not met returns 400 Bad Request")
    void minOrderNotMet_shouldReturn400() throws Exception {
        // Product 5: AirPods Pro 2 = 5,690,000 VND
        mockMvc.perform(post("/api/v1/cart/items")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(AddToCartRequest.builder().productId(5L).quantity(1).build())))
                .andExpect(status().isOk());

        // Create coupon requiring min 10,000,000 VND
        CreateCouponRequest req = CreateCouponRequest.builder()
                .code("MIN10M")
                .discountType(DiscountType.FIXED_AMOUNT)
                .discountValue(BigDecimal.valueOf(500000))
                .minOrderAmount(BigDecimal.valueOf(10000000))
                .usageLimit(50)
                .startDate(LocalDateTime.now().minusDays(1))
                .endDate(LocalDateTime.now().plusDays(10))
                .isActive(true)
                .build();

        mockMvc.perform(post("/api/v1/admin/coupons")
                        .header("Authorization", "Bearer " + staffToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated());

        CheckoutRequest checkoutReq = CheckoutRequest.builder()
                .recipientName("Nguyen Van A")
                .recipientPhone("0987654321")
                .shippingAddress("123 Street")
                .branchId(1L)
                .paymentMethod(PaymentMethod.COD)
                .couponCode("MIN10M")
                .build();

        mockMvc.perform(post("/api/v1/checkout")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkoutReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("chưa đạt giá trị tối thiểu")));
    }

    @Test
    @DisplayName("Test 8: Backend recalculates discount and caps at maxDiscountAmount without trusting frontend")
    void backend_recalculatesDiscount_andCapsAtMaxDiscount() throws Exception {
        // Product 1: iPhone 15 Pro Max (29,990,000 VND)
        mockMvc.perform(post("/api/v1/cart/items")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(AddToCartRequest.builder().productId(1L).quantity(1).build())))
                .andExpect(status().isOk());

        // Coupon TECH10: 10% on min 5M, maxDiscount = 2,000,000
        // 10% of 29,990,000 = 2,999,000, but capped at 2,000,000!
        CheckoutRequest checkoutReq = CheckoutRequest.builder()
                .recipientName("Nguyen Van A")
                .recipientPhone("0987654321")
                .shippingAddress("123 Street")
                .branchId(1L)
                .paymentMethod(PaymentMethod.COD)
                .couponCode("TECH10")
                .build();

        mockMvc.perform(post("/api/v1/checkout")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkoutReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.totalItemsAmount", is(29990000.0)))
                .andExpect(jsonPath("$.data.discountAmount", is(2000000.0)))
                .andExpect(jsonPath("$.data.shippingFee").value(anyOf(is(0), is(0.0))))
                .andExpect(jsonPath("$.data.taxAmount").value(anyOf(is(2239200), is(2239200.0))))
                .andExpect(jsonPath("$.data.finalAmount", is(30229200.0)));
    }

    @Test
    @DisplayName("Test 9: Staff can search and filter coupons")
    void staff_searchAndFilterCoupons_success() throws Exception {
        mockMvc.perform(get("/api/v1/admin/coupons")
                        .header("Authorization", "Bearer " + staffToken)
                        .param("search", "TECH10")
                        .param("discountType", "PERCENTAGE"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.content", hasSize(greaterThanOrEqualTo(1))))
                .andExpect(jsonPath("$.data.content[0].code", is("TECH10")));
    }

    @Test
    @DisplayName("Test 10: Customer cannot access admin coupon management endpoints (403 Forbidden)")
    void customer_accessAdminCoupons_shouldReturn403() throws Exception {
        mockMvc.perform(get("/api/v1/admin/coupons")
                        .header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Test 11: Admin can retrieve coupon statistics")
    void admin_getCouponStats_success() throws Exception {
        mockMvc.perform(get("/api/v1/admin/coupons/stats")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.totalCoupons", greaterThanOrEqualTo(1)))
                .andExpect(jsonPath("$.data.activeCoupons", greaterThanOrEqualTo(0)))
                .andExpect(jsonPath("$.data.totalUsed", greaterThanOrEqualTo(0)));
    }

    @Test
    @DisplayName("Test 12: Anyone can retrieve active available coupons for shopping")
    void getAvailableCoupons_success() throws Exception {
        mockMvc.perform(get("/api/v1/coupons"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", notNullValue()));
    }
}


