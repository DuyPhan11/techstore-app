package com.techstore.controller;

import com.techstore.dto.ApiResponse;
import com.techstore.dto.PageResponse;
import com.techstore.dto.UpdateUserRolesRequest;
import com.techstore.dto.UpdateUserStatusRequest;
import com.techstore.dto.UserFilterParams;
import com.techstore.dto.UserResponseDto;
import com.techstore.enums.RoleName;
import com.techstore.enums.UserStatus;
import com.techstore.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin/users")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminUserController {

    private final UserService userService;

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<UserResponseDto>>> getUsers(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) UserStatus status,
            @RequestParam(required = false) RoleName role,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "10") Integer size) {

        UserFilterParams params = UserFilterParams.builder()
                .search(search)
                .status(status)
                .role(role)
                .page(page)
                .size(size)
                .build();

        PageResponse<UserResponseDto> result = userService.getUsers(params);
        return ResponseEntity.ok(ApiResponse.ok("Lấy danh sách người dùng thành công", result));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<UserResponseDto>> getUserById(@PathVariable Long id) {
        UserResponseDto user = userService.getUserById(id);
        return ResponseEntity.ok(ApiResponse.ok("Lấy thông tin người dùng thành công", user));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<UserResponseDto>> updateUserStatus(
            @PathVariable Long id,
            @Valid @RequestBody UpdateUserStatusRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {

        UserResponseDto updated = userService.updateUserStatus(id, request.getStatus(), userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok("Cập nhật trạng thái người dùng thành công", updated));
    }

    @PutMapping("/{id}/roles")
    public ResponseEntity<ApiResponse<UserResponseDto>> updateUserRoles(
            @PathVariable Long id,
            @Valid @RequestBody UpdateUserRolesRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {

        UserResponseDto updated = userService.updateUserRoles(id, request.getRoles(), userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok("Cập nhật vai trò người dùng thành công", updated));
    }
}


