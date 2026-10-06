package com.techstore.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.*;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AddressRequest {

    @NotBlank(message = "Tên người nhận không được để trống")
    private String recipientName;

    @NotBlank(message = "Số điện thoại không được để trống")
    private String phone;

    @NotBlank(message = "Địa chỉ chi tiết (số nhà, đường) không được để trống")
    private String streetAddress;

    private String ward;

    private String district;

    @NotBlank(message = "Tỉnh / Thành phố không được để trống")
    private String city;

    private Boolean isDefault;
}
