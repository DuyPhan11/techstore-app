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
public class AdminReplyReviewRequest {

    @NotBlank(message = "Nội dung phản hồi không được để trống")
    @Size(min = 2, max = 1000, message = "Nội dung phản hồi từ 2 đến 1000 ký tự")
    private String reply;
}
