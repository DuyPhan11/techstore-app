package com.techstore.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CategoryRequest {

    @NotBlank(message = "Tên danh mục không được để trống")
    @Size(max = 100, message = "Tên danh mục tối đa 100 ký tự")
    private String name;

    @Size(max = 100, message = "Slug tối đa 100 ký tự")
    private String slug;

    private String description;

    @Size(max = 255, message = "Đường dẫn ảnh tối đa 255 ký tự")
    private String imageUrl;

    @Builder.Default
    private String status = "ACTIVE";
}

