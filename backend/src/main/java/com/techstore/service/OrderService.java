package com.techstore.service;

import com.techstore.entity.User;
import com.techstore.dto.CancelOrderRequest;
import com.techstore.dto.OrderFilterParams;
import com.techstore.dto.OrderResponseDto;
import com.techstore.dto.OrderStatusUpdateRequest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

public interface OrderService {

    Page<OrderResponseDto> getMyOrders(User user, Pageable pageable);

    OrderResponseDto getOrderDetail(User user, Long orderId);

    OrderResponseDto cancelOrder(User user, Long orderId, CancelOrderRequest request);

    Page<OrderResponseDto> getAdminOrders(OrderFilterParams filter, Pageable pageable);

    OrderResponseDto getAdminOrderDetail(Long orderId);

    OrderResponseDto updateOrderStatus(Long orderId, OrderStatusUpdateRequest request);

    OrderResponseDto requestReturn(User user, Long orderId, com.techstore.dto.ReturnRequestDto request);

    OrderResponseDto processReturnDecision(Long orderId, com.techstore.dto.ReturnDecisionRequest request);

    OrderResponseDto processRefund(Long orderId, String note);
}


