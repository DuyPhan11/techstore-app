package com.techstore;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.techstore.dto.LoginRequest;
import com.techstore.dto.RegisterRequest;
import com.techstore.repository.CartRepository;
import com.techstore.entity.User;
import com.techstore.enums.UserStatus;
import com.techstore.repository.UserRepository;
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
class AuthIntegrationTest {
    @org.springframework.test.context.bean.override.mockito.MockitoBean
    private org.springframework.mail.javamail.JavaMailSender mailSender;

    @Test
    void passwordResetDeliversTokenOnlyByEmailAndCannotBeReused() throws Exception {
        mockMvc.perform(post("/api/v1/auth/forgot-password")
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"email\":\"customer2@gmail.com\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.token").doesNotExist());
        var message = org.mockito.ArgumentCaptor.forClass(org.springframework.mail.SimpleMailMessage.class);
        org.mockito.Mockito.verify(mailSender).send(message.capture());
        org.junit.jupiter.api.Assertions.assertEquals("customer2@gmail.com", message.getValue().getTo()[0]);
        String token = message.getValue().getText().split("#token=")[1].split("\\s")[0];
        String payload = objectMapper.writeValueAsString(java.util.Map.of("token", token, "newPassword", "new-password123"));
        mockMvc.perform(post("/api/v1/auth/reset-password").contentType(MediaType.APPLICATION_JSON).content(payload))
                .andExpect(status().isOk());
        mockMvc.perform(post("/api/v1/auth/reset-password").contentType(MediaType.APPLICATION_JSON).content(payload))
                .andExpect(status().isBadRequest());
        mockMvc.perform(post("/api/v1/auth/login").contentType(MediaType.APPLICATION_JSON)
                .content("{\"username\":\"customer2@gmail.com\",\"password\":\"new-password123\"}"))
                .andExpect(status().isOk());
    }

    @Test
    void unknownResetEmailReturnsGenericResponseWithoutSendingMail() throws Exception {
        mockMvc.perform(post("/api/v1/auth/forgot-password")
                .contentType(MediaType.APPLICATION_JSON).content("{\"email\":\"unknown@example.invalid\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.token").doesNotExist());
        org.mockito.Mockito.verifyNoInteractions(mailSender);
    }

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private CartRepository cartRepository;

    @Test
    @DisplayName("Register sends OTP and leaves the account pending verification")
    void registerSuccess() throws Exception {
        org.mockito.Mockito.when(mailSender.createMimeMessage())
                .thenReturn(org.mockito.Mockito.mock(jakarta.mail.internet.MimeMessage.class));
        RegisterRequest request = RegisterRequest.builder()
                .fullName("Test User")
                .email("test.newuser@techstore.com")
                .phone("0988776655")
                .password("securePassword123")
                .build();

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.tokenType", is("PENDING_VERIFICATION")))
                .andExpect(jsonPath("$.data.token").doesNotExist())
                .andExpect(jsonPath("$.data.user.email", is("test.newuser@techstore.com")))
                .andExpect(jsonPath("$.data.user.roles", hasItem("ROLE_CUSTOMER")));

        User savedUser = userRepository.findByEmail("test.newuser@techstore.com").orElse(null);
        assertNotNull(savedUser);
        assertNotEquals("securePassword123", savedUser.getPassword(), "Password must be hashed with BCrypt");
        assertEquals(UserStatus.PENDING_VERIFICATION, savedUser.getStatus());
        assertFalse(cartRepository.existsByUserId(savedUser.getId()), "Cart is initialized after OTP verification");
        org.mockito.Mockito.verify(mailSender).send(org.mockito.ArgumentMatchers.any(jakarta.mail.internet.MimeMessage.class));
    }

    @Test
    @DisplayName("SMTP failure fails registration and rolls back the pending account")
    void registerMailFailureDoesNotExposeOtpOrLeavePendingAccount() throws Exception {
        org.mockito.Mockito.when(mailSender.createMimeMessage())
                .thenReturn(org.mockito.Mockito.mock(jakarta.mail.internet.MimeMessage.class));
        org.mockito.Mockito.doThrow(new org.springframework.mail.MailSendException("SMTP unavailable"))
                .when(mailSender).send(org.mockito.ArgumentMatchers.any(jakarta.mail.internet.MimeMessage.class));
        RegisterRequest request = RegisterRequest.builder()
                .fullName("Mail Failure")
                .email("mail.failure@techstore.com")
                .phone("0988776656")
                .password("securePassword123")
                .build();

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isServiceUnavailable())
                .andExpect(jsonPath("$.success", is(false)));
        assertTrue(userRepository.findByEmail("mail.failure@techstore.com").isEmpty(),
                "Failed email delivery must roll back pending account creation");
    }

    @Test
    @DisplayName("Test 2: Duplicate Email or Phone - Should return 409 Conflict")
    void registerDuplicateEmailOrPhone() throws Exception {
        RegisterRequest request1 = RegisterRequest.builder()
                .fullName("First User")
                .email("duplicate.test@techstore.com")
                .phone("0911223344")
                .password("password123")
                .build();

        // Register first user
        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request1)))
                .andExpect(status().isCreated());

        // Register with same email
        RegisterRequest duplicateEmailRequest = RegisterRequest.builder()
                .fullName("Second User")
                .email("duplicate.test@techstore.com")
                .phone("0999888777")
                .password("password123")
                .build();

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(duplicateEmailRequest)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.message", containsString("Email đã được sử dụng")));

        // Register with same phone
        RegisterRequest duplicatePhoneRequest = RegisterRequest.builder()
                .fullName("Third User")
                .email("another.email@techstore.com")
                .phone("0911223344")
                .password("password123")
                .build();

        mockMvc.perform(post("/api/v1/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(duplicatePhoneRequest)))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.message", containsString("Số điện thoại đã được sử dụng")));
    }

    @Test
    @DisplayName("Test 3: Wrong Password - Should return 401 Unauthorized")
    void loginWrongPassword() throws Exception {
        LoginRequest request = LoginRequest.builder()
                .username("admin@techstore.com")
                .password("incorrect_password")
                .build();

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.message", containsString("không chính xác")));
    }

    @Test
    @DisplayName("Test 4: Locked Account - Should return 403 Forbidden")
    void loginLockedAccount() throws Exception {
        // Create a dedicated locked user
        User lockedUser = User.builder()
                .email("locked.testuser@techstore.com")
                .phone("0988000999")
                .fullName("Locked Test User")
                .password(userRepository.findByEmail("admin@techstore.com").get().getPassword())
                .status(UserStatus.LOCKED)
                .build();
        userRepository.saveAndFlush(lockedUser);

        LoginRequest request = LoginRequest.builder()
                .username("locked.testuser@techstore.com")
                .password("password123")
                .build();

        mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success", is(false)))
                .andExpect(jsonPath("$.message", containsString("đã bị khóa")));
    }

    @Test
    @DisplayName("Test 5: Role Authorization - Customer cannot access /admin, Admin can")
    void roleAuthorization() throws Exception {
        // 1. Login as Customer
        LoginRequest customerLogin = LoginRequest.builder()
                .username("customer2@gmail.com")
                .password("password123")
                .build();

        MvcResult customerResult = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(customerLogin)))
                .andExpect(status().isOk())
                .andReturn();

        String customerResponseStr = customerResult.getResponse().getContentAsString();
        String customerToken = objectMapper.readTree(customerResponseStr).get("data").get("token").asText();

        // Customer attempts to call Admin ping endpoint -> Must be 403 Forbidden
        mockMvc.perform(get("/api/v1/admin/ping")
                        .header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isForbidden());

        // 2. Login as Admin
        LoginRequest adminLogin = LoginRequest.builder()
                .username("admin@techstore.com")
                .password("password123")
                .build();

        MvcResult adminResult = mockMvc.perform(post("/api/v1/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(adminLogin)))
                .andExpect(status().isOk())
                .andReturn();

        String adminResponseStr = adminResult.getResponse().getContentAsString();
        String adminToken = objectMapper.readTree(adminResponseStr).get("data").get("token").asText();

        // Admin calls Admin ping endpoint -> Must be 200 OK
        mockMvc.perform(get("/api/v1/admin/ping")
                        .header("Authorization", "Bearer " + adminToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success", is(true)))
                .andExpect(jsonPath("$.data.role", is("ADMIN")));
    }
}



