package com.techstore.controller;

import com.techstore.dto.BranchDto;
import com.techstore.dto.BranchRequest;
import com.techstore.service.BranchService;
import com.techstore.dto.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/admin/branches")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminBranchController {

    private final BranchService branchService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<BranchDto>>> getAllBranches(
            @RequestParam(required = false) String status) {
        List<BranchDto> branches = branchService.getAllBranches(status);
        return ResponseEntity.ok(ApiResponse.ok("Lấy danh sách chi nhánh thành công", branches));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<BranchDto>> getBranchById(@PathVariable Long id) {
        BranchDto branch = branchService.getBranchById(id);
        return ResponseEntity.ok(ApiResponse.ok("Lấy thông tin chi nhánh thành công", branch));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<BranchDto>> createBranch(@Valid @RequestBody BranchRequest request) {
        BranchDto created = branchService.createBranch(request);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.ok("Tạo chi nhánh thành công", created));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<BranchDto>> updateBranch(
            @PathVariable Long id,
            @Valid @RequestBody BranchRequest request) {
        BranchDto updated = branchService.updateBranch(id, request);
        return ResponseEntity.ok(ApiResponse.ok("Cập nhật thông tin chi nhánh thành công", updated));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteBranch(@PathVariable Long id) {
        branchService.deleteBranch(id);
        return ResponseEntity.ok(ApiResponse.ok("Vô hiệu hóa chi nhánh thành công", null));
    }
}


