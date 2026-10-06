package com.techstore.repository;

import com.techstore.entity.VerificationCode;
import com.techstore.enums.VerificationType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.Optional;

@Repository
public interface VerificationCodeRepository extends JpaRepository<VerificationCode, Long> {

    Optional<VerificationCode> findFirstByEmailAndCodeAndTypeAndIsUsedFalseAndExpiryDateAfterOrderByCreatedAtDesc(
            String email,
            String code,
            VerificationType type,
            LocalDateTime now
    );

    @Modifying
    @Query("DELETE FROM VerificationCode v WHERE v.email = :email AND v.type = :type")
    void deleteAllByEmailAndType(@Param("email") String email, @Param("type") VerificationType type);
}
