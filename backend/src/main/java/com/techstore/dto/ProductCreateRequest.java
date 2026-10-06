package com.techstore.dto;

import com.techstore.enums.ProductStatus;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ProductCreateRequest {

    @NotBlank(message = "Tên sản phẩm không được để trống")
    @Size(max = 200, message = "Tên sản phẩm tối đa 200 ký tự")
    private String name;

    @Size(max = 255, message = "Slug tối đa 255 ký tự")
    private String slug;

    @NotBlank(message = "Mã SKU không được để trống")
    @Size(max = 50, message = "SKU tối đa 50 ký tự")
    private String sku;

    @NotNull(message = "Giá bán không được để trống")
    @DecimalMin(value = "0.0", inclusive = false, message = "Giá bán phải lớn hơn 0")
    private BigDecimal price;

    @NotNull(message = "Giá vốn không được để trống")
    @DecimalMin(value = "0.0", inclusive = false, message = "Giá vốn phải lớn hơn 0")
    private BigDecimal costPrice;

    @NotNull(message = "Danh mục không được để trống")
    private Long categoryId;

    @NotNull(message = "Thương hiệu không được để trống")
    private Long brandId;

    private String description;

    private String specifications;

    @Builder.Default
    private ProductStatus status = ProductStatus.ACTIVE;

    @Builder.Default
    private Integer warrantyMonths = 12;

    private Long initialBranchId;

    private Integer initialStock;

    @Builder.Default
    @jakarta.validation.Valid
    private List<ProductImageRequest> images = new ArrayList<>();
}


