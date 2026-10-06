package com.techstore.controller;

import com.techstore.dto.AddressDto;
import com.techstore.dto.AddressRequest;
import com.techstore.dto.ApiResponse;
import com.techstore.entity.User;
import com.techstore.exception.ResourceNotFoundException;
import com.techstore.exception.UnauthorizedException;
import com.techstore.repository.UserRepository;
import com.techstore.security.CustomUserDetails;
import com.techstore.service.AddressService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/addresses")
@RequiredArgsConstructor
public class AddressController {

    private final AddressService addressService;
    private final UserRepository userRepository;

    private User getAuthenticatedUser() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null || !authentication.isAuthenticated() || "anonymousUser".equals(authentication.getPrincipal())) {
            throw new UnauthorizedException("Vui lòng đăng nhập để thao tác sổ địa chỉ.");
        }

        if (authentication.getPrincipal() instanceof CustomUserDetails userDetails) {
            return userDetails.getUser();
        }

        String username = authentication.getName();
        return userRepository.findByEmail(username)
                .or(() -> userRepository.findByPhone(username))
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thông tin tài khoản: " + username));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<AddressDto>>> getMyAddresses() {
        User user = getAuthenticatedUser();
        List<AddressDto> list = addressService.getMyAddresses(user);
        return ResponseEntity.ok(ApiResponse.ok("Lấy danh sách địa chỉ thành công", list));
    }

    @GetMapping("/default")
    public ResponseEntity<ApiResponse<AddressDto>> getDefaultAddress() {
        User user = getAuthenticatedUser();
        AddressDto dto = addressService.getDefaultAddress(user);
        return ResponseEntity.ok(ApiResponse.ok("Lấy địa chỉ mặc định thành công", dto));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<AddressDto>> getAddressById(@PathVariable Long id) {
        User user = getAuthenticatedUser();
        AddressDto dto = addressService.getAddressById(user, id);
        return ResponseEntity.ok(ApiResponse.ok("Lấy thông tin địa chỉ thành công", dto));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<AddressDto>> createAddress(@Valid @RequestBody AddressRequest request) {
        User user = getAuthenticatedUser();
        AddressDto created = addressService.createAddress(user, request);
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok("Thêm địa chỉ mới thành công", created));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<AddressDto>> updateAddress(@PathVariable Long id, @Valid @RequestBody AddressRequest request) {
        User user = getAuthenticatedUser();
        AddressDto updated = addressService.updateAddress(user, id, request);
        return ResponseEntity.ok(ApiResponse.ok("Cập nhật địa chỉ thành công", updated));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteAddress(@PathVariable Long id) {
        User user = getAuthenticatedUser();
        addressService.deleteAddress(user, id);
        return ResponseEntity.ok(ApiResponse.ok("Xóa địa chỉ thành công", null));
    }

    @PatchMapping("/{id}/default")
    public ResponseEntity<ApiResponse<AddressDto>> setDefaultAddress(@PathVariable Long id) {
        User user = getAuthenticatedUser();
        AddressDto updated = addressService.setDefaultAddress(user, id);
        return ResponseEntity.ok(ApiResponse.ok("Đặt địa chỉ mặc định thành công", updated));
    }
}
