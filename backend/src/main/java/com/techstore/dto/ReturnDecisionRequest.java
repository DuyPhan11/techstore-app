package com.techstore.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ReturnDecisionRequest {

    private Boolean approve;

    private String rejectReason;

    private Boolean refundDirectly;

    private String note;
}
