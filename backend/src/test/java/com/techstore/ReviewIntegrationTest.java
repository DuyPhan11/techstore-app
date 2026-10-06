package com.techstore;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.techstore.dto.LoginRequest;
import com.techstore.dto.AddToCartRequest;
import com.techstore.dto.CheckoutRequest;
import com.techstore.entity.Order;
import com.techstore.enums.OrderStatus;
import com.techstore.repository.OrderRepository;
import com.techstore.enums.PaymentMethod;
import com.techstore.dto.CreateReviewRequest;
import com.techstore.dto.UpdateReviewRequest;
import com.techstore.repository.ReviewRepository;
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

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class ReviewIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private ReviewRepository reviewRepository;

    private String customer1Token;
    private String customer2Token;
    private String adminToken;

    @BeforeEach
    void setUp() throws Exception {
        customer1Token = loginAndGetToken("customer1@gmail.com", "password123");
        customer2Token = loginAndGetToken("customer2@gmail.com", "password123");
        adminToken = loginAndGetToken("admin@techstore.com", "password123");

        // Clear cart for customer 1
        mockMvc.perform(delete("/api/v1/cart").header("Authorization", "Bearer " + customer1Token));
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

    private Long createAndCompleteOrder(String token, Long productId) throws Exception {
        mockMvc.perform(post("/api/v1/cart/items")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(AddToCartRequest.builder().productId(productId).quantity(1).build())))
                .andExpect(status().isOk());

        CheckoutRequest checkoutReq = CheckoutRequest.builder()
                .recipientName("Test Customer")
                .recipientPhone("0987654321")
                .shippingAddress("123 Test Street")
                .branchId(1L)
                .paymentMethod(PaymentMethod.COD)
                .build();

        MvcResult result = mockMvc.perform(post("/api/v1/checkout")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkoutReq)))
                .andExpect(status().isCreated())
                .andReturn();

        Long orderId = objectMapper.readTree(result.getResponse().getContentAsString())
                .get("data").get("id").asLong();

        // Mark order as COMPLETED
        Order order = orderRepository.findById(orderId).orElseThrow();
        order.setStatus(OrderStatus.COMPLETED);
        orderRepository.saveAndFlush(order);

        return orderId;
    }

    @Test
    @DisplayName("Test 1: Unauthenticated request to create review should return 401 Unauthorized")
    void unauthenticated_createReview_shouldReturn401() throws Exception {
        CreateReviewRequest req = CreateReviewRequest.builder()
                .rating(5)
                .comment("Sản phẩm rất xuất sắc!")
                .build();

        mockMvc.perform(post("/api/v1/products/1/reviews")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Test 2: Customer who has NOT bought product cannot create review (400 Bad Request)")
    void customer_notBoughtProduct_shouldReturn400() throws Exception {
        CreateReviewRequest req = CreateReviewRequest.builder()
                .rating(5)
                .comment("Tôi chưa mua nhưng muốn đánh giá")
                .build();

        // Customer 1 attempts to review Product 4 (has not bought it)
        mockMvc.perform(post("/api/v1/products/4/reviews")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.message", containsString("sau khi đã mua và đơn hàng ở trạng thái HOÀN THÀNH")));
    }

    @Test
    @DisplayName("Test 3: Customer with uncompleted order (e.g. SHIPPING) cannot review (400 Bad Request)")
    void customer_orderNotCompleted_shouldReturn400() throws Exception {
        // Create an order for product 3 but keep it SHIPPING
        mockMvc.perform(post("/api/v1/cart/items")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(AddToCartRequest.builder().productId(3L).quantity(1).build())))
                .andExpect(status().isOk());

        CheckoutRequest checkoutReq = CheckoutRequest.builder()
                .recipientName("Test Customer")
                .recipientPhone("0987654321")
                .shippingAddress("123 Test Street")
                .branchId(1L)
                .paymentMethod(PaymentMethod.COD)
                .build();

        MvcResult result = mockMvc.perform(post("/api/v1/checkout")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkoutReq)))
                .andExpect(status().isCreated())
                .andReturn();

        Long orderId = objectMapper.readTree(result.getResponse().getContentAsString())
                .get("data").get("id").asLong();

        Order order = orderRepository.findById(orderId).orElseThrow();
        order.setStatus(OrderStatus.SHIPPING);
        orderRepository.saveAndFlush(order);

        CreateReviewRequest req = CreateReviewRequest.builder()
                .rating(4)
                .comment("Hàng đang giao nhưng đánh giá trước")
                .build();

        mockMvc.perform(post("/api/v1/products/3/reviews")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("sau khi đã mua và đơn hàng ở trạng thái HOÀN THÀNH")));
    }

    @Test
    @DisplayName("Test 4: Customer with COMPLETED order creates review successfully (201 Created)")
    void customer_completedOrder_createReview_success() throws Exception {
        Long orderId = createAndCompleteOrder(customer1Token, 1L);

        CreateReviewRequest req = CreateReviewRequest.builder()
                .rating(5)
                .comment("Sản phẩm iPhone 15 Pro Max chính hãng, dùng rất mượt!")
                .orderId(orderId)
                .build();

        mockMvc.perform(post("/api/v1/products/1/reviews")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.rating", is(5)))
                .andExpect(jsonPath("$.data.comment", is("Sản phẩm iPhone 15 Pro Max chính hãng, dùng rất mượt!")))
                .andExpect(jsonPath("$.data.isOwner", is(true)))
                .andExpect(jsonPath("$.data.productId", is(1)))
                .andExpect(jsonPath("$.data.orderId", is(orderId.intValue())));
    }

    @Test
    @DisplayName("Test 5: Duplicate review on same completed order should return 400 Bad Request")
    void customer_duplicateReview_shouldReturn400() throws Exception {
        Long orderId = createAndCompleteOrder(customer1Token, 1L);

        CreateReviewRequest req1 = CreateReviewRequest.builder()
                .rating(5)
                .comment("Đánh giá lần thứ nhất rất tốt")
                .orderId(orderId)
                .build();

        mockMvc.perform(post("/api/v1/products/1/reviews")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req1)))
                .andExpect(status().isCreated());

        CreateReviewRequest req2 = CreateReviewRequest.builder()
                .rating(4)
                .comment("Đánh giá lần thứ hai lại trùng")
                .orderId(orderId)
                .build();

        mockMvc.perform(post("/api/v1/products/1/reviews")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req2)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("đã đánh giá sản phẩm này")));
    }

    @Test
    @DisplayName("Test 6: Invalid rating (< 1 or > 5) should return 400 Bad Request")
    void invalidRating_shouldReturn400() throws Exception {
        CreateReviewRequest reqLow = CreateReviewRequest.builder()
                .rating(0)
                .comment("Đánh giá rating 0 sao")
                .build();

        mockMvc.perform(post("/api/v1/products/1/reviews")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(reqLow)))
                .andExpect(status().isBadRequest());

        CreateReviewRequest reqHigh = CreateReviewRequest.builder()
                .rating(6)
                .comment("Đánh giá rating 6 sao")
                .build();

        mockMvc.perform(post("/api/v1/products/1/reviews")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(reqHigh)))
                .andExpect(status().isBadRequest());
    }

    @Test
    @DisplayName("Test 7: Public user can view reviews and summary rating stats")
    void public_viewReviewsAndStats_success() throws Exception {
        createAndCompleteOrder(customer1Token, 2L);

        CreateReviewRequest req = CreateReviewRequest.builder()
                .rating(5)
                .comment("MacBook Pro M3 Max quá mạnh mẽ!")
                .build();

        mockMvc.perform(post("/api/v1/products/2/reviews")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated());

        // Guest calls GET /api/v1/products/2/reviews without token
        mockMvc.perform(get("/api/v1/products/2/reviews"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.averageRating", is(5.0)))
                .andExpect(jsonPath("$.data.totalReviews", greaterThanOrEqualTo(1)))
                .andExpect(jsonPath("$.data.reviews.content", hasSize(greaterThanOrEqualTo(1))));
    }

    @Test
    @DisplayName("Test 8: Customer can update their own review")
    void customer_updateOwnReview_success() throws Exception {
        createAndCompleteOrder(customer1Token, 1L);

        CreateReviewRequest createReq = CreateReviewRequest.builder()
                .rating(3)
                .comment("Bình thường, dùng tạm ổn")
                .build();

        MvcResult createRes = mockMvc.perform(post("/api/v1/products/1/reviews")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createReq)))
                .andExpect(status().isCreated())
                .andReturn();

        Long reviewId = objectMapper.readTree(createRes.getResponse().getContentAsString())
                .get("data").get("id").asLong();

        // Update review
        UpdateReviewRequest updateReq = UpdateReviewRequest.builder()
                .rating(5)
                .comment("Dùng thêm vài ngày thấy rất mượt, đổi lại 5 sao!")
                .build();

        mockMvc.perform(put("/api/v1/reviews/" + reviewId)
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.rating", is(5)))
                .andExpect(jsonPath("$.data.comment", is("Dùng thêm vài ngày thấy rất mượt, đổi lại 5 sao!")));
    }

    @Test
    @DisplayName("Test 9: Customer cannot update another customer's review (403 Forbidden)")
    void customer_cannotUpdateOtherUserReview_shouldReturn403() throws Exception {
        createAndCompleteOrder(customer1Token, 1L);

        CreateReviewRequest createReq = CreateReviewRequest.builder()
                .rating(5)
                .comment("Review của khách hàng 1")
                .build();

        MvcResult createRes = mockMvc.perform(post("/api/v1/products/1/reviews")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createReq)))
                .andExpect(status().isCreated())
                .andReturn();

        Long reviewId = objectMapper.readTree(createRes.getResponse().getContentAsString())
                .get("data").get("id").asLong();

        // Customer 2 tries to update Customer 1's review
        UpdateReviewRequest updateReq = UpdateReviewRequest.builder()
                .rating(1)
                .comment("Khách hàng 2 cố tình sửa đánh giá của người khác")
                .build();

        mockMvc.perform(put("/api/v1/reviews/" + reviewId)
                        .header("Authorization", "Bearer " + customer2Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Test 10: Customer can delete own review, and Admin can delete any review")
    void customer_andAdmin_deleteReview_success() throws Exception {
        // Customer 1 creates review A
        createAndCompleteOrder(customer1Token, 1L);
        CreateReviewRequest createReqA = CreateReviewRequest.builder()
                .rating(5)
                .comment("Review sẽ bị xóa bởi chính khách hàng")
                .build();

        MvcResult resA = mockMvc.perform(post("/api/v1/products/1/reviews")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createReqA)))
                .andExpect(status().isCreated())
                .andReturn();
        Long reviewIdA = objectMapper.readTree(resA.getResponse().getContentAsString()).get("data").get("id").asLong();

        // Customer 1 deletes their own review A
        mockMvc.perform(delete("/api/v1/reviews/" + reviewIdA)
                        .header("Authorization", "Bearer " + customer1Token))
                .andExpect(status().isOk());
        assertFalse(reviewRepository.existsById(reviewIdA));

        // Customer 1 creates review B
        createAndCompleteOrder(customer1Token, 2L);
        CreateReviewRequest createReqB = CreateReviewRequest.builder()
                .rating(1)
                .comment("Review có nội dung vi phạm bị admin xóa")
                .build();

        MvcResult resB = mockMvc.perform(post("/api/v1/products/2/reviews")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createReqB)))
                .andExpect(status().isCreated())
                .andReturn();
        Long reviewIdB = objectMapper.readTree(resB.getResponse().getContentAsString()).get("data").get("id").asLong();

        // Admin deletes review B
        mockMvc.perform(delete("/api/v1/reviews/" + reviewIdB)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk());
        assertFalse(reviewRepository.existsById(reviewIdB));
    }

    @Test
    @DisplayName("Test 11: Customer can fetch pending reviews, my reviews, and review counts")
    void customer_getPendingAndReviewedOrders_success() throws Exception {
        // Customer 1 creates and completes an order for product 1
        createAndCompleteOrder(customer1Token, 1L);

        // Before review: pending count should be at least 1
        mockMvc.perform(get("/api/v1/reviews/my/pending")
                        .header("Authorization", "Bearer " + customer1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", hasSize(greaterThanOrEqualTo(1))))
                .andExpect(jsonPath("$.data[0].productId", is(1)));

        mockMvc.perform(get("/api/v1/reviews/my/counts")
                        .header("Authorization", "Bearer " + customer1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.pendingCount", greaterThanOrEqualTo(1)));

        // Create review for product 1
        CreateReviewRequest req = CreateReviewRequest.builder()
                .rating(5)
                .comment("Sản phẩm tuyệt vời, giao nhanh")
                .build();

        mockMvc.perform(post("/api/v1/products/1/reviews")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated());

        // After review: pending for product 1 is gone, now appears in my reviews
        mockMvc.perform(get("/api/v1/reviews/my")
                        .header("Authorization", "Bearer " + customer1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content", hasSize(greaterThanOrEqualTo(1))))
                .andExpect(jsonPath("$.data.content[0].productId", is(1)))
                .andExpect(jsonPath("$.data.content[0].comment", is("Sản phẩm tuyệt vời, giao nhanh")));
    }

    @Test
    @DisplayName("Test 12: Admin can fetch all reviews, stats, and reply to a review")
    void admin_reviewsManagement_andReply_success() throws Exception {
        // Customer 1 creates a review for product 1
        createAndCompleteOrder(customer1Token, 1L);
        CreateReviewRequest req = CreateReviewRequest.builder()
                .rating(5)
                .comment("Đánh giá sản phẩm để admin phản hồi")
                .build();

        MvcResult createRes = mockMvc.perform(post("/api/v1/products/1/reviews")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andReturn();

        Long reviewId = objectMapper.readTree(createRes.getResponse().getContentAsString()).get("data").get("id").asLong();

        // Admin fetches reviews stats
        mockMvc.perform(get("/api/v1/admin/reviews/stats")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalReviews", greaterThanOrEqualTo(1)))
                .andExpect(jsonPath("$.data.averageRating", greaterThan(0.0)));

        // Admin fetches reviews list
        mockMvc.perform(get("/api/v1/admin/reviews")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.content", hasSize(greaterThanOrEqualTo(1))));

        // Admin replies to review
        com.techstore.dto.AdminReplyReviewRequest replyReq = com.techstore.dto.AdminReplyReviewRequest.builder()
                .reply("Dạ shop cảm ơn quý khách đã tin tưởng ủng hộ ạ!")
                .build();

        mockMvc.perform(post("/api/v1/admin/reviews/" + reviewId + "/reply")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(replyReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.adminReply", is("Dạ shop cảm ơn quý khách đã tin tưởng ủng hộ ạ!")));
    }
}


