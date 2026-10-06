package com.techstore.repository;

import com.techstore.entity.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long>, JpaSpecificationExecutor<User> {
    Optional<User> findByEmail(String email);
    Optional<User> findByPhone(String phone);
    boolean existsByEmail(String email);
    boolean existsByPhone(String phone);
    Page<User> findAll(Pageable pageable);

    @org.springframework.data.jpa.repository.Query("SELECT COUNT(DISTINCT u) FROM User u JOIN u.roles r WHERE r.name = :roleName")
    long countByRole(@org.springframework.data.repository.query.Param("roleName") com.techstore.enums.RoleName roleName);

    @org.springframework.data.jpa.repository.Query("SELECT COUNT(DISTINCT u) FROM User u JOIN u.roles r WHERE r.name = :roleName AND u.createdAt >= :since")
    long countByRoleAndCreatedAtAfter(@org.springframework.data.repository.query.Param("roleName") com.techstore.enums.RoleName roleName, @org.springframework.data.repository.query.Param("since") java.time.LocalDateTime since);
}


