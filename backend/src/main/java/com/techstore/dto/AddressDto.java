package com.techstore.dto;

import com.techstore.entity.Address;
import lombok.*;

import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AddressDto {
    private Long id;
    private String recipientName;
    private String phone;
    private String streetAddress;
    private String ward;
    private String district;
    private String city;
    private String fullAddress;
    private Boolean isDefault;
    private LocalDateTime createdAt;

    public static AddressDto fromEntity(Address address) {
        if (address == null) return null;

        StringBuilder sb = new StringBuilder();
        if (address.getStreetAddress() != null && !address.getStreetAddress().isBlank()) {
            sb.append(address.getStreetAddress().trim());
        }
        if (address.getWard() != null && !address.getWard().isBlank()) {
            if (sb.length() > 0) sb.append(", ");
            sb.append(address.getWard().trim());
        }
        if (address.getDistrict() != null && !address.getDistrict().isBlank()) {
            if (sb.length() > 0) sb.append(", ");
            sb.append(address.getDistrict().trim());
        }
        if (address.getCity() != null && !address.getCity().isBlank()) {
            if (sb.length() > 0) sb.append(", ");
            sb.append(address.getCity().trim());
        }

        return AddressDto.builder()
                .id(address.getId())
                .recipientName(address.getRecipientName())
                .phone(address.getPhone())
                .streetAddress(address.getStreetAddress())
                .ward(address.getWard())
                .district(address.getDistrict())
                .city(address.getCity())
                .fullAddress(sb.toString())
                .isDefault(Boolean.TRUE.equals(address.getIsDefault()))
                .createdAt(address.getCreatedAt())
                .build();
    }
}
