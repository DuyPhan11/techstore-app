package com.techstore.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReturnRequestDto {

    @NotBlank(message = "Vui lòng chọn lý do đổi trả")
    private String reason;

    private String note;

    private String returnImages;

    private String bankName;

    private String bankAccountNumber;

    private String bankAccountName;
}
