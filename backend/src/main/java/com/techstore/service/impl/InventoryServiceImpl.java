package com.techstore.service.impl;

import com.techstore.entity.Branch;
import com.techstore.repository.BranchRepository;
import com.techstore.exception.BadRequestException;
import com.techstore.exception.ResourceNotFoundException;
import com.techstore.dto.PageResponse;
import com.techstore.dto.InventoryDto;
import com.techstore.dto.InventoryFilterParams;
import com.techstore.dto.StockAdjustmentRequest;
import com.techstore.dto.StockTransferRequest;
import com.techstore.entity.Inventory;
import com.techstore.repository.InventoryRepository;
import com.techstore.service.InventoryService;
import com.techstore.entity.Product;
import com.techstore.repository.ProductRepository;
import jakarta.persistence.criteria.Join;
import jakarta.persistence.criteria.Predicate;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class InventoryServiceImpl implements InventoryService {

    private final InventoryRepository inventoryRepository;
    private final ProductRepository productRepository;
    private final BranchRepository branchRepository;

    @Override
    @Transactional(readOnly = true)
    public PageResponse<InventoryDto> getInventory(InventoryFilterParams params) {
        Pageable pageable = PageRequest.of(
                params.getPage() != null ? params.getPage() : 0,
                params.getSize() != null ? params.getSize() : 10,
                Sort.by(Sort.Direction.DESC, "id")
        );

        Specification<Inventory> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (params.getProductId() != null) {
                predicates.add(cb.equal(root.get("product").get("id"), params.getProductId()));
            }

            if (params.getBranchId() != null) {
                predicates.add(cb.equal(root.get("branch").get("id"), params.getBranchId()));
            }

            if (params.getLowStock() != null && params.getLowStock()) {
                predicates.add(cb.lessThanOrEqualTo(root.get("quantity"), root.get("minStockAlert")));
            }

            if (params.getSearch() != null && !params.getSearch().trim().isEmpty()) {
                String pattern = "%" + params.getSearch().trim().toLowerCase() + "%";
                Join<Inventory, Product> productJoin = root.join("product");
                Join<Inventory, Branch> branchJoin = root.join("branch");

                Predicate pName = cb.like(cb.lower(productJoin.get("name")), pattern);
                Predicate pSku = cb.like(cb.lower(productJoin.get("sku")), pattern);
                Predicate bName = cb.like(cb.lower(branchJoin.get("name")), pattern);
                predicates.add(cb.or(pName, pSku, bName));
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        Page<Inventory> page = inventoryRepository.findAll(spec, pageable);
        return PageResponse.from(page.map(InventoryDto::fromEntity));
    }

    @Override
    @Transactional
    public InventoryDto adjustStock(StockAdjustmentRequest request) {
        Product product = productRepository.findById(request.getProductId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy sản phẩm với ID: " + request.getProductId()));

        Branch branch = branchRepository.findById(request.getBranchId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy chi nhánh với ID: " + request.getBranchId()));

        Inventory inventory = inventoryRepository.findByProductIdAndBranchIdWithLock(request.getProductId(), request.getBranchId())
                .orElseGet(() -> Inventory.builder()
                        .product(product)
                        .branch(branch)
                        .quantity(0)
                        .minStockAlert(5)
                        .build());

        int currentQty = inventory.getQuantity() != null ? inventory.getQuantity() : 0;
        int newQty;

        switch (request.getAdjustmentType()) {
            case ADD -> newQty = currentQty + request.getQuantity();
            case SUBTRACT -> {
                newQty = currentQty - request.getQuantity();
                if (newQty < 0) {
                    throw new BadRequestException("Số lượng tồn kho không đủ để giảm. Hiện có: " + currentQty + ", yêu cầu giảm: " + request.getQuantity());
                }
            }
            case SET -> newQty = request.getQuantity();
            default -> throw new BadRequestException("Loại điều chỉnh không hợp lệ");
        }

        inventory.setQuantity(newQty);
        inventory.setUpdatedAt(LocalDateTime.now());
        Inventory saved = inventoryRepository.save(inventory);

        log.info("Inventory adjusted: product={}, branch={}, oldQty={}, newQty={}, type={}, reason={}",
                product.getName(), branch.getName(), currentQty, newQty, request.getAdjustmentType(), request.getReason());

        return InventoryDto.fromEntity(saved);
    }

    @Override
    @Transactional
    public void transferStock(StockTransferRequest request) {
        if (request.getFromBranchId().equals(request.getToBranchId())) {
            throw new BadRequestException("Chi nhánh xuất và chi nhánh nhập không được trùng nhau.");
        }

        Product product = productRepository.findById(request.getProductId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy sản phẩm với ID: " + request.getProductId()));

        Branch fromBranch = branchRepository.findById(request.getFromBranchId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy chi nhánh xuất với ID: " + request.getFromBranchId()));

        Branch toBranch = branchRepository.findById(request.getToBranchId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy chi nhánh nhập với ID: " + request.getToBranchId()));

        Inventory fromInventory = inventoryRepository.findByProductIdAndBranchIdWithLock(request.getProductId(), request.getFromBranchId())
                .orElseThrow(() -> new BadRequestException("Sản phẩm chưa có tồn kho tại chi nhánh xuất: " + fromBranch.getName()));

        int fromQty = fromInventory.getQuantity() != null ? fromInventory.getQuantity() : 0;
        if (fromQty < request.getQuantity()) {
            throw new BadRequestException("Tồn kho tại chi nhánh '" + fromBranch.getName() + "' không đủ để chuyển. Hiện có: "
                    + fromQty + ", cần chuyển: " + request.getQuantity());
        }

        fromInventory.setQuantity(fromQty - request.getQuantity());
        fromInventory.setUpdatedAt(LocalDateTime.now());
        inventoryRepository.save(fromInventory);

        Inventory toInventory = inventoryRepository.findByProductIdAndBranchIdWithLock(request.getProductId(), request.getToBranchId())
                .orElseGet(() -> Inventory.builder()
                        .product(product)
                        .branch(toBranch)
                        .quantity(0)
                        .minStockAlert(5)
                        .build());

        int toQty = toInventory.getQuantity() != null ? toInventory.getQuantity() : 0;
        toInventory.setQuantity(toQty + request.getQuantity());
        toInventory.setUpdatedAt(LocalDateTime.now());
        inventoryRepository.save(toInventory);

        log.info("Inventory transferred: product={}, fromBranch={}, toBranch={}, quantity={}",
                product.getName(), fromBranch.getName(), toBranch.getName(), request.getQuantity());
    }
}


