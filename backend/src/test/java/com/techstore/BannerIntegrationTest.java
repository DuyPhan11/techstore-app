package com.techstore;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.techstore.dto.CreateBannerRequest;
import com.techstore.dto.LoginRequest;
import com.techstore.dto.UpdateBannerRequest;
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

import java.util.Map;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
class BannerIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    private String adminToken;
    private String customerToken;

    @BeforeEach
    void setUp() throws Exception {
        adminToken = loginAndGetToken("admin@techstore.com", "password123");
        customerToken = loginAndGetToken("customer1@gmail.com", "password123");
    }

    private String loginAndGetToken(String username, String password) throws Exception {
        LoginRequest loginRequest = new LoginRequest(username, password);
        MvcResult result = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(loginRequest)))
                .andExpect(status().isOk())
                .andReturn();

        String responseBody = result.getResponse().getContentAsString();
        Map<?, ?> map = objectMapper.readValue(responseBody, Map.class);
        Map<?, ?> data = (Map<?, ?>) map.get("data");
        return (String) data.get("token");
    }

    @Test
    @DisplayName("Test 1: Anyone can retrieve active banners for homepage")
    void getActiveBanners_success() throws Exception {
        mockMvc.perform(get("/api/v1/banners"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", hasSize(greaterThanOrEqualTo(1))))
                .andExpect(jsonPath("$.data[0].title", notNullValue()));
    }

    @Test
    @DisplayName("Test 2: Admin can get all banners including inactive ones")
    void admin_getAllBanners_success() throws Exception {
        mockMvc.perform(get("/api/v1/admin/banners")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data", hasSize(greaterThanOrEqualTo(1))));
    }

    @Test
    @DisplayName("Test 3: Customer cannot access admin banners endpoint (403 Forbidden)")
    void customer_accessAdminBanners_shouldReturn403() throws Exception {
        mockMvc.perform(get("/api/v1/admin/banners")
                        .header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Test 4: Admin can create a new marketing banner")
    void admin_createBanner_success() throws Exception {
        CreateBannerRequest req = CreateBannerRequest.builder()
                .title("MEGA SALE 2026")
                .subtitle("Giảm sốc toàn sàn")
                .badgeText1("HOT")
                .badgeText2("50%")
                .titleColor("#FF0000")
                .backgroundColor("#000000")
                .iconName("bolt")
                .linkType("COUPON")
                .linkValue("TECH10")
                .displayOrder(10)
                .isActive(true)
                .build();

        mockMvc.perform(post("/api/v1/admin/banners")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.title", is("MEGA SALE 2026")))
                .andExpect(jsonPath("$.data.linkType", is("COUPON")));
    }

    @Test
    @DisplayName("Test 5: Admin can toggle banner status and delete banner")
    void admin_toggleAndDeleteBanner_success() throws Exception {
        CreateBannerRequest req = CreateBannerRequest.builder()
                .title("TEMP BANNER")
                .displayOrder(99)
                .isActive(true)
                .build();

        MvcResult createResult = mockMvc.perform(post("/api/v1/admin/banners")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andReturn();

        Map<?, ?> createdMap = objectMapper.readValue(createResult.getResponse().getContentAsString(), Map.class);
        Map<?, ?> createdData = (Map<?, ?>) createdMap.get("data");
        Number bannerId = (Number) createdData.get("id");

        // Toggle inactive
        mockMvc.perform(patch("/api/v1/admin/banners/" + bannerId + "/status")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("active", false))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.isActive", is(false)));

        // Delete
        mockMvc.perform(delete("/api/v1/admin/banners/" + bannerId)
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)));
    }
}
