package com.techstore.service;

import com.techstore.dto.PageResponse;
import com.techstore.dto.*;
import com.techstore.enums.RoleName;
import com.techstore.enums.UserStatus;

import java.util.Set;

public interface UserService {

    PageResponse<UserResponseDto> getUsers(UserFilterParams params);

    UserResponseDto getUserById(Long id);

    UserResponseDto updateUserStatus(Long id, UserStatus status, String currentAdminEmail);

    UserResponseDto updateUserRoles(Long id, Set<RoleName> roles, String currentAdminEmail);

    PageResponse<UserResponseDto> getStaffUsers(UserFilterParams params);

    UserResponseDto createStaff(CreateStaffRequest request);

    UserResponseDto updateStaffStatus(Long id, UserStatus status, String currentAdminEmail);
}


