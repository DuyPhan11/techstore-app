package com.techstore;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.techstore.dto.LoginRequest;
import com.techstore.entity.Branch;
import com.techstore.repository.BranchRepository;
import com.techstore.entity.Order;
import com.techstore.entity.OrderItem;
import com.techstore.enums.OrderStatus;
import com.techstore.repository.OrderItemRepository;
import com.techstore.repository.OrderRepository;
import com.techstore.enums.PaymentMethod;
import com.techstore.enums.PaymentStatus;
import com.techstore.entity.Product;
import com.techstore.repository.ProductRepository;
import com.techstore.entity.User;
import com.techstore.repository.UserRepository;
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
import java.util.UUID;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
public class DashboardIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private OrderRepository orderRepository;

    @Autowired
    private OrderItemRepository orderItemRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private BranchRepository branchRepository;

    @Autowired
    private ProductRepository productRepository;

    private String adminToken;
    private String staffToken;
    private String customerToken;

    @BeforeEach
    void setUp() throws Exception {
        adminToken = loginAndGetToken("admin@techstore.com", "password123");
        staffToken = loginAndGetToken("staff@techstore.com", "password123");
        customerToken = loginAndGetToken("customer1@gmail.com", "password123");
    }

    private String loginAndGetToken(String username, String password) throws Exception {
        LoginRequest req = LoginRequest.builder().username(username).password(password).build();
        MvcResult res = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andReturn();
        return objectMapper.readTree(res.getResponse().getContentAsString()).get("data").get("token").asText();
    }

    @Test
    @DisplayName("Admin and Staff can retrieve dashboard summary successfully (200 OK)")
    void adminAndStaff_getDashboardSummary_success() throws Exception {
        // Staff check
        mockMvc.perform(get("/api/v1/admin/dashboard/summary")
                        .header("Authorization", "Bearer " + staffToken)
                        .param("days", "14"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.totalOrders", notNullValue()))
                .andExpect(jsonPath("$.data.totalRevenue", notNullValue()))
                .andExpect(jsonPath("$.data.cancelledOrders", notNullValue()))
                .andExpect(jsonPath("$.data.newCustomers", notNullValue()))
                .andExpect(jsonPath("$.data.revenueOverTime", hasSize(14)))
                .andExpect(jsonPath("$.data.revenueByCategory", notNullValue()))
                .andExpect(jsonPath("$.data.revenueByBranch", notNullValue()))
                .andExpect(jsonPath("$.data.bestSellingProducts", notNullValue()));

        // Admin check
        mockMvc.perform(get("/api/v1/admin/dashboard/summary")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.revenueOverTime", hasSize(30)));
    }

    @Test
    @DisplayName("Revenue counts only COMPLETED orders, ignoring PENDING or CANCELLED")
    void dashboard_revenueOnlyFromCompletedOrders() throws Exception {
        User customer = userRepository.findByEmail("customer1@gmail.com").orElseThrow();
        Branch branch = branchRepository.findById(1L).orElseThrow();
        Product product = productRepository.findById(1L).orElseThrow();

        // 1. Create a CANCELLED order of 10,000,000
        Order cancelledOrder = Order.builder()
                .orderCode("TEST-CANCELLED-" + UUID.randomUUID().toString().substring(0, 8))
                .user(customer)
                .branch(branch)
                .recipientName("Test Customer")
                .recipientPhone("0901234567")
                .shippingAddress("123 Street")
                .totalItemsAmount(BigDecimal.valueOf(10000000))
                .finalAmount(BigDecimal.valueOf(10000000))
                .status(OrderStatus.CANCELLED)
                .paymentMethod(PaymentMethod.COD)
                .paymentStatus(PaymentStatus.UNPAID)
                .build();
        orderRepository.save(cancelledOrder);

        // 2. Create a COMPLETED order of 5,000,000
        Order completedOrder = Order.builder()
                .orderCode("TEST-COMPLETED-" + UUID.randomUUID().toString().substring(0, 8))
                .user(customer)
                .branch(branch)
                .recipientName("Test Customer")
                .recipientPhone("0901234567")
                .shippingAddress("123 Street")
                .totalItemsAmount(BigDecimal.valueOf(5000000))
                .finalAmount(BigDecimal.valueOf(5000000))
                .status(OrderStatus.COMPLETED)
                .paymentMethod(PaymentMethod.COD)
                .paymentStatus(PaymentStatus.PAID)
                .build();
        completedOrder = orderRepository.save(completedOrder);

        OrderItem item = OrderItem.builder()
                .order(completedOrder)
                .product(product)
                .productName(product.getName())
                .productSku(product.getSku())
                .productImage("img.jpg")
                .unitPrice(BigDecimal.valueOf(5000000))
                .quantity(1)
                .subtotalAmount(BigDecimal.valueOf(5000000))
                .build();
        orderItemRepository.save(item);

        // Query summary
        MvcResult res = mockMvc.perform(get("/api/v1/admin/dashboard/summary")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andReturn();

        var json = objectMapper.readTree(res.getResponse().getContentAsString()).get("data");
        long cancelledCount = json.get("cancelledOrders").asLong();
        double totalRev = json.get("totalRevenue").asDouble();

        assert cancelledCount >= 1;
        assert totalRev >= 5000000;
    }

    @Test
    @DisplayName("Customer cannot access admin dashboard (403 Forbidden)")
    void customer_accessDashboard_shouldReturn403() throws Exception {
        mockMvc.perform(get("/api/v1/admin/dashboard/summary")
                        .header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Unauthenticated guest cannot access admin dashboard (401 Unauthorized)")
    void unauthenticated_accessDashboard_shouldReturn401() throws Exception {
        mockMvc.perform(get("/api/v1/admin/dashboard/summary"))
                .andExpect(status().isUnauthorized());
    }
}


