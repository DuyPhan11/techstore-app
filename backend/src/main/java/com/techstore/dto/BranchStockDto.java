package com.techstore.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BranchStockDto {
    private Long branchId;
    private String branchName;
    private String branchAddress;
    private Integer quantity;
}
