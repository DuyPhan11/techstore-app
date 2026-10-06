package com.techstore.dto;

import com.techstore.enums.RoleName;
import com.techstore.enums.UserStatus;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class UserFilterParams {
    private String search;
    private UserStatus status;
    private RoleName role;
    
    @Builder.Default
    private Integer page = 0;
    
    @Builder.Default
    private Integer size = 10;
}


