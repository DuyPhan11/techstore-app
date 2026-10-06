package com.techstore.controller;

import com.techstore.dto.ApiResponse;
import lombok.extern.slf4j.Slf4j;
import com.cloudinary.Cloudinary;
import com.cloudinary.utils.ObjectUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.servlet.support.ServletUriComponentsBuilder;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.*;

@Slf4j
@RestController
@RequestMapping("/api/v1/uploads")
public class FileUploadController {

    private static final String UPLOAD_DIR = "uploads/images";
    private static final Set<String> ALLOWED_EXTENSIONS = Set.of("jpg", "jpeg", "png", "webp", "gif");

    @Autowired(required = false)
    private Cloudinary cloudinary;

    @PostMapping("/image")
    @PreAuthorize("isAuthenticated()")
    public ResponseEntity<ApiResponse<Map<String, Object>>> uploadImage(
            @RequestParam("file") MultipartFile file) {

        if (file.isEmpty()) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Vui lòng chọn file hình ảnh"));
        }

        String originalFilename = StringUtils.cleanPath(Objects.requireNonNullElse(file.getOriginalFilename(), "image.jpg"));
        String extension = "";
        int dotIdx = originalFilename.lastIndexOf('.');
        if (dotIdx > 0) {
            extension = originalFilename.substring(dotIdx + 1).toLowerCase();
        }

        if (!ALLOWED_EXTENSIONS.contains(extension)) {
            return ResponseEntity.badRequest().body(ApiResponse.error("Định dạng file không hợp lệ. Chỉ chấp nhận JPG, PNG, WEBP, GIF"));
        }

        // 1. Ưu tiên upload trực tiếp lên Cloudinary nếu có cấu hình (chuẩn cho Render / Cloud)
        if (cloudinary != null) {
            try {
                @SuppressWarnings("rawtypes")
                Map uploadResult = cloudinary.uploader().upload(file.getBytes(), ObjectUtils.asMap(
                        "folder", "techstore/products",
                        "resource_type", "image"
                ));

                String secureUrl = (String) uploadResult.get("secure_url");
                String publicId = (String) uploadResult.get("public_id");

                Map<String, Object> data = new HashMap<>();
                data.put("url", secureUrl);
                data.put("fileName", publicId);
                data.put("size", file.getSize());
                data.put("provider", "cloudinary");

                log.info("Uploaded product image to Cloudinary successfully: {}", secureUrl);
                return ResponseEntity.status(HttpStatus.CREATED)
                        .body(ApiResponse.ok("Tải ảnh lên Cloudinary thành công", data));
            } catch (Exception e) {
                log.error("Cloudinary upload failed, falling back to local storage: {}", e.getMessage(), e);
            }
        }

        // 2. Fallback lưu trữ cục bộ trên máy chủ nếu chưa cấu hình Cloudinary keys
        try {
            Path targetFolder = Paths.get(UPLOAD_DIR).toAbsolutePath().normalize();
            if (!Files.exists(targetFolder)) {
                Files.createDirectories(targetFolder);
            }

            String newFilename = UUID.randomUUID().toString().replace("-", "") + "_" + originalFilename;
            Path targetFile = targetFolder.resolve(newFilename);

            Files.copy(file.getInputStream(), targetFile, StandardCopyOption.REPLACE_EXISTING);

            String fileUrl = ServletUriComponentsBuilder.fromCurrentContextPath()
                    .path("/uploads/images/")
                    .path(newFilename)
                    .toUriString();

            Map<String, Object> data = new HashMap<>();
            data.put("url", fileUrl);
            data.put("fileName", newFilename);
            data.put("size", file.getSize());

            log.info("Uploaded product image successfully: {}", fileUrl);
            return ResponseEntity.status(HttpStatus.CREATED)
                    .body(ApiResponse.ok("Tải ảnh lên thành công", data));

        } catch (IOException e) {
            log.error("Failed to store uploaded image: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApiResponse.error("Lỗi khi lưu trữ file: " + e.getMessage()));
        }
    }
}
