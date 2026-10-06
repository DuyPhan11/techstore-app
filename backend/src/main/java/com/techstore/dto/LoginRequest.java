package com.techstore.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class LoginRequest {

    @NotBlank(message = "Tài khoản (Email hoặc SĐT) không được để trống")
    @com.fasterxml.jackson.annotation.JsonAlias({"email", "username"})
    private String username;

    @NotBlank(message = "Mật khẩu không được để trống")
    private String password;
}

