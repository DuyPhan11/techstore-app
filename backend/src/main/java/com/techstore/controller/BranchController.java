package com.techstore.controller;

import com.techstore.dto.BranchDto;
import com.techstore.service.BranchService;
import com.techstore.dto.ApiResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/v1/branches")
@RequiredArgsConstructor
public class BranchController {

    private final BranchService branchService;

    @GetMapping
    public ResponseEntity<ApiResponse<List<BranchDto>>> getActiveBranches() {
        List<BranchDto> branches = branchService.getActiveBranches();
        return ResponseEntity.ok(ApiResponse.ok("Lấy danh sách chi nhánh thành công", branches));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<BranchDto>> getBranchById(@PathVariable Long id) {
        BranchDto branch = branchService.getBranchById(id);
        return ResponseEntity.ok(ApiResponse.ok("Lấy thông tin chi nhánh thành công", branch));
    }
}


