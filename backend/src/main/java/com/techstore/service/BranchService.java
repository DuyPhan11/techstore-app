package com.techstore.service;

import com.techstore.dto.BranchDto;
import com.techstore.dto.BranchRequest;

import java.util.List;

public interface BranchService {
    List<BranchDto> getActiveBranches();
    List<BranchDto> getAllBranches(String status);
    BranchDto getBranchById(Long id);
    BranchDto createBranch(BranchRequest request);
    BranchDto updateBranch(Long id, BranchRequest request);
    void deleteBranch(Long id);
}


