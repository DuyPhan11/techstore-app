package com.techstore.repository;

import com.techstore.entity.Cart;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface CartRepository extends JpaRepository<Cart, Long> {
    Optional<Cart> findByUserId(Long userId);
    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("select c from Cart c where c.user.id = :userId")
    Optional<Cart> findByUserIdWithLock(@org.springframework.data.repository.query.Param("userId") Long userId);
    boolean existsByUserId(Long userId);
}


