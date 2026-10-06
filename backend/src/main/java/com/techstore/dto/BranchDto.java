package com.techstore.dto;

import com.techstore.entity.Branch;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BranchDto {

    private Long id;
    private String name;
    private String phone;
    private String address;
    private String status;

    public static BranchDto fromEntity(Branch branch) {
        if (branch == null) {
            return null;
        }
        return BranchDto.builder()
                .id(branch.getId())
                .name(branch.getName())
                .phone(branch.getPhone())
                .address(branch.getAddress())
                .status(branch.getStatus())
                .build();
    }
}


