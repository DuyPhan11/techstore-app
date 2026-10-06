package com.techstore.controller;

import com.techstore.dto.ApiResponse;
import com.techstore.dto.PageResponse;
import com.techstore.dto.CreateStaffRequest;
import com.techstore.dto.UpdateUserStatusRequest;
import com.techstore.dto.UserFilterParams;
import com.techstore.dto.UserResponseDto;
import com.techstore.enums.UserStatus;
import com.techstore.service.UserService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin/staff")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminStaffController {

    private final UserService userService;

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<UserResponseDto>>> getStaffUsers(
            @RequestParam(required = false) String search,
            @RequestParam(required = false) UserStatus status,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "10") Integer size) {

        UserFilterParams params = UserFilterParams.builder()
                .search(search)
                .status(status)
                .page(page)
                .size(size)
                .build();

        PageResponse<UserResponseDto> result = userService.getStaffUsers(params);
        return ResponseEntity.ok(ApiResponse.ok("Lấy danh sách nhân viên thành công", result));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<UserResponseDto>> createStaff(
            @Valid @RequestBody CreateStaffRequest request) {

        UserResponseDto created = userService.createStaff(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Tạo tài khoản nhân viên thành công", created));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<UserResponseDto>> updateStaffStatus(
            @PathVariable Long id,
            @Valid @RequestBody UpdateUserStatusRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {

        UserResponseDto updated = userService.updateStaffStatus(id, request.getStatus(), userDetails.getUsername());
        return ResponseEntity.ok(ApiResponse.ok("Cập nhật trạng thái nhân viên thành công", updated));
    }
}


