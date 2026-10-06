package com.techstore.repository;

import com.techstore.entity.Order;
import com.techstore.enums.OrderStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long>, JpaSpecificationExecutor<Order> {
    Optional<Order> findByOrderCode(String orderCode);
    Optional<Order> findByIdAndUserId(Long id, Long userId);
    Optional<Order> findByOrderCodeAndUserId(String orderCode, Long userId);
    Page<Order> findByUserId(Long userId, Pageable pageable);
    Page<Order> findByUserIdAndStatus(Long userId, OrderStatus status, Pageable pageable);
    java.util.List<Order> findByUserIdAndStatusOrderByCreatedAtDesc(Long userId, OrderStatus status);
    Page<Order> findByStatus(OrderStatus status, Pageable pageable);
    boolean existsByOrderCode(String orderCode);

    @org.springframework.data.jpa.repository.Query("SELECT o FROM Order o JOIN o.items i WHERE o.user.id = :userId AND o.status = com.techstore.enums.OrderStatus.COMPLETED AND i.product.id = :productId ORDER BY o.createdAt DESC")
    java.util.List<Order> findCompletedOrdersByUserAndProduct(@org.springframework.data.repository.query.Param("userId") Long userId, @org.springframework.data.repository.query.Param("productId") Long productId);

    long countByStatus(OrderStatus status);

    @org.springframework.data.jpa.repository.Query("SELECT COALESCE(SUM(o.finalAmount), 0) FROM Order o WHERE o.status = :status")
    java.math.BigDecimal sumTotalRevenueByStatus(@org.springframework.data.repository.query.Param("status") OrderStatus status);

    @org.springframework.data.jpa.repository.Query("SELECT o.branch.id, o.branch.name, COALESCE(SUM(o.finalAmount), 0), COUNT(o.id) " +
           "FROM Order o WHERE o.status = com.techstore.enums.OrderStatus.COMPLETED " +
           "GROUP BY o.branch.id, o.branch.name " +
           "ORDER BY SUM(o.finalAmount) DESC")
    java.util.List<Object[]> getRevenueByBranch();

    @org.springframework.data.jpa.repository.Query("SELECT o FROM Order o WHERE o.status = com.techstore.enums.OrderStatus.COMPLETED AND o.createdAt >= :startDate AND o.createdAt <= :endDate ORDER BY o.createdAt ASC")
    java.util.List<Order> findCompletedOrdersBetween(@org.springframework.data.repository.query.Param("startDate") java.time.LocalDateTime startDate, @org.springframework.data.repository.query.Param("endDate") java.time.LocalDateTime endDate);

    @org.springframework.data.jpa.repository.Query("SELECT COUNT(o) FROM Order o WHERE o.createdAt >= :startDate AND o.createdAt <= :endDate")
    long countOrdersBetween(@org.springframework.data.repository.query.Param("startDate") java.time.LocalDateTime startDate, @org.springframework.data.repository.query.Param("endDate") java.time.LocalDateTime endDate);

    @org.springframework.data.jpa.repository.Query("SELECT COUNT(o) FROM Order o WHERE o.status = :status AND o.createdAt >= :startDate AND o.createdAt <= :endDate")
    long countOrdersByStatusBetween(@org.springframework.data.repository.query.Param("status") OrderStatus status, @org.springframework.data.repository.query.Param("startDate") java.time.LocalDateTime startDate, @org.springframework.data.repository.query.Param("endDate") java.time.LocalDateTime endDate);

    @org.springframework.data.jpa.repository.Query("SELECT o.branch.id, o.branch.name, COALESCE(SUM(o.finalAmount), 0), COUNT(o.id) " +
           "FROM Order o WHERE o.status = com.techstore.enums.OrderStatus.COMPLETED AND o.createdAt >= :startDate AND o.createdAt <= :endDate " +
           "GROUP BY o.branch.id, o.branch.name " +
           "ORDER BY SUM(o.finalAmount) DESC")
    java.util.List<Object[]> getRevenueByBranchBetween(@org.springframework.data.repository.query.Param("startDate") java.time.LocalDateTime startDate, @org.springframework.data.repository.query.Param("endDate") java.time.LocalDateTime endDate);
}


