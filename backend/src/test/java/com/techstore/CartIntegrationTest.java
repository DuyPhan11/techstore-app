package com.techstore;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.techstore.dto.LoginRequest;
import com.techstore.dto.AddToCartRequest;
import com.techstore.dto.UpdateCartItemRequest;
import com.techstore.entity.Product;
import com.techstore.enums.ProductStatus;
import com.techstore.repository.ProductRepository;
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

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class CartIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private ProductRepository productRepository;

    private String customerToken;

    @BeforeEach
    void setUp() throws Exception {
        LoginRequest customerLogin = LoginRequest.builder()
                .username("customer1@gmail.com")
                .password("password123")
                .build();

        MvcResult custRes = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(customerLogin)))
                .andExpect(status().isOk())
                .andReturn();

        customerToken = objectMapper.readTree(custRes.getResponse().getContentAsString())
                .get("data").get("token").asText();
    }

    @Test
    @DisplayName("Test 1: Unauthenticated request to /cart should return 401 Unauthorized")
    void getCart_unauthenticated_shouldReturn401() throws Exception {
        mockMvc.perform(get("/api/v1/cart"))
                .andExpect(status().isUnauthorized());
    }

    @Test
    @DisplayName("Test 2: Authenticated customer gets cart successfully")
    void getCart_authenticated_shouldReturnCart() throws Exception {
        mockMvc.perform(get("/api/v1/cart")
                        .header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.id", notNullValue()))
                .andExpect(jsonPath("$.data.items", notNullValue()));
    }

    @Test
    @DisplayName("Test 3: Add to cart succeeds and calculates subtotal & totalPrice correctly")
    void addToCart_success_shouldAddAndCalculateSubtotal() throws Exception {
        // Product 1: iPhone 15 Pro Max, price = 29,990,000
        AddToCartRequest request = AddToCartRequest.builder()
                .productId(1L)
                .quantity(2)
                .build();

        mockMvc.perform(post("/api/v1/cart/items")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.totalItems", is(2)))
                .andExpect(jsonPath("$.data.totalPrice", is(59980000.0)))
                .andExpect(jsonPath("$.data.items[0].productId", is(1)))
                .andExpect(jsonPath("$.data.items[0].quantity", is(2)))
                .andExpect(jsonPath("$.data.items[0].subtotal", is(59980000.0)))
                .andExpect(jsonPath("$.data.items[0].inStock", is(true)))
                .andExpect(jsonPath("$.data.items[0].availableStock", greaterThanOrEqualTo(2)));
    }

    @Test
    @DisplayName("Test 4: Add inactive product to cart should return 400 Bad Request")
    void addToCart_inactiveProduct_shouldReturn400() throws Exception {
        // Deactivate product 5 temporarily
        Product product5 = productRepository.findById(5L).orElseThrow();
        product5.setStatus(ProductStatus.INACTIVE);
        productRepository.saveAndFlush(product5);

        AddToCartRequest request = AddToCartRequest.builder()
                .productId(5L)
                .quantity(1)
                .build();

        mockMvc.perform(post("/api/v1/cart/items")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.message", containsString("không hoạt động hoặc đã ngừng kinh doanh")));
    }

    @Test
    @DisplayName("Test 5: Add product exceeding available stock should return 400 Bad Request")
    void addToCart_exceedStock_shouldReturn400() throws Exception {
        // Product 1 has stock = 90. Request 999 units
        AddToCartRequest request = AddToCartRequest.builder()
                .productId(1L)
                .quantity(999)
                .build();

        mockMvc.perform(post("/api/v1/cart/items")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.message", containsString("vượt quá số lượng tồn kho")));
    }

    @Test
    @DisplayName("Test 6: Update cart item quantity and recalculate subtotals")
    void updateCartItem_validQuantity_shouldRecalculate() throws Exception {
        // Add 1 item first
        AddToCartRequest addReq = AddToCartRequest.builder()
                .productId(1L)
                .quantity(1)
                .build();

        mockMvc.perform(post("/api/v1/cart/items")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(addReq)))
                .andExpect(status().isOk());

        // Update to 3 units
        UpdateCartItemRequest updateReq = UpdateCartItemRequest.builder()
                .quantity(3)
                .build();

        mockMvc.perform(put("/api/v1/cart/items/1")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalItems", is(3)))
                .andExpect(jsonPath("$.data.totalPrice", is(89970000.0)))
                .andExpect(jsonPath("$.data.items[0].quantity", is(3)));

        // Update to 0 -> should remove item
        UpdateCartItemRequest zeroReq = UpdateCartItemRequest.builder()
                .quantity(0)
                .build();

        mockMvc.perform(put("/api/v1/cart/items/1")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(zeroReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalItems", is(0)))
                .andExpect(jsonPath("$.data.items", hasSize(0)));
    }

    @Test
    @DisplayName("Test 7: Remove item from cart")
    void removeCartItem_shouldRemoveItemFromCart() throws Exception {
        // Add item
        AddToCartRequest addReq = AddToCartRequest.builder()
                .productId(1L)
                .quantity(1)
                .build();

        mockMvc.perform(post("/api/v1/cart/items")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(addReq)))
                .andExpect(status().isOk());

        // Remove item
        mockMvc.perform(delete("/api/v1/cart/items/1")
                        .header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items", hasSize(0)))
                .andExpect(jsonPath("$.data.totalItems", is(0)));
    }

    @Test
    @DisplayName("Test 8: Clear cart should delete all items")
    void clearCart_shouldEmptyCart() throws Exception {
        // Add 2 items
        AddToCartRequest add1 = AddToCartRequest.builder().productId(1L).quantity(1).build();
        AddToCartRequest add2 = AddToCartRequest.builder().productId(2L).quantity(1).build();

        mockMvc.perform(post("/api/v1/cart/items")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(add1)))
                .andExpect(status().isOk());

        mockMvc.perform(post("/api/v1/cart/items")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(add2)))
                .andExpect(status().isOk());

        // Clear cart
        mockMvc.perform(delete("/api/v1/cart")
                        .header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)));

        // Verify cart is empty
        mockMvc.perform(get("/api/v1/cart")
                        .header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items", hasSize(0)))
                .andExpect(jsonPath("$.data.totalItems", is(0)))
                .andExpect(jsonPath("$.data.totalPrice", is(0)));
    }
}


