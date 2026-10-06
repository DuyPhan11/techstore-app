package com.techstore.repository;

import com.techstore.entity.OrderItem;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OrderItemRepository extends JpaRepository<OrderItem, Long> {
    List<OrderItem> findByOrderId(Long orderId);

    @Query("SELECT oi.product.id, oi.productName, oi.productSku, oi.productImage, SUM(oi.quantity), SUM(oi.subtotalAmount) " +
           "FROM OrderItem oi " +
           "WHERE oi.order.status = com.techstore.enums.OrderStatus.COMPLETED " +
           "GROUP BY oi.product.id, oi.productName, oi.productSku, oi.productImage " +
           "ORDER BY SUM(oi.quantity) DESC")
    List<Object[]> getBestSellingProducts(Pageable pageable);

    @Query("SELECT c.id, c.name, COALESCE(SUM(oi.subtotalAmount), 0), COALESCE(SUM(oi.quantity), 0) " +
           "FROM OrderItem oi " +
           "JOIN oi.product p " +
           "JOIN p.category c " +
           "WHERE oi.order.status = com.techstore.enums.OrderStatus.COMPLETED " +
           "GROUP BY c.id, c.name " +
           "ORDER BY SUM(oi.subtotalAmount) DESC")
    List<Object[]> getRevenueByCategory();

    @Query("SELECT c.id, c.name, COALESCE(SUM(oi.subtotalAmount), 0), COALESCE(SUM(oi.quantity), 0) " +
           "FROM OrderItem oi " +
           "JOIN oi.product p " +
           "JOIN p.category c " +
           "WHERE oi.order.status = com.techstore.enums.OrderStatus.COMPLETED " +
           "AND oi.order.createdAt >= :startDate AND oi.order.createdAt <= :endDate " +
           "GROUP BY c.id, c.name " +
           "ORDER BY SUM(oi.subtotalAmount) DESC")
    List<Object[]> getRevenueByCategoryBetween(@org.springframework.data.repository.query.Param("startDate") java.time.LocalDateTime startDate, @org.springframework.data.repository.query.Param("endDate") java.time.LocalDateTime endDate);

    @Query("SELECT oi.product.id, oi.productName, oi.productSku, oi.productImage, SUM(oi.quantity), SUM(oi.subtotalAmount) " +
           "FROM OrderItem oi " +
           "WHERE oi.order.status = com.techstore.enums.OrderStatus.COMPLETED " +
           "AND oi.order.createdAt >= :startDate AND oi.order.createdAt <= :endDate " +
           "GROUP BY oi.product.id, oi.productName, oi.productSku, oi.productImage " +
           "ORDER BY SUM(oi.quantity) DESC")
    List<Object[]> getBestSellingProductsBetween(@org.springframework.data.repository.query.Param("startDate") java.time.LocalDateTime startDate, @org.springframework.data.repository.query.Param("endDate") java.time.LocalDateTime endDate, Pageable pageable);
}


