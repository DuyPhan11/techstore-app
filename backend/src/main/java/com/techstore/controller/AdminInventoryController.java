package com.techstore.controller;

import com.techstore.dto.ApiResponse;
import com.techstore.dto.PageResponse;
import com.techstore.dto.InventoryDto;
import com.techstore.dto.InventoryFilterParams;
import com.techstore.dto.StockAdjustmentRequest;
import com.techstore.dto.StockTransferRequest;
import com.techstore.service.InventoryService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin/inventory")
@RequiredArgsConstructor
@PreAuthorize("hasAnyRole('STAFF', 'ADMIN')")
public class AdminInventoryController {

    private final InventoryService inventoryService;

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<InventoryDto>>> getInventory(
            @RequestParam(required = false) Long productId,
            @RequestParam(required = false) Long branchId,
            @RequestParam(required = false) Boolean lowStock,
            @RequestParam(required = false) String search,
            @RequestParam(defaultValue = "0") Integer page,
            @RequestParam(defaultValue = "10") Integer size) {

        InventoryFilterParams params = InventoryFilterParams.builder()
                .productId(productId)
                .branchId(branchId)
                .lowStock(lowStock)
                .search(search)
                .page(page)
                .size(size)
                .build();

        PageResponse<InventoryDto> response = inventoryService.getInventory(params);
        return ResponseEntity.ok(ApiResponse.ok("Lấy danh sách tồn kho thành công", response));
    }

    @PostMapping("/adjust")
    public ResponseEntity<ApiResponse<InventoryDto>> adjustStock(
            @Valid @RequestBody StockAdjustmentRequest request) {

        InventoryDto result = inventoryService.adjustStock(request);
        return ResponseEntity.ok(ApiResponse.ok("Điều chỉnh tồn kho thành công", result));
    }

    @PostMapping("/transfer")
    public ResponseEntity<ApiResponse<Void>> transferStock(
            @Valid @RequestBody StockTransferRequest request) {

        inventoryService.transferStock(request);
        return ResponseEntity.ok(ApiResponse.ok("Điều chuyển tồn kho giữa chi nhánh thành công", null));
    }
}


