package com.techstore.dto;

import com.techstore.enums.PaymentMethod;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CheckoutRequest {

    @NotBlank(message = "Họ tên người nhận không được để trống")
    @Size(max = 100, message = "Tên người nhận tối đa 100 ký tự")
    private String recipientName;

    @NotBlank(message = "Số điện thoại người nhận không được để trống")
    @Size(max = 20, message = "Số điện thoại tối đa 20 ký tự")
    private String recipientPhone;

    @NotBlank(message = "Địa chỉ nhận hàng không được để trống")
    @Size(max = 255, message = "Địa chỉ nhận hàng tối đa 255 ký tự")
    private String shippingAddress;

    private Long branchId;

    private String couponCode;

    @NotNull(message = "Phương thức thanh toán không được để trống")
    private PaymentMethod paymentMethod;

    private String notes;

    private Long directProductId;

    private Integer directQuantity;

    private java.util.List<Long> selectedCartItemIds;

    private java.math.BigDecimal shippingFee;

    private java.math.BigDecimal vatRate;

    @Builder.Default
    private Boolean mockPaymentSuccess = true;
}


