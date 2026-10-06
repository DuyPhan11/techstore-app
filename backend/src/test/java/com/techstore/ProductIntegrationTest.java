package com.techstore;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.techstore.dto.LoginRequest;
import com.techstore.dto.BrandRequest;
import com.techstore.dto.CategoryRequest;
import com.techstore.dto.ProductCreateRequest;
import com.techstore.dto.ProductImageRequest;
import com.techstore.dto.ProductUpdateRequest;
import com.techstore.entity.Product;
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
import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class ProductIntegrationTest {
    @Test
    void managementListIncludesInactiveProductsAndRequiresStaff() throws Exception {
        Product product = productRepository.findById(1L).orElseThrow();
        product.setStatus(com.techstore.enums.ProductStatus.INACTIVE);
        productRepository.saveAndFlush(product);
        mockMvc.perform(get("/api/v1/products/management").param("keyword", product.getSku())
                .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.content[0].status", is("INACTIVE")));
        mockMvc.perform(get("/api/v1/products/management").header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isForbidden());
    }
    @Test
    void costPriceIsOnlyAvailableToManagement() throws Exception {
        mockMvc.perform(get("/api/v1/products/1"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.costPrice").doesNotExist());
        mockMvc.perform(get("/api/v1/products/1/management"))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(get("/api/v1/products/1/management").header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isForbidden());
        mockMvc.perform(get("/api/v1/products/1/management").header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.costPrice").isNumber());
    }

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private ProductRepository productRepository;

    private String customerToken;
    private String adminToken;

    @BeforeEach
    void setUp() throws Exception {
        // Obtain Customer Token
        LoginRequest customerLogin = LoginRequest.builder()
                .username("customer1@gmail.com")
                .password("password123")
                .build();
        MvcResult custRes = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(customerLogin)))
                .andExpect(status().isOk())
                .andReturn();
        customerToken = objectMapper.readTree(custRes.getResponse().getContentAsString()).get("data").get("token").asText();

        // Obtain Admin Token
        LoginRequest adminLogin = LoginRequest.builder()
                .username("admin@techstore.com")
                .password("password123")
                .build();
        MvcResult adminRes = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(adminLogin)))
                .andExpect(status().isOk())
                .andReturn();
        adminToken = objectMapper.readTree(adminRes.getResponse().getContentAsString()).get("data").get("token").asText();
    }

    @Test
    @DisplayName("Test 1: Public Guest can view product list with default pagination")
    void getProducts_publicAccess_shouldReturn200AndPageResponse() throws Exception {
        mockMvc.perform(get("/api/v1/products"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.content", not(empty())))
                .andExpect(jsonPath("$.data.totalElements", greaterThanOrEqualTo(5)))
                .andExpect(jsonPath("$.data.pageNumber", is(0)));
    }

    @Test
    @DisplayName("Test 2: Search and Filter - Keyword, Category, Price Range and Pagination")
    void getProducts_withFilterAndPagination_shouldFilterCorrectly() throws Exception {
        // Search by keyword "MacBook"
        mockMvc.perform(get("/api/v1/products")
                        .param("keyword", "MacBook"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.content", hasSize(1)))
                .andExpect(jsonPath("$.data.content[0].name", containsString("MacBook Pro")));

        // Search by 'search' query parameter (used by mobile apps)
        mockMvc.perform(get("/api/v1/products")
                        .param("search", "MacBook"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.content", hasSize(1)))
                .andExpect(jsonPath("$.data.content[0].name", containsString("MacBook Pro")));

        // Search by brand name "Apple"
        mockMvc.perform(get("/api/v1/products")
                        .param("keyword", "Apple"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.content", not(empty())));

        // Filter by categoryId 1 (Điện Thoại)
        mockMvc.perform(get("/api/v1/products")
                        .param("categoryId", "1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.content[0].category.id", is(1)));

        // Filter by price range
        mockMvc.perform(get("/api/v1/products")
                        .param("minPrice", "5000000")
                        .param("maxPrice", "6000000"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.content[0].sku", is("APL-APP2-USBC")));

        // Test pagination
        mockMvc.perform(get("/api/v1/products")
                        .param("page", "0")
                        .param("size", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.pageSize", is(2)))
                .andExpect(jsonPath("$.data.content", hasSize(2)));
    }

    @Test
    @DisplayName("Test 3: Get Product Detail by ID and Slug including total stock")
    void getProductByIdAndSlug_shouldReturnDetailWithStock() throws Exception {
        // By ID
        mockMvc.perform(get("/api/v1/products/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.id", is(1)))
                .andExpect(jsonPath("$.data.sku", is("APL-IP15PM-256")))
                .andExpect(jsonPath("$.data.totalStock", is(90))) // 50 (HN) + 40 (HCM)
                .andExpect(jsonPath("$.data.category.id", is(1)))
                .andExpect(jsonPath("$.data.brand.id", is(1)));

        // By Slug
        mockMvc.perform(get("/api/v1/products/slug/iphone-15-pro-max-256gb"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.slug", is("iphone-15-pro-max-256gb")));

        // Non-existent ID -> 404
        mockMvc.perform(get("/api/v1/products/99999"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success", is(false)));
    }

    @Test
    @DisplayName("Test 4: Customer role cannot create, update, or delete products - Should return 403 Forbidden")
    void customerRole_cannotModifyProducts() throws Exception {
        ProductCreateRequest request = ProductCreateRequest.builder()
                .name("Hacker Product")
                .sku("HACK-001")
                .price(new BigDecimal("1000000"))
                .costPrice(new BigDecimal("800000"))
                .categoryId(1L)
                .brandId(1L)
                .build();

        // Customer POST -> 403
        mockMvc.perform(post("/api/v1/products")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());

        // Customer PUT -> 403
        mockMvc.perform(put("/api/v1/products/1")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden());

        // Customer DELETE -> 403
        mockMvc.perform(delete("/api/v1/products/1")
                        .header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Test 5: Admin can create product with images successfully")
    void createProduct_adminRole_shouldReturn201Created() throws Exception {
        ProductCreateRequest request = ProductCreateRequest.builder()
                .name("iPad Pro M4 11 inch 256GB WiFi")
                .sku("APL-IPADM4-11")
                .price(new BigDecimal("28990000"))
                .costPrice(new BigDecimal("25000000"))
                .categoryId(3L) // Tablet
                .brandId(1L)    // Apple
                .description("Màn hình OLED Ultra Retina XDR siêu mỏng, chip M4")
                .specifications("{\"Chip\": \"Apple M4\", \"Bộ nhớ\": \"256GB\"}")
                .images(List.of(
                        ProductImageRequest.builder()
                                .imageUrl("https://example.com/ipad-m4.jpg")
                                .isPrimary(true)
                                .displayOrder(1)
                                .build()
                ))
                .build();

        mockMvc.perform(post("/api/v1/products")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.sku", is("APL-IPADM4-11")))
                .andExpect(jsonPath("$.data.images", hasSize(1)));

        Product saved = productRepository.findBySku("APL-IPADM4-11").orElse(null);
        assertNotNull(saved);
    }

    @Test
    @DisplayName("Test 6: Admin can update product details")
    void updateProduct_adminRole_shouldReturn200() throws Exception {
        ProductUpdateRequest request = ProductUpdateRequest.builder()
                .name("iPhone 15 Pro Max 256GB Titan Tự Nhiên (Khuyến Mãi Đặc Biệt)")
                .sku("APL-IP15PM-256")
                .price(new BigDecimal("28500000"))
                .costPrice(new BigDecimal("26000000"))
                .categoryId(1L)
                .brandId(1L)
                .description("Cập nhật giá ưu đãi tuần lễ Apple")
                .specifications("{\"RAM\": \"8GB\"}")
                .build();

        mockMvc.perform(put("/api/v1/products/1")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.name", containsString("(Khuyến Mãi Đặc Biệt)")))
                .andExpect(jsonPath("$.data.price", is(28500000)));
    }

    @Test
    @DisplayName("Test 7: Category & Brand CRUD - Public view, Customer denied, Admin allowed")
    void categoryAndBrandCrud_roleProtection() throws Exception {
        CategoryRequest catRequest = CategoryRequest.builder()
                .name("Đồng Hồ Thông Minh")
                .description("Apple Watch, Galaxy Watch")
                .build();

        // Customer attempts to create category -> 403
        mockMvc.perform(post("/api/v1/categories")
                        .header("Authorization", "Bearer " + customerToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(catRequest)))
                .andExpect(status().isForbidden());

        // Admin creates category -> 201
        mockMvc.perform(post("/api/v1/categories")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(catRequest)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.name", is("Đồng Hồ Thông Minh")))
                .andExpect(jsonPath("$.data.slug", is("dong-ho-thong-minh")));

        // Public gets categories -> 200
        mockMvc.perform(get("/api/v1/categories"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", not(empty())));

        // Brand CRUD with Admin -> 201
        BrandRequest brandRequest = BrandRequest.builder()
                .name("Sony")
                .description("Tập đoàn thiết bị điện tử Sony")
                .build();

        mockMvc.perform(post("/api/v1/brands")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(brandRequest)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.name", is("Sony")));

        // Public gets brands -> 200
        mockMvc.perform(get("/api/v1/brands"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data", not(empty())));
    }

    @Test
    @DisplayName("Test Recommendations: Public can fetch smart recommendations")
    void testGetRecommendations() throws Exception {
        // Fallback test: no viewedIds provided
        mockMvc.perform(get("/api/v1/products/recommendations"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", not(empty())));

        // With viewedIds: should recommend products and exclude viewedId
        mockMvc.perform(get("/api/v1/products/recommendations")
                        .param("viewedIds", "1")
                        .param("limit", "4"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", not(empty())))
                .andExpect(jsonPath("$.data[*].id", not(hasItem(1))));
    }
}


