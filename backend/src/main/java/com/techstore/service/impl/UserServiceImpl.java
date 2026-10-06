package com.techstore.service.impl;

import com.techstore.exception.BadRequestException;
import com.techstore.exception.ConflictException;
import com.techstore.exception.ResourceNotFoundException;
import com.techstore.dto.PageResponse;
import com.techstore.dto.*;
import com.techstore.entity.Role;
import com.techstore.entity.User;
import com.techstore.enums.RoleName;
import com.techstore.enums.UserStatus;
import com.techstore.repository.RoleRepository;
import com.techstore.repository.UserRepository;
import com.techstore.service.UserService;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.Predicate;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoder;

    @Override
    @Transactional(readOnly = true)
    public PageResponse<UserResponseDto> getUsers(UserFilterParams params) {
        Pageable pageable = PageRequest.of(
                params.getPage() != null ? params.getPage() : 0,
                params.getSize() != null ? params.getSize() : 10,
                Sort.by(Sort.Direction.DESC, "createdAt")
        );

        Specification<User> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (params.getSearch() != null && !params.getSearch().trim().isEmpty()) {
                String searchPattern = "%" + params.getSearch().trim().toLowerCase() + "%";
                Predicate emailPredicate = cb.like(cb.lower(root.get("email")), searchPattern);
                Predicate phonePredicate = cb.like(cb.lower(root.get("phone")), searchPattern);
                Predicate namePredicate = cb.like(cb.lower(root.get("fullName")), searchPattern);
                predicates.add(cb.or(emailPredicate, phonePredicate, namePredicate));
            }

            if (params.getStatus() != null) {
                predicates.add(cb.equal(root.get("status"), params.getStatus()));
            }

            if (params.getRole() != null) {
                Join<User, Role> rolesJoin = root.join("roles");
                predicates.add(cb.equal(rolesJoin.get("name"), params.getRole()));
            }

            query.distinct(true);
            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<User> userPage = userRepository.findAll(spec, pageable);
        return PageResponse.from(userPage.map(this::mapToResponseDto));
    }

    @Override
    @Transactional(readOnly = true)
    public UserResponseDto getUserById(Long id) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại với ID: " + id));
        return mapToResponseDto(user);
    }

    @Override
    @Transactional
    public UserResponseDto updateUserStatus(Long id, UserStatus status, String currentAdminEmail) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại với ID: " + id));

        if (user.getEmail().equalsIgnoreCase(currentAdminEmail) && status == UserStatus.LOCKED) {
            throw new BadRequestException("Bạn không thể tự khóa tài khoản của chính mình.");
        }

        user.setStatus(status);
        User saved = userRepository.save(user);
        log.info("User status updated: id={}, email={}, status={}", saved.getId(), saved.getEmail(), status);
        return mapToResponseDto(saved);
    }

    @Override
    @Transactional
    public UserResponseDto updateUserRoles(Long id, Set<RoleName> roleNames, String currentAdminEmail) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Người dùng không tồn tại với ID: " + id));

        if (user.getEmail().equalsIgnoreCase(currentAdminEmail) && !roleNames.contains(RoleName.ROLE_ADMIN)) {
            throw new BadRequestException("Bạn không thể tự gỡ quyền Quản trị viên của chính mình.");
        }

        Set<Role> roles = new HashSet<>();
        for (RoleName rn : roleNames) {
            Role role = roleRepository.findByName(rn)
                    .orElseThrow(() -> new ResourceNotFoundException("Vai trò không tồn tại: " + rn));
            roles.add(role);
        }

        user.setRoles(roles);
        User saved = userRepository.save(user);
        log.info("User roles updated: id={}, email={}, roles={}", saved.getId(), saved.getEmail(), roleNames);
        return mapToResponseDto(saved);
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<UserResponseDto> getStaffUsers(UserFilterParams params) {
        params.setRole(RoleName.ROLE_STAFF);
        return getUsers(params);
    }

    @Override
    @Transactional
    public UserResponseDto createStaff(CreateStaffRequest request) {
        if (userRepository.existsByEmail(request.getEmail().trim().toLowerCase())) {
            throw new ConflictException("Email '" + request.getEmail() + "' đã được sử dụng trong hệ thống.");
        }

        if (userRepository.existsByPhone(request.getPhone().trim())) {
            throw new ConflictException("Số điện thoại '" + request.getPhone() + "' đã được sử dụng trong hệ thống.");
        }

        Role staffRole = roleRepository.findByName(RoleName.ROLE_STAFF)
                .orElseThrow(() -> new ResourceNotFoundException("Vai trò ROLE_STAFF không tồn tại"));

        User staff = User.builder()
                .fullName(request.getFullName().trim())
                .email(request.getEmail().trim().toLowerCase())
                .phone(request.getPhone().trim())
                .password(passwordEncoder.encode(request.getPassword()))
                .status(UserStatus.ACTIVE)
                .roles(new HashSet<>(Set.of(staffRole)))
                .build();

        User saved = userRepository.save(staff);
        log.info("Staff created successfully: id={}, email={}", saved.getId(), saved.getEmail());
        return mapToResponseDto(saved);
    }

    @Override
    @Transactional
    public UserResponseDto updateStaffStatus(Long id, UserStatus status, String currentAdminEmail) {
        User user = userRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Nhân viên không tồn tại với ID: " + id));

        boolean isStaff = user.getRoles().stream().anyMatch(r -> r.getName() == RoleName.ROLE_STAFF);
        if (!isStaff) {
            throw new BadRequestException("Người dùng với ID " + id + " không phải là nhân viên.");
        }

        return updateUserStatus(id, status, currentAdminEmail);
    }

    private UserResponseDto mapToResponseDto(User user) {
        Set<String> roleNames = user.getRoles().stream()
                .map(r -> r.getName().name())
                .collect(Collectors.toSet());

        return UserResponseDto.builder()
                .id(user.getId())
                .email(user.getEmail())
                .phone(user.getPhone())
                .fullName(user.getFullName())
                .avatarUrl(user.getAvatarUrl())
                .status(user.getStatus())
                .roles(roleNames)
                .createdAt(user.getCreatedAt())
                .updatedAt(user.getUpdatedAt())
                .build();
    }
}


