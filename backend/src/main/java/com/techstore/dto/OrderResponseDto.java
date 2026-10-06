package com.techstore.dto;

import com.techstore.entity.Order;
import com.techstore.enums.OrderStatus;
import com.techstore.enums.PaymentMethod;
import com.techstore.enums.PaymentStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class OrderResponseDto {

    private Long id;
    private String orderCode;
    private String recipientName;
    private String recipientPhone;
    private String shippingAddress;
    private Long branchId;
    private String branchName;
    private BigDecimal totalItemsAmount;
    private BigDecimal discountAmount;
    private BigDecimal shippingFee;
    private BigDecimal taxAmount;
    private BigDecimal vatRate;
    private BigDecimal finalAmount;
    private OrderStatus status;
    private PaymentMethod paymentMethod;
    private PaymentStatus paymentStatus;
    private String transactionCode;
    private String couponCode;
    private String notes;
    private String returnReason;
    private String returnNote;
    private String returnImages;
    private String bankInfo;
    private String returnRejectReason;
    private LocalDateTime returnRequestedAt;
    private LocalDateTime refundedAt;
    private LocalDateTime completedAt;
    private List<OrderItemResponseDto> items;
    private LocalDateTime createdAt;

    public static OrderResponseDto fromEntity(Order order) {
        if (order == null) {
            return null;
        }

        List<OrderItemResponseDto> itemDtos = Collections.emptyList();
        if (order.getItems() != null) {
            itemDtos = order.getItems().stream()
                    .map(OrderItemResponseDto::fromEntity)
                    .collect(Collectors.toList());
        }

        String txCode = null;
        if (order.getPayment() != null) {
            txCode = order.getPayment().getTransactionCode();
        }

        String couponCode = null;
        if (order.getCoupon() != null) {
            couponCode = order.getCoupon().getCode();
        }

        return OrderResponseDto.builder()
                .id(order.getId())
                .orderCode(order.getOrderCode())
                .recipientName(order.getRecipientName())
                .recipientPhone(order.getRecipientPhone())
                .shippingAddress(order.getShippingAddress())
                .branchId(order.getBranch() != null ? order.getBranch().getId() : null)
                .branchName(order.getBranch() != null ? order.getBranch().getName() : null)
                .totalItemsAmount(order.getTotalItemsAmount())
                .discountAmount(order.getDiscountAmount())
                .shippingFee(order.getShippingFee() != null ? order.getShippingFee() : BigDecimal.ZERO)
                .taxAmount(order.getTaxAmount() != null ? order.getTaxAmount() : BigDecimal.ZERO)
                .vatRate(order.getVatRate() != null ? order.getVatRate() : new BigDecimal("0.08"))
                .finalAmount(order.getFinalAmount())
                .status(order.getStatus())
                .paymentMethod(order.getPaymentMethod())
                .paymentStatus(order.getPaymentStatus())
                .transactionCode(txCode)
                .couponCode(couponCode)
                .notes(order.getNotes())
                .returnReason(order.getReturnReason())
                .returnNote(order.getReturnNote())
                .returnImages(order.getReturnImages())
                .bankInfo(order.getBankInfo())
                .returnRejectReason(order.getReturnRejectReason())
                .returnRequestedAt(order.getReturnRequestedAt())
                .refundedAt(order.getRefundedAt())
                .completedAt(order.getCompletedAt())
                .items(itemDtos)
                .createdAt(order.getCreatedAt())
                .build();
    }
}


