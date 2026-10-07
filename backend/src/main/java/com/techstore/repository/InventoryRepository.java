package com.techstore.repository;

import com.techstore.entity.Inventory;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface InventoryRepository extends JpaRepository<Inventory, Long>, JpaSpecificationExecutor<Inventory> {

    List<Inventory> findByProductId(Long productId);

    List<Inventory> findByBranchId(Long branchId);

    Optional<Inventory> findByProductIdAndBranchId(Long productId, Long branchId);

    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("SELECT i FROM Inventory i WHERE i.product.id = :productId AND i.branch.id = :branchId")
    Optional<Inventory> findByProductIdAndBranchIdWithLock(@Param("productId") Long productId, @Param("branchId") Long branchId);

    @Query("SELECT COALESCE(SUM(i.quantity), 0) FROM Inventory i WHERE i.product.id = :productId")
    Integer getTotalStockByProductId(@Param("productId") Long productId);

    @Query("SELECT i FROM Inventory i JOIN FETCH i.branch JOIN FETCH i.product WHERE i.product.id IN :productIds")
    List<Inventory> findByProductIdInWithBranch(@Param("productIds") List<Long> productIds);
}


