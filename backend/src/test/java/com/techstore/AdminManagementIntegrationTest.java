package com.techstore;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.techstore.dto.LoginRequest;
import com.techstore.dto.BranchRequest;
import com.techstore.repository.BranchRepository;
import com.techstore.dto.StockAdjustmentRequest;
import com.techstore.dto.StockTransferRequest;
import com.techstore.enums.AdjustmentType;
import com.techstore.repository.InventoryRepository;
import com.techstore.dto.CreateStaffRequest;
import com.techstore.dto.UpdateUserStatusRequest;
import com.techstore.entity.User;
import com.techstore.enums.UserStatus;
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

import java.util.Map;

import static org.hamcrest.Matchers.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Transactional
public class AdminManagementIntegrationTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private BranchRepository branchRepository;

    @Autowired
    private InventoryRepository inventoryRepository;

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

    // ==========================================
    // 1. USER & STAFF MODULE TESTS
    // ==========================================

    @Test
    @DisplayName("Admin lists users successfully (200 OK)")
    void admin_listUsers_success() throws Exception {
        mockMvc.perform(get("/api/v1/admin/users")
                        .header("Authorization", "Bearer " + adminToken)
                        .param("page", "0")
                        .param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.content", hasSize(greaterThanOrEqualTo(3))));
    }

    @Test
    @DisplayName("Staff cannot list users (403 Forbidden)")
    void staff_accessUsers_shouldReturn403() throws Exception {
        mockMvc.perform(get("/api/v1/admin/users")
                        .header("Authorization", "Bearer " + staffToken))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Customer cannot list users (403 Forbidden)")
    void customer_accessUsers_shouldReturn403() throws Exception {
        mockMvc.perform(get("/api/v1/admin/users")
                        .header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isForbidden());
    }

    @Test
    @DisplayName("Admin locks a customer account successfully (200 OK)")
    void admin_lockUser_success() throws Exception {
        User customer = userRepository.findByEmail("customer1@gmail.com").orElseThrow();

        UpdateUserStatusRequest req = UpdateUserStatusRequest.builder()
                .status(UserStatus.LOCKED)
                .build();

        mockMvc.perform(patch("/api/v1/admin/users/" + customer.getId() + "/status")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.status", is("LOCKED")));
    }

    @Test
    @DisplayName("Admin attempting to lock their own account returns 400 Bad Request")
    void admin_selfLock_shouldReturn400() throws Exception {
        User admin = userRepository.findByEmail("admin@techstore.com").orElseThrow();

        UpdateUserStatusRequest req = UpdateUserStatusRequest.builder()
                .status(UserStatus.LOCKED)
                .build();

        mockMvc.perform(patch("/api/v1/admin/users/" + admin.getId() + "/status")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("tự khóa tài khoản")));
    }

    @Test
    @DisplayName("Admin creates a new staff account successfully (201 Created)")
    void admin_createStaff_success() throws Exception {
        CreateStaffRequest req = CreateStaffRequest.builder()
                .fullName("Lê Nhân Viên Mới")
                .email("newstaff@techstore.com")
                .phone("0981999888")
                .password("password123")
                .build();

        mockMvc.perform(post("/api/v1/admin/staff")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.email", is("newstaff@techstore.com")))
                .andExpect(jsonPath("$.data.roles", hasItem("ROLE_STAFF")));
    }

    @Test
    @DisplayName("Staff cannot create staff accounts (403 Forbidden)")
    void staff_createStaff_shouldReturn403() throws Exception {
        CreateStaffRequest req = CreateStaffRequest.builder()
                .fullName("Hacker Staff")
                .email("hacker@techstore.com")
                .phone("0981777666")
                .password("password123")
                .build();

        mockMvc.perform(post("/api/v1/admin/staff")
                        .header("Authorization", "Bearer " + staffToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isForbidden());
    }

    // ==========================================
    // 2. BRANCH MODULE TESTS
    // ==========================================

    @Test
    @DisplayName("Admin creates and updates store branch successfully (201 & 200)")
    void admin_createAndUpdateBranch_success() throws Exception {
        BranchRequest createReq = BranchRequest.builder()
                .name("TechStore Đà Nẵng")
                .phone("0236-3999-777")
                .address("77 Đường Nguyễn Văn Linh, Đà Nẵng")
                .status("ACTIVE")
                .build();

        MvcResult createRes = mockMvc.perform(post("/api/v1/admin/branches")
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createReq)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.name", is("TechStore Đà Nẵng")))
                .andReturn();

        Long branchId = objectMapper.readTree(createRes.getResponse().getContentAsString())
                .get("data").get("id").asLong();

        BranchRequest updateReq = BranchRequest.builder()
                .name("TechStore Đà Nẵng (Đã Cập Nhật)")
                .phone("0236-3999-888")
                .address("99 Đường Nguyễn Văn Linh, Đà Nẵng")
                .status("ACTIVE")
                .build();

        mockMvc.perform(put("/api/v1/admin/branches/" + branchId)
                        .header("Authorization", "Bearer " + adminToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(updateReq)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name", is("TechStore Đà Nẵng (Đã Cập Nhật)")));
    }

    @Test
    @DisplayName("Staff cannot create branch (403 Forbidden)")
    void staff_createBranch_shouldReturn403() throws Exception {
        BranchRequest createReq = BranchRequest.builder()
                .name("Unauthorized Branch")
                .address("123 Fake Street")
                .build();

        mockMvc.perform(post("/api/v1/admin/branches")
                        .header("Authorization", "Bearer " + staffToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(createReq)))
                .andExpect(status().isForbidden());
    }

    // ==========================================
    // 3. INVENTORY MODULE TESTS
    // ==========================================

    @Test
    @DisplayName("Staff views inventory list successfully (200 OK)")
    void staff_viewInventory_success() throws Exception {
        mockMvc.perform(get("/api/v1/admin/inventory")
                        .header("Authorization", "Bearer " + staffToken)
                        .param("page", "0")
                        .param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.content", hasSize(greaterThanOrEqualTo(1))));
    }

    @Test
    @DisplayName("Staff adjusts inventory stock level (ADD) successfully (200 OK)")
    void staff_adjustStock_add_success() throws Exception {
        // Product 1, Branch 1 currently has 50 in seed.sql
        StockAdjustmentRequest req = StockAdjustmentRequest.builder()
                .productId(1L)
                .branchId(1L)
                .adjustmentType(AdjustmentType.ADD)
                .quantity(20)
                .reason("Nhập kho lô hàng mới")
                .build();

        mockMvc.perform(post("/api/v1/admin/inventory/adjust")
                        .header("Authorization", "Bearer " + staffToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.quantity", is(70)));
    }

    @Test
    @DisplayName("Staff subtracting more stock than available returns 400 Bad Request")
    void staff_adjustStock_subtractExcess_shouldReturn400() throws Exception {
        // Product 1, Branch 1 has 50
        StockAdjustmentRequest req = StockAdjustmentRequest.builder()
                .productId(1L)
                .branchId(1L)
                .adjustmentType(AdjustmentType.SUBTRACT)
                .quantity(9999)
                .reason("Xuất kho vượt mức")
                .build();

        mockMvc.perform(post("/api/v1/admin/inventory/adjust")
                        .header("Authorization", "Bearer " + staffToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message", containsString("không đủ để giảm")));
    }

    @Test
    @DisplayName("Staff transfers stock between branches successfully (200 OK)")
    void staff_transferStock_success() throws Exception {
        // Product 1: Branch 1 has 50, Branch 2 has 40
        StockTransferRequest req = StockTransferRequest.builder()
                .productId(1L)
                .fromBranchId(1L)
                .toBranchId(2L)
                .quantity(10)
                .notes("Chuyển hàng hỗ trợ chi nhánh TP.HCM")
                .build();

        mockMvc.perform(post("/api/v1/admin/inventory/transfer")
                        .header("Authorization", "Bearer " + staffToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)));

        // Verify Branch 1 has 40, Branch 2 has 50
        int b1Stock = inventoryRepository.findByProductIdAndBranchId(1L, 1L).orElseThrow().getQuantity();
        int b2Stock = inventoryRepository.findByProductIdAndBranchId(1L, 2L).orElseThrow().getQuantity();

        assert b1Stock == 40;
        assert b2Stock == 50;
    }

    @Test
    @DisplayName("Customer cannot access inventory endpoints (403 Forbidden)")
    void customer_accessInventory_shouldReturn403() throws Exception {
        mockMvc.perform(get("/api/v1/admin/inventory")
                        .header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isForbidden());
    }
}


