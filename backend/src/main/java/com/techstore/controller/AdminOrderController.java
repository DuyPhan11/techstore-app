package com.techstore.controller;

import com.techstore.dto.ApiResponse;
import com.techstore.dto.OrderFilterParams;
import com.techstore.dto.OrderResponseDto;
import com.techstore.dto.OrderStatusUpdateRequest;
import com.techstore.service.OrderService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/v1/admin/orders")
@RequiredArgsConstructor
public class AdminOrderController {

    private final OrderService orderService;

    @GetMapping
    public ResponseEntity<ApiResponse<Page<OrderResponseDto>>> getOrders(
            @ModelAttribute OrderFilterParams filter,
            @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
        Page<OrderResponseDto> response = orderService.getAdminOrders(filter, pageable);
        return ResponseEntity.ok(ApiResponse.ok("Lấy danh sách đơn hàng thành công", response));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<OrderResponseDto>> getOrderDetail(@PathVariable Long id) {
        OrderResponseDto response = orderService.getAdminOrderDetail(id);
        return ResponseEntity.ok(ApiResponse.ok("Lấy chi tiết đơn hàng thành công", response));
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<ApiResponse<OrderResponseDto>> updateOrderStatus(
            @PathVariable Long id,
            @Valid @RequestBody OrderStatusUpdateRequest request) {
        OrderResponseDto response = orderService.updateOrderStatus(id, request);
        return ResponseEntity.ok(ApiResponse.ok("Cập nhật trạng thái đơn hàng thành công", response));
    }

    @PostMapping("/{id}/return-decision")
    public ResponseEntity<ApiResponse<OrderResponseDto>> processReturnDecision(
            @PathVariable Long id,
            @RequestBody com.techstore.dto.ReturnDecisionRequest request) {
        OrderResponseDto response = orderService.processReturnDecision(id, request);
        return ResponseEntity.ok(ApiResponse.ok("Xử lý yêu cầu đổi trả thành công", response));
    }

    @PostMapping("/{id}/refund")
    public ResponseEntity<ApiResponse<OrderResponseDto>> processRefund(
            @PathVariable Long id,
            @RequestParam(required = false) String note) {
        OrderResponseDto response = orderService.processRefund(id, note);
        return ResponseEntity.ok(ApiResponse.ok("Xác nhận hoàn tiền thành công", response));
    }
}


