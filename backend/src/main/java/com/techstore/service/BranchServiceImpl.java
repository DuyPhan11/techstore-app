package com.techstore.service;

import com.techstore.dto.BranchDto;
import com.techstore.dto.BranchRequest;
import com.techstore.entity.Branch;
import com.techstore.repository.BranchRepository;
import com.techstore.service.BranchService;
import com.techstore.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class BranchServiceImpl implements BranchService {

    private final BranchRepository branchRepository;

    @Override
    @Transactional(readOnly = true)
    public List<BranchDto> getActiveBranches() {
        return branchRepository.findByStatus("ACTIVE").stream()
                .map(BranchDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public List<BranchDto> getAllBranches(String status) {
        if (status != null && !status.isBlank()) {
            return branchRepository.findByStatus(status.toUpperCase()).stream()
                    .map(BranchDto::fromEntity)
                    .collect(Collectors.toList());
        }
        return branchRepository.findAll().stream()
                .map(BranchDto::fromEntity)
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public BranchDto getBranchById(Long id) {
        Branch branch = branchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy chi nhánh với ID: " + id));
        return BranchDto.fromEntity(branch);
    }

    @Override
    @Transactional
    public BranchDto createBranch(BranchRequest request) {
        Branch branch = Branch.builder()
                .name(request.getName().trim())
                .phone(request.getPhone() != null ? request.getPhone().trim() : null)
                .address(request.getAddress().trim())
                .status(request.getStatus() != null ? request.getStatus().toUpperCase() : "ACTIVE")
                .build();

        Branch saved = branchRepository.save(branch);
        log.info("Branch created: id={}, name={}", saved.getId(), saved.getName());
        return BranchDto.fromEntity(saved);
    }

    @Override
    @Transactional
    public BranchDto updateBranch(Long id, BranchRequest request) {
        Branch branch = branchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy chi nhánh với ID: " + id));

        branch.setName(request.getName().trim());
        branch.setPhone(request.getPhone() != null ? request.getPhone().trim() : null);
        branch.setAddress(request.getAddress().trim());
        if (request.getStatus() != null) {
            branch.setStatus(request.getStatus().toUpperCase());
        }

        Branch saved = branchRepository.save(branch);
        log.info("Branch updated: id={}, name={}, status={}", saved.getId(), saved.getName(), saved.getStatus());
        return BranchDto.fromEntity(saved);
    }

    @Override
    @Transactional
    public void deleteBranch(Long id) {
        Branch branch = branchRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy chi nhánh với ID: " + id));

        branch.setStatus("INACTIVE");
        branchRepository.save(branch);
        log.info("Branch deactivated: id={}", id);
    }
}


