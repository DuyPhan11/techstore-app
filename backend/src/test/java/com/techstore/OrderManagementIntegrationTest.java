package com.techstore;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.techstore.dto.LoginRequest;
import com.techstore.dto.AddToCartRequest;
import com.techstore.entity.Inventory;
import com.techstore.repository.InventoryRepository;
import com.techstore.dto.CancelOrderRequest;
import com.techstore.dto.CheckoutRequest;
import com.techstore.dto.OrderStatusUpdateRequest;
import com.techstore.entity.Order;
import com.techstore.enums.OrderStatus;
import com.techstore.repository.OrderRepository;
import com.techstore.enums.PaymentMethod;
import com.techstore.enums.PaymentStatus;
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
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class OrderManagementIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private InventoryRepository inventoryRepository;

    private String customer1Token;
    private String customer2Token;
    private String staffToken;
    private String adminToken;

    @BeforeEach
    void setUp() throws Exception {
        customer1Token = loginAndGetToken("customer1@gmail.com", "password123");
        customer2Token = loginAndGetToken("customer2@gmail.com", "password123");
        staffToken = loginAndGetToken("staff@techstore.com", "password123");
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

    private Long createOrder(String token, PaymentMethod method, boolean mockSuccess) throws Exception {
        mockMvc.perform(post("/api/v1/cart/items")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(AddToCartRequest.builder().productId(1L).quantity(2).build())))
                .andExpect(status().isOk());

        CheckoutRequest checkoutReq = CheckoutRequest.builder()
                .recipientName("Test Customer")
                .recipientPhone("0987654321")
                .shippingAddress("123 Test Street")
                .branchId(1L)
                .paymentMethod(method)
                .mockPaymentSuccess(mockSuccess)
                .build();

        MvcResult result = mockMvc.perform(post("/api/v1/checkout")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(checkoutReq)))
                .andExpect(status().isCreated())
                .andReturn();

        return objectMapper.readTree(result.getResponse().getContentAsString())
                .get("data").get("id").asLong();
    }

    @Test
    @DisplayName("Test 1: Customer can list their own orders and view detail")
    void customer_getMyOrdersAndDetail_success() throws Exception {
        Long orderId = createOrder(customer1Token, PaymentMethod.COD, false);

        // List my orders
        mockMvc.perform(get("/api/v1/orders/my")
                        .header("Authorization", "Bearer " + customer1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.content", not(empty())));

        // Get single order detail
        mockMvc.perform(get("/api/v1/orders/" + orderId)
                        .header("Authorization", "Bearer " + customer1Token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.id", is(orderId.intValue())))
                .andExpect(jsonPath("$.data.recipientName", is("Test Customer")))
                .andExpect(jsonPath("$.data.items", hasSize(1)));
    }

    @Test
    @DisplayName("Test 2: Customer cancels CONFIRMED order - Should restore inventory and set CANCELLED")
    void customer_cancelOrder_restoresInventory() throws Exception {
        Inventory invBefore = inventoryRepository.findByProductIdAndBranchId(1L, 1L).orElseThrow();
        int stockBefore = invBefore.getQuantity();

        Long orderId = createOrder(customer1Token, PaymentMethod.COD, false);

        Inventory invAfterCheckout = inventoryRepository.findByProductIdAndBranchId(1L, 1L).orElseThrow();
        assertEquals(stockBefore - 2, invAfterCheckout.getQuantity());

        // Cancel order
        CancelOrderRequest cancelReq = CancelOrderRequest.builder().reason("Đổi ý không mua nữa").build();
        mockMvc.perform(post("/api/v1/orders/" + orderId + "/cancel")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(cancelReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.status", is("CANCELLED")));

        // Verify inventory is restored back to stockBefore
        Inventory invAfterCancel = inventoryRepository.findByProductIdAndBranchId(1L, 1L).orElseThrow();
        assertEquals(stockBefore, invAfterCancel.getQuantity(), "Stock must be fully restored upon cancellation");
    }

    @Test
    @DisplayName("Test 3: Customer cancels PAID order - Should refund payment and restore inventory")
    void customer_cancelOrder_refundsPayment() throws Exception {
        Long orderId = createOrder(customer1Token, PaymentMethod.ONLINE_MOCK, true);

        // Cancel order
        CancelOrderRequest cancelReq = CancelOrderRequest.builder().reason("Muốn hoàn tiền").build();
        mockMvc.perform(post("/api/v1/orders/" + orderId + "/cancel")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(cancelReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.status", is("CANCELLED")))
                .andExpect(jsonPath("$.data.paymentStatus", is("REFUNDED")));
    }

    @Test
    @DisplayName("Test 4: Customer cannot cancel order in SHIPPING or COMPLETED status - Should return 400")
    void customer_cancelOrder_invalidState_shouldReturn400() throws Exception {
        Long orderId = createOrder(customer1Token, PaymentMethod.COD, false);

        // Manually move order to SHIPPING
        Order order = orderRepository.findById(orderId).orElseThrow();
        order.setStatus(OrderStatus.SHIPPING);
        orderRepository.saveAndFlush(order);

        // Try to cancel SHIPPING order
        CancelOrderRequest cancelReq = CancelOrderRequest.builder().reason("Hủy khi đang giao").build();
        mockMvc.perform(post("/api/v1/orders/" + orderId + "/cancel")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(cancelReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.message", containsString("Cannot cancel order in status SHIPPING")));

        // Move order to COMPLETED
        order.setStatus(OrderStatus.COMPLETED);
        orderRepository.saveAndFlush(order);

        // Try to cancel COMPLETED order
        mockMvc.perform(post("/api/v1/orders/" + orderId + "/cancel")
                        .header("Authorization", "Bearer " + customer1Token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(cancelReq)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.message", containsString("Cannot cancel order in status COMPLETED")));
    }

    @Test
    @DisplayName("Test 5: Customer cannot access or cancel another user's order - Should return 404")
    void customer_accessOtherUserOrder_shouldReturn404() throws Exception {
        Long orderId = createOrder(customer1Token, PaymentMethod.COD, false);

        // Customer 2 attempts to get Customer 1's order
        mockMvc.perform(get("/api/v1/orders/" + orderId)
                        .header("Authorization", "Bearer " + customer2Token))
                .andExpect(status().isNotFound());

        // Customer 2 attempts to cancel Customer 1's order
        mockMvc.perform(post("/api/v1/orders/" + orderId + "/cancel")
                        .header("Authorization", "Bearer " + customer2Token))
                .andExpect(status().isNotFound());
    }

    @Test
    @DisplayName("Test 6: Staff and Admin can query and filter orders")
    void staffAndAdmin_queryOrders_success() throws Exception {
        Long orderId = createOrder(customer1Token, PaymentMethod.COD, false);

        // Staff lists orders
        mockMvc.perform(get("/api/v1/admin/orders")
                        .header("Authorization", "Bearer " + staffToken)
                        .param("status", "CONFIRMED"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.content", not(empty())));

        // Admin views order detail
        mockMvc.perform(get("/api/v1/admin/orders/" + orderId)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.id", is(orderId.intValue())));
    }

    @Test
    @DisplayName("Test 7: Staff advances order lifecycle CONFIRMED -> SHIPPING -> COMPLETED (COD paid)")
    void staff_advanceOrderLifecycle_success() throws Exception {
        Long orderId = createOrder(customer1Token, PaymentMethod.COD, false);

        // 1. Advance to SHIPPING
        OrderStatusUpdateRequest shippingReq = OrderStatusUpdateRequest.builder()
                .status(OrderStatus.SHIPPING)
                .notes("Đã bàn giao đơn vị vận chuyển")
                .build();

        mockMvc.perform(put("/api/v1/admin/orders/" + orderId + "/status")
                        .header("Authorization", "Bearer " + staffToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(shippingReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status", is("SHIPPING")));

        // 2. Advance to COMPLETED (COD should now be PAID)
        OrderStatusUpdateRequest completedReq = OrderStatusUpdateRequest.builder()
                .status(OrderStatus.COMPLETED)
                .notes("Giao hàng thành công")
                .build();

        mockMvc.perform(put("/api/v1/admin/orders/" + orderId + "/status")
                        .header("Authorization", "Bearer " + staffToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(completedReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status", is("COMPLETED")))
                .andExpect(jsonPath("$.data.paymentStatus", is("PAID")));
    }

    @Test
    @DisplayName("Test 8: Changing status of a COMPLETED order should return 400 Bad Request")
    void admin_modifyCompletedOrder_shouldReturn400() throws Exception {
        Long orderId = createOrder(customer1Token, PaymentMethod.COD, false);

        // Move to SHIPPING then COMPLETED
        Order order = orderRepository.findById(orderId).orElseThrow();
        order.setStatus(OrderStatus.COMPLETED);
        orderRepository.saveAndFlush(order);

        // Attempt to move back to SHIPPING
        OrderStatusUpdateRequest req = OrderStatusUpdateRequest.builder()
                .status(OrderStatus.SHIPPING)
                .build();

        mockMvc.perform(put("/api/v1/admin/orders/" + orderId + "/status")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("Cannot modify an order that is already COMPLETED")));
    }

    @Test
    @DisplayName("Test 9: Admin cancel order restores inventory")
    void admin_cancelOrder_restoresInventory() throws Exception {
        Inventory invBefore = inventoryRepository.findByProductIdAndBranchId(1L, 1L).orElseThrow();
        int stockBefore = invBefore.getQuantity();

        Long orderId = createOrder(customer1Token, PaymentMethod.COD, false);

        // Admin cancels order
        OrderStatusUpdateRequest req = OrderStatusUpdateRequest.builder()
                .status(OrderStatus.CANCELLED)
                .notes("Hết hàng đột xuất")
                .build();

        mockMvc.perform(put("/api/v1/admin/orders/" + orderId + "/status")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status", is("CANCELLED")));

        Inventory invAfter = inventoryRepository.findByProductIdAndBranchId(1L, 1L).orElseThrow();
        assertEquals(stockBefore, invAfter.getQuantity(), "Stock must be restored when admin cancels order");
    }

    @Test
    @DisplayName("Test 10: Customer cannot access admin order management endpoints - Should return 403 Forbidden")
    void customer_accessAdminOrderEndpoints_shouldReturn403() throws Exception {
        mockMvc.perform(get("/api/v1/admin/orders")
                        .header("Authorization", "Bearer " + customer1Token))
                .andExpect(status().isForbidden());
    }
}


