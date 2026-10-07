package com.techstore.service;

import com.techstore.entity.Brand;
import com.techstore.entity.Branch;
import com.techstore.entity.Inventory;
import com.techstore.repository.BrandRepository;
import com.techstore.repository.BranchRepository;
import com.techstore.entity.Category;
import com.techstore.repository.CategoryRepository;
import com.techstore.exception.ConflictException;
import com.techstore.exception.ResourceNotFoundException;
import com.techstore.dto.PageResponse;
import com.techstore.util.SlugUtil;
import com.techstore.repository.InventoryRepository;
import com.techstore.dto.*;
import com.techstore.entity.Product;
import com.techstore.entity.ProductImage;
import com.techstore.enums.ProductStatus;
import com.techstore.repository.ProductImageRepository;
import com.techstore.repository.ProductRepository;
import com.techstore.specification.ProductSpecification;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ProductServiceImpl implements ProductService {

    private final ProductRepository productRepository;
    private final ProductImageRepository productImageRepository;
    private final CategoryRepository categoryRepository;
    private final BrandRepository brandRepository;
    private final BranchRepository branchRepository;
    private final InventoryRepository inventoryRepository;

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ProductSummaryDto> getProducts(ProductFilterParams params) {
        return listProducts(params, false);
    }

    @Override
    @Transactional(readOnly = true)
    public PageResponse<ProductSummaryDto> getManagementProducts(ProductFilterParams params) {
        return listProducts(params, true);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ProductSummaryDto> getRecommendations(List<Long> viewedIds, Integer limit) {
        int maxItems = (limit != null && limit > 0 && limit <= 50) ? limit : 6;
        List<Product> resultProducts = new ArrayList<>();
        Set<Long> collectedIds = new HashSet<>();

        if (viewedIds != null && !viewedIds.isEmpty()) {
            List<Product> viewedProducts = productRepository.findAllById(viewedIds);

            // Đếm tần suất xem theo Category và Brand (Category/Brand được xem nhiều nhất sẽ đứng đầu)
            Map<Long, Long> categoryFreq = viewedProducts.stream()
                    .filter(p -> p.getCategory() != null)
                    .collect(Collectors.groupingBy(p -> p.getCategory().getId(), Collectors.counting()));

            Map<Long, Long> brandFreq = viewedProducts.stream()
                    .filter(p -> p.getBrand() != null)
                    .collect(Collectors.groupingBy(p -> p.getBrand().getId(), Collectors.counting()));

            List<Long> sortedCategories = categoryFreq.entrySet().stream()
                    .sorted((e1, e2) -> Long.compare(e2.getValue(), e1.getValue()))
                    .map(Map.Entry::getKey)
                    .collect(Collectors.toList());

            List<Long> sortedBrands = brandFreq.entrySet().stream()
                    .sorted((e1, e2) -> Long.compare(e2.getValue(), e1.getValue()))
                    .map(Map.Entry::getKey)
                    .collect(Collectors.toList());

            Set<Long> excludeSet = new HashSet<>(viewedIds);

            // TẦNG 1 (ƯU TIÊN TUYỆT ĐỐI): CÙNG BRAND VÀ CÙNG CATEGORY XEM NHIỀU NHẤT (VD: Các dòng iPhone Apple khác)
            for (Long bId : sortedBrands) {
                for (Long cId : sortedCategories) {
                    if (resultProducts.size() >= maxItems) break;
                    final Long targetBId = bId;
                    final Long targetCId = cId;
                    Specification<Product> step1Spec = (root, q, cb) -> cb.and(
                            cb.equal(root.get("status"), ProductStatus.ACTIVE),
                            cb.not(root.get("id").in(excludeSet)),
                            cb.equal(root.get("brand").get("id"), targetBId),
                            cb.equal(root.get("category").get("id"), targetCId)
                    );
                    List<Product> matched = productRepository.findAll(step1Spec,
                            PageRequest.of(0, maxItems - resultProducts.size(), Sort.by(Sort.Direction.DESC, "id"))).getContent();
                    for (Product p : matched) {
                        if (collectedIds.add(p.getId())) {
                            resultProducts.add(p);
                            excludeSet.add(p.getId());
                        }
                    }
                }
            }

            // TẦNG 2: CÙNG BRAND YÊU THÍCH (Hệ sinh thái Apple: MacBook, iPad, AirPods chính hãng Apple)
            if (resultProducts.size() < maxItems) {
                for (Long bId : sortedBrands) {
                    if (resultProducts.size() >= maxItems) break;
                    final Long targetBId = bId;
                    Specification<Product> step2Spec = (root, q, cb) -> cb.and(
                            cb.equal(root.get("status"), ProductStatus.ACTIVE),
                            cb.not(root.get("id").in(excludeSet)),
                            cb.equal(root.get("brand").get("id"), targetBId)
                    );
                    List<Product> matched = productRepository.findAll(step2Spec,
                            PageRequest.of(0, maxItems - resultProducts.size(), Sort.by(Sort.Direction.DESC, "id"))).getContent();
                    for (Product p : matched) {
                        if (collectedIds.add(p.getId())) {
                            resultProducts.add(p);
                            excludeSet.add(p.getId());
                        }
                    }
                }
            }

            // TẦNG 3: CÙNG CATEGORY XEM NHIỀU NHẤT (Các điện thoại nổi bật của hãng khác: Samsung Galaxy, Xiaomi...)
            if (resultProducts.size() < maxItems) {
                for (Long cId : sortedCategories) {
                    if (resultProducts.size() >= maxItems) break;
                    final Long targetCId = cId;
                    Specification<Product> step3Spec = (root, q, cb) -> cb.and(
                            cb.equal(root.get("status"), ProductStatus.ACTIVE),
                            cb.not(root.get("id").in(excludeSet)),
                            cb.equal(root.get("category").get("id"), targetCId)
                    );
                    List<Product> matched = productRepository.findAll(step3Spec,
                            PageRequest.of(0, maxItems - resultProducts.size(), Sort.by(Sort.Direction.DESC, "id"))).getContent();
                    for (Product p : matched) {
                        if (collectedIds.add(p.getId())) {
                            resultProducts.add(p);
                            excludeSet.add(p.getId());
                        }
                    }
                }
            }
        }

        // TẦNG 4: Fallback nếu người dùng chưa xem gì hoặc chưa đủ maxItems
        if (resultProducts.size() < maxItems) {
            int needed = maxItems - resultProducts.size();
            List<Long> exclude = new ArrayList<>(collectedIds);
            if (viewedIds != null) {
                exclude.addAll(viewedIds);
            }
            Specification<Product> fallbackSpec = ProductSpecification.activeExcludingSpec(exclude);
            Pageable pageable = PageRequest.of(0, needed, Sort.by(Sort.Direction.DESC, "createdAt"));
            List<Product> fallbackProducts = productRepository.findAll(fallbackSpec, pageable).getContent();
            for (Product p : fallbackProducts) {
                if (collectedIds.add(p.getId())) {
                    resultProducts.add(p);
                }
            }
        }

        return convertToSummaryDtos(resultProducts);
    }

    private PageResponse<ProductSummaryDto> listProducts(ProductFilterParams params, boolean management) {
        // Prepare sorting
        String sortBy = "createdAt";
        if (params.getSortBy() != null) {
            String lowerSort = params.getSortBy().toLowerCase();
            if (List.of("price", "name", "createdat", "id").contains(lowerSort)) {
                sortBy = "createdat".equals(lowerSort) ? "createdAt" : lowerSort;
            }
        }

        Sort.Direction direction = "asc".equalsIgnoreCase(params.getSortDir())
                ? Sort.Direction.ASC
                : Sort.Direction.DESC;

        int pageNum = Math.max(params.getPage() != null ? params.getPage() : 0, 0);
        int pageSize = (params.getSize() != null && params.getSize() > 0 && params.getSize() <= 100)
                ? params.getSize()
                : 12;

        Pageable pageable = PageRequest.of(pageNum, pageSize, Sort.by(direction, sortBy));

        // Default to ACTIVE products if status is not explicitly set
        if (params.getStatus() == null && !management) {
            params.setStatus(ProductStatus.ACTIVE);
        }

        Specification<Product> spec = ProductSpecification.filterBy(params);
        Page<Product> productPage = productRepository.findAll(spec, pageable);

        List<ProductSummaryDto> content = convertToSummaryDtos(productPage.getContent());

        return PageResponse.<ProductSummaryDto>builder()
                .content(content)
                .pageNumber(productPage.getNumber())
                .pageSize(productPage.getSize())
                .totalElements(productPage.getTotalElements())
                .totalPages(productPage.getTotalPages())
                .last(productPage.isLast())
                .build();
    }

    private List<ProductSummaryDto> convertToSummaryDtos(List<Product> products) {
        if (products == null || products.isEmpty()) {
            return Collections.emptyList();
        }

        List<Long> productIds = products.stream()
                .map(Product::getId)
                .filter(Objects::nonNull)
                .distinct()
                .collect(Collectors.toList());

        if (productIds.isEmpty()) {
            return Collections.emptyList();
        }

        // 1. Bulk fetch all inventories with branches in 1 single query
        List<Inventory> allInventories = inventoryRepository.findByProductIdInWithBranch(productIds);

        // Group total stock by product ID
        Map<Long, Integer> stockMap = allInventories.stream()
                .filter(inv -> inv.getProduct() != null && inv.getProduct().getId() != null)
                .collect(Collectors.groupingBy(
                        inv -> inv.getProduct().getId(),
                        Collectors.summingInt(inv -> inv.getQuantity() != null ? inv.getQuantity() : 0)
                ));

        // Group branch stocks by product ID
        Map<Long, List<BranchStockDto>> branchStockMap = allInventories.stream()
                .filter(inv -> inv.getProduct() != null && inv.getProduct().getId() != null)
                .collect(Collectors.groupingBy(
                        inv -> inv.getProduct().getId(),
                        Collectors.mapping(inv -> BranchStockDto.builder()
                                        .branchId(inv.getBranch() != null ? inv.getBranch().getId() : null)
                                        .branchName(inv.getBranch() != null ? inv.getBranch().getName() : null)
                                        .branchAddress(inv.getBranch() != null ? inv.getBranch().getAddress() : null)
                                        .quantity(inv.getQuantity() != null ? inv.getQuantity() : 0)
                                        .build(),
                                Collectors.toList()
                        )
                ));

        // 2. Bulk fetch all product images in 1 single query
        List<ProductImage> allImages = productImageRepository.findByProductIdInOrderByDisplayOrderAsc(productIds);
        Map<Long, String> primaryImageMap = new HashMap<>();
        for (ProductImage img : allImages) {
            if (img.getProduct() == null || img.getProduct().getId() == null) continue;
            Long pid = img.getProduct().getId();
            if (Boolean.TRUE.equals(img.getIsPrimary())) {
                primaryImageMap.put(pid, img.getImageUrl());
            } else if (!primaryImageMap.containsKey(pid)) {
                primaryImageMap.put(pid, img.getImageUrl());
            }
        }

        // 3. Map to DTOs in memory (0 extra queries)
        return products.stream()
                .map(product -> {
                    Integer stock = stockMap.getOrDefault(product.getId(), 0);
                    List<BranchStockDto> branchStocks = branchStockMap.getOrDefault(product.getId(), Collections.emptyList());
                    String primaryImg = primaryImageMap.get(product.getId());
                    return ProductSummaryDto.fromEntity(product, stock, branchStocks, primaryImg);
                })
                .collect(Collectors.toList());
    }

    private List<BranchStockDto> getBranchStocks(Long productId) {
        if (productId == null) return new ArrayList<>();
        return inventoryRepository.findByProductId(productId).stream()
                .map(inv -> BranchStockDto.builder()
                        .branchId(inv.getBranch() != null ? inv.getBranch().getId() : null)
                        .branchName(inv.getBranch() != null ? inv.getBranch().getName() : null)
                        .branchAddress(inv.getBranch() != null ? inv.getBranch().getAddress() : null)
                        .quantity(inv.getQuantity() != null ? inv.getQuantity() : 0)
                        .build())
                .collect(Collectors.toList());
    }

    @Override
    @Transactional(readOnly = true)
    public ProductDetailDto getProductById(Long id) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy sản phẩm với ID: " + id));

        Integer stock = inventoryRepository.getTotalStockByProductId(product.getId());
        List<BranchStockDto> branchStocks = getBranchStocks(product.getId());
        return ProductDetailDto.fromEntity(product, stock, branchStocks);
    }

    @Override
    @Transactional(readOnly = true)
    public ProductDetailDto getProductBySlug(String slug) {
        Product product = productRepository.findBySlug(slug)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy sản phẩm với slug: " + slug));

        Integer stock = inventoryRepository.getTotalStockByProductId(product.getId());
        List<BranchStockDto> branchStocks = getBranchStocks(product.getId());
        return ProductDetailDto.fromEntity(product, stock, branchStocks);
    }

    @Override
    @Transactional(readOnly = true)
    public ProductDetailDto getProductForManagement(Long id) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy sản phẩm"));
        List<BranchStockDto> branchStocks = getBranchStocks(id);
        ProductDetailDto dto = ProductDetailDto.fromEntity(product, inventoryRepository.getTotalStockByProductId(id), branchStocks);
        dto.setCostPrice(product.getCostPrice());
        return dto;
    }

    @Override
    @Transactional
    public ProductDetailDto createProduct(ProductCreateRequest request) {
        if (productRepository.existsBySku(request.getSku().trim())) {
            throw new ConflictException("Mã SKU '" + request.getSku() + "' đã tồn tại");
        }

        String targetSlug = (request.getSlug() != null && !request.getSlug().trim().isEmpty())
                ? SlugUtil.toSlug(request.getSlug())
                : SlugUtil.toSlug(request.getName());

        if (productRepository.existsBySlug(targetSlug)) {
            targetSlug += "-" + request.getSku().trim().toLowerCase();
        }

        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy danh mục ID: " + request.getCategoryId()));

        Brand brand = brandRepository.findById(request.getBrandId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thương hiệu ID: " + request.getBrandId()));

        Product product = Product.builder()
                .name(request.getName().trim())
                .slug(targetSlug)
                .sku(request.getSku().trim().toUpperCase())
                .price(request.getPrice())
                .costPrice(request.getCostPrice())
                .category(category)
                .brand(brand)
                .description(request.getDescription())
                .specifications(request.getSpecifications())
                .warrantyMonths(request.getWarrantyMonths() != null ? request.getWarrantyMonths() : 12)
                .status(request.getStatus() != null ? request.getStatus() : ProductStatus.ACTIVE)
                .images(new ArrayList<>())
                .build();

        if (request.getImages() != null && !request.getImages().isEmpty()) {
            for (ProductImageRequest imgReq : request.getImages()) {
                ProductImage img = ProductImage.builder()
                        .product(product)
                        .imageUrl(imgReq.getImageUrl())
                        .isPrimary(Boolean.TRUE.equals(imgReq.getIsPrimary()))
                        .displayOrder(imgReq.getDisplayOrder() != null ? imgReq.getDisplayOrder() : 0)
                        .build();
                product.getImages().add(img);
            }
        }

        Product saved = productRepository.save(product);

        List<BranchStockDto> branchStocks = new ArrayList<>();
        if (request.getInitialBranchId() != null && request.getInitialStock() != null && request.getInitialStock() > 0) {
            Branch branch = branchRepository.findById(request.getInitialBranchId()).orElse(null);
            if (branch != null) {
                Inventory inventory = Inventory.builder()
                        .product(saved)
                        .branch(branch)
                        .quantity(request.getInitialStock())
                        .minStockAlert(5)
                        .build();
                Inventory savedInv = inventoryRepository.save(inventory);
                branchStocks.add(BranchStockDto.builder()
                        .branchId(branch.getId())
                        .branchName(branch.getName())
                        .branchAddress(branch.getAddress())
                        .quantity(savedInv.getQuantity())
                        .build());
            }
        }

        int totalStock = branchStocks.stream().mapToInt(BranchStockDto::getQuantity).sum();
        return ProductDetailDto.fromEntity(saved, totalStock, branchStocks);
    }

    @Override
    @Transactional
    public ProductDetailDto updateProduct(Long id, ProductUpdateRequest request) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy sản phẩm với ID: " + id));

        String targetSku = request.getSku().trim().toUpperCase();
        if (!targetSku.equals(product.getSku()) && productRepository.existsBySku(targetSku)) {
            throw new ConflictException("Mã SKU '" + targetSku + "' đã tồn tại");
        }

        String targetSlug = (request.getSlug() != null && !request.getSlug().trim().isEmpty())
                ? SlugUtil.toSlug(request.getSlug())
                : SlugUtil.toSlug(request.getName());

        if (!targetSlug.equals(product.getSlug()) && productRepository.existsBySlug(targetSlug)) {
            throw new ConflictException("Slug sản phẩm '" + targetSlug + "' đã tồn tại");
        }

        Category category = categoryRepository.findById(request.getCategoryId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy danh mục ID: " + request.getCategoryId()));

        Brand brand = brandRepository.findById(request.getBrandId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thương hiệu ID: " + request.getBrandId()));

        product.setName(request.getName().trim());
        product.setSlug(targetSlug);
        product.setSku(targetSku);
        product.setPrice(request.getPrice());
        product.setCostPrice(request.getCostPrice());
        product.setCategory(category);
        product.setBrand(brand);
        product.setDescription(request.getDescription());
        product.setSpecifications(request.getSpecifications());
        if (request.getWarrantyMonths() != null) {
            product.setWarrantyMonths(request.getWarrantyMonths());
        }
        if (request.getStatus() != null) {
            product.setStatus(request.getStatus());
        }

        if (request.getImages() != null) {
            product.getImages().clear();
            for (ProductImageRequest imgReq : request.getImages()) {
                ProductImage img = ProductImage.builder()
                        .product(product)
                        .imageUrl(imgReq.getImageUrl())
                        .isPrimary(Boolean.TRUE.equals(imgReq.getIsPrimary()))
                        .displayOrder(imgReq.getDisplayOrder() != null ? imgReq.getDisplayOrder() : 0)
                        .build();
                product.getImages().add(img);
            }
        }

        Product updated = productRepository.save(product);
        Integer stock = inventoryRepository.getTotalStockByProductId(updated.getId());
        List<BranchStockDto> branchStocks = getBranchStocks(updated.getId());
        ProductDetailDto dto = ProductDetailDto.fromEntity(updated, stock, branchStocks);
        dto.setCostPrice(updated.getCostPrice());
        return dto;
    }

    @Override
    @Transactional
    public void deleteProduct(Long id) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy sản phẩm với ID: " + id));
        product.setStatus(ProductStatus.INACTIVE);
        productRepository.save(product);
    }

    @Override
    @Transactional
    public ProductDetailDto updateProductStatus(Long id, ProductStatus status) {
        Product product = productRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy sản phẩm với ID: " + id));

        ProductStatus targetStatus = (status != null)
                ? status
                : (product.getStatus() == ProductStatus.ACTIVE ? ProductStatus.INACTIVE : ProductStatus.ACTIVE);

        product.setStatus(targetStatus);
        Product saved = productRepository.save(product);
        Integer stock = inventoryRepository.getTotalStockByProductId(saved.getId());
        List<BranchStockDto> branchStocks = getBranchStocks(saved.getId());
        return ProductDetailDto.fromEntity(saved, stock, branchStocks);
    }

    @Override
    @Transactional
    public ProductImageDto addProductImage(Long productId, ProductImageRequest request) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy sản phẩm với ID: " + productId));

        if (Boolean.TRUE.equals(request.getIsPrimary())) {
            product.getImages().forEach(img -> img.setIsPrimary(false));
        }

        ProductImage image = ProductImage.builder()
                .product(product)
                .imageUrl(request.getImageUrl())
                .isPrimary(Boolean.TRUE.equals(request.getIsPrimary()))
                .displayOrder(request.getDisplayOrder() != null ? request.getDisplayOrder() : 0)
                .build();

        ProductImage saved = productImageRepository.save(image);
        return ProductImageDto.fromEntity(saved);
    }

    @Override
    @Transactional
    public void deleteProductImage(Long productId, Long imageId) {
        ProductImage image = productImageRepository.findById(imageId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hình ảnh với ID: " + imageId));

        if (!image.getProduct().getId().equals(productId)) {
            throw new ResourceNotFoundException("Hình ảnh không thuộc về sản phẩm ID: " + productId);
        }

        productImageRepository.delete(image);
    }

    @Override
    @Transactional
    public void setPrimaryImage(Long productId, Long imageId) {
        Product product = productRepository.findById(productId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy sản phẩm với ID: " + productId));

        boolean found = false;
        for (ProductImage img : product.getImages()) {
            if (img.getId().equals(imageId)) {
                img.setIsPrimary(true);
                found = true;
            } else {
                img.setIsPrimary(false);
            }
        }

        if (!found) {
            throw new ResourceNotFoundException("Hình ảnh ID " + imageId + " không thuộc sản phẩm ID " + productId);
        }

        productRepository.save(product);
    }
}


