package com.techstore.service.impl;

import com.techstore.entity.User;
import com.techstore.exception.BadRequestException;
import com.techstore.exception.ResourceNotFoundException;
import com.techstore.exception.UnauthorizedException;
import com.techstore.repository.InventoryRepository;
import com.techstore.dto.CancelOrderRequest;
import com.techstore.dto.OrderFilterParams;
import com.techstore.dto.OrderResponseDto;
import com.techstore.dto.OrderStatusUpdateRequest;
import com.techstore.entity.Order;
import com.techstore.entity.OrderItem;
import com.techstore.enums.OrderStatus;
import com.techstore.enums.RoleName;
import com.techstore.repository.OrderRepository;
import com.techstore.service.OrderService;
import com.techstore.enums.PaymentMethod;
import com.techstore.enums.PaymentStatus;
import jakarta.persistence.criteria.Predicate;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class OrderServiceImpl implements OrderService {

    private final OrderRepository orderRepository;
    private final InventoryRepository inventoryRepository;
    private final com.techstore.service.NotificationService notificationService;

    private boolean isUserAdminOrStaff(User user) {
        return user != null && user.getRoles() != null && user.getRoles().stream()
                .anyMatch(r -> r.getName() == RoleName.ROLE_ADMIN || r.getName() == RoleName.ROLE_STAFF);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<OrderResponseDto> getMyOrders(User user, Pageable pageable) {
        return orderRepository.findByUserId(user.getId(), pageable)
                .map(OrderResponseDto::fromEntity);
    }

    @Override
    @Transactional(readOnly = true)
    public OrderResponseDto getOrderDetail(User user, Long orderId) {
        Order order;
        if (isUserAdminOrStaff(user)) {
            order = orderRepository.findById(orderId)
                    .orElseThrow(() -> new ResourceNotFoundException("Order not found with id: " + orderId));
        } else {
            order = orderRepository.findByIdAndUserId(orderId, user.getId())
                    .orElseThrow(() -> new ResourceNotFoundException("Order not found or access denied with id: " + orderId));
        }
        return OrderResponseDto.fromEntity(order);
    }

    @Override
    @Transactional
    public OrderResponseDto cancelOrder(User user, Long orderId, CancelOrderRequest request) {
        Order order;
        if (isUserAdminOrStaff(user)) {
            order = orderRepository.findById(orderId)
                    .orElseThrow(() -> new ResourceNotFoundException("Order not found with id: " + orderId));
        } else {
            order = orderRepository.findByIdAndUserId(orderId, user.getId())
                    .orElseThrow(() -> new ResourceNotFoundException("Order not found or access denied with id: " + orderId));
        }

        if (order.getStatus() == OrderStatus.SHIPPING || order.getStatus() == OrderStatus.COMPLETED) {
            throw new BadRequestException("Cannot cancel order in status " + order.getStatus() + ". Only pending or confirmed orders can be cancelled.");
        }

        if (order.getStatus() == OrderStatus.CANCELLED) {
            throw new BadRequestException("Order is already cancelled");
        }

        restoreInventoryForOrder(order);

        handleCancellationPayment(order);

        if (request != null && request.getReason() != null && !request.getReason().isBlank()) {
            String note = "Customer Cancellation: " + request.getReason().trim();
            order.setNotes(order.getNotes() != null ? order.getNotes() + " | " + note : note);
        }

        order.setStatus(OrderStatus.CANCELLED);
        Order savedOrder = orderRepository.save(order);
        log.info("Order {} successfully cancelled by user {}", order.getOrderCode(), user.getEmail());

        return OrderResponseDto.fromEntity(savedOrder);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<OrderResponseDto> getAdminOrders(OrderFilterParams filter, Pageable pageable) {
        Specification<Order> spec = (root, query, cb) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (filter != null) {
                if (filter.getStatus() != null) {
                    predicates.add(cb.equal(root.get("status"), filter.getStatus()));
                }

                if (filter.getSearch() != null && !filter.getSearch().trim().isEmpty()) {
                    String searchPattern = "%" + filter.getSearch().trim().toLowerCase() + "%";
                    predicates.add(cb.or(
                            cb.like(cb.lower(root.get("orderCode")), searchPattern),
                            cb.like(cb.lower(root.get("recipientName")), searchPattern),
                            cb.like(cb.lower(root.get("recipientPhone")), searchPattern)
                    ));
                }

                if (filter.getFromDate() != null) {
                    predicates.add(cb.greaterThanOrEqualTo(root.get("createdAt"), filter.getFromDate()));
                }

                if (filter.getToDate() != null) {
                    predicates.add(cb.lessThanOrEqualTo(root.get("createdAt"), filter.getToDate()));
                }
            }

            return cb.and(predicates.toArray(new Predicate[0]));
        };

        return orderRepository.findAll(spec, pageable).map(OrderResponseDto::fromEntity);
    }

    @Override
    @Transactional(readOnly = true)
    public OrderResponseDto getAdminOrderDetail(Long orderId) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Order not found with id: " + orderId));
        return OrderResponseDto.fromEntity(order);
    }

    @Override
    @Transactional
    public OrderResponseDto updateOrderStatus(Long orderId, OrderStatusUpdateRequest request) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Order not found with id: " + orderId));

        OrderStatus currentStatus = order.getStatus();
        OrderStatus newStatus = request.getStatus();

        if (currentStatus == newStatus) {
            return OrderResponseDto.fromEntity(order);
        }

        if (currentStatus == OrderStatus.COMPLETED) {
            throw new BadRequestException("Cannot modify an order that is already COMPLETED");
        }

        if (currentStatus == OrderStatus.CANCELLED) {
            throw new BadRequestException("Cannot modify an order that is already CANCELLED");
        }

        if (!isValidTransition(currentStatus, newStatus)) {
            throw new BadRequestException(String.format("Invalid order status transition from %s to %s", currentStatus, newStatus));
        }

        if (newStatus == OrderStatus.CANCELLED) {
            restoreInventoryForOrder(order);
            handleCancellationPayment(order);
        } else if (newStatus == OrderStatus.COMPLETED) {
            if (order.getPaymentMethod() == PaymentMethod.COD && order.getPaymentStatus() == PaymentStatus.UNPAID) {
                order.setPaymentStatus(PaymentStatus.PAID);
                if (order.getPayment() != null) {
                    order.getPayment().setStatus(PaymentStatus.PAID);
                    order.getPayment().setPaidAt(LocalDateTime.now());
                }
            }
        }

        if (request.getNotes() != null && !request.getNotes().isBlank()) {
            String note = "Status Update (" + newStatus + "): " + request.getNotes().trim();
            order.setNotes(order.getNotes() != null ? order.getNotes() + " | " + note : note);
        }

        order.setStatus(newStatus);
        if (newStatus == OrderStatus.COMPLETED && order.getCompletedAt() == null) {
            order.setCompletedAt(LocalDateTime.now());
        }
        Order savedOrder = orderRepository.save(order);
        log.info("Order {} status updated from {} to {}", order.getOrderCode(), currentStatus, newStatus);

        // Send notification to customer
        try {
            if (savedOrder.getUser() != null) {
                String statusDesc = switch (newStatus) {
                    case CONFIRMED -> "đã được nhân viên xác nhận và đang đóng gói sản phẩm.";
                    case SHIPPING -> "đang trên đường giao đến bạn. Hãy để ý điện thoại nhé!";
                    case COMPLETED -> "đã được giao thành công. Cảm ơn bạn đã mua hàng tại TechStore!";
                    case CANCELLED -> "đã bị hủy.";
                    default -> "đã chuyển sang trạng thái: " + newStatus.name();
                };
                notificationService.createNotification(
                        savedOrder.getUser(),
                        "Cập nhật đơn hàng #" + savedOrder.getOrderCode(),
                        "Đơn hàng #" + savedOrder.getOrderCode() + " của bạn " + statusDesc,
                        com.techstore.enums.NotificationType.ORDER,
                        savedOrder.getId().toString()
                );
            }
        } catch (Exception e) {
            log.warn("Failed to notify user for order status update: {}", e.getMessage());
        }

        return OrderResponseDto.fromEntity(savedOrder);
    }

    private boolean isValidTransition(OrderStatus current, OrderStatus target) {
        return switch (current) {
            case PENDING, PAYMENT_PENDING -> target == OrderStatus.CONFIRMED || target == OrderStatus.CANCELLED;
            case CONFIRMED -> target == OrderStatus.SHIPPING || target == OrderStatus.CANCELLED;
            case SHIPPING -> target == OrderStatus.COMPLETED || target == OrderStatus.CANCELLED;
            case COMPLETED -> target == OrderStatus.RETURN_REQUESTED;
            case RETURN_REQUESTED -> target == OrderStatus.RETURN_APPROVED || target == OrderStatus.RETURN_REJECTED || target == OrderStatus.REFUNDED;
            case RETURN_APPROVED -> target == OrderStatus.REFUNDED;
            case RETURN_REJECTED -> target == OrderStatus.COMPLETED;
            case CANCELLED, REFUNDED -> false;
        };
    }

    @Override
    @Transactional
    public OrderResponseDto requestReturn(User user, Long orderId, com.techstore.dto.ReturnRequestDto request) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn hàng ID: " + orderId));

        if (!order.getUser().getId().equals(user.getId())) {
            throw new UnauthorizedException("Bạn không có quyền thực hiện thao tác trên đơn hàng này.");
        }

        if (order.getStatus() != OrderStatus.COMPLETED) {
            throw new BadRequestException("Chỉ đơn hàng đã giao thành công (Hoàn thành) mới có thể yêu cầu đổi trả.");
        }

        LocalDateTime completedTime = order.getCompletedAt() != null
                ? order.getCompletedAt()
                : (order.getUpdatedAt() != null ? order.getUpdatedAt() : order.getCreatedAt());
        if (completedTime != null && java.time.temporal.ChronoUnit.DAYS.between(completedTime, LocalDateTime.now()) > 7) {
            throw new BadRequestException("Đơn hàng đã quá thời hạn 7 ngày đổi trả kể từ ngày nhận hàng thành công.");
        }

        order.setStatus(OrderStatus.RETURN_REQUESTED);
        order.setReturnReason(request.getReason());
        order.setReturnNote(request.getNote());
        order.setReturnImages(request.getReturnImages());

        String bankInfo = "";
        if (request.getBankName() != null && !request.getBankName().isBlank()) {
            bankInfo = request.getBankName().trim() + " - " + (request.getBankAccountNumber() != null ? request.getBankAccountNumber().trim() : "")
                    + " (" + (request.getBankAccountName() != null ? request.getBankAccountName().trim().toUpperCase() : "") + ")";
        }
        order.setBankInfo(bankInfo.isBlank() ? null : bankInfo);
        order.setReturnRequestedAt(LocalDateTime.now());

        Order saved = orderRepository.save(order);
        log.info("Order {} submitted return request. Reason: {}", order.getOrderCode(), request.getReason());

        try {
            notificationService.createNotification(
                    user,
                    "Yêu cầu đổi trả đơn hàng #" + saved.getOrderCode(),
                    "TechStore đã tiếp nhận yêu cầu đổi trả của bạn. Chúng tôi sẽ xử lý và phản hồi trong vòng 24h.",
                    com.techstore.enums.NotificationType.ORDER,
                    saved.getId().toString()
            );
        } catch (Exception e) {
            log.warn("Failed to notify user for return request: {}", e.getMessage());
        }

        return OrderResponseDto.fromEntity(saved);
    }

    @Override
    @Transactional
    public OrderResponseDto processReturnDecision(Long orderId, com.techstore.dto.ReturnDecisionRequest request) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn hàng ID: " + orderId));

        if (order.getStatus() != OrderStatus.RETURN_REQUESTED) {
            throw new BadRequestException("Đơn hàng không ở trạng thái yêu cầu đổi trả.");
        }

        if (Boolean.TRUE.equals(request.getApprove())) {
            if (Boolean.TRUE.equals(request.getRefundDirectly())) {
                order.setStatus(OrderStatus.REFUNDED);
                order.setRefundedAt(LocalDateTime.now());
                restoreInventoryForOrder(order);
                handleCancellationPayment(order);
            } else {
                order.setStatus(OrderStatus.RETURN_APPROVED);
            }
        } else {
            order.setStatus(OrderStatus.RETURN_REJECTED);
            order.setReturnRejectReason(request.getRejectReason() != null ? request.getRejectReason() : "Không đáp ứng điều kiện đổi trả của cửa hàng.");
        }

        if (request.getNote() != null && !request.getNote().isBlank()) {
            order.setNotes(order.getNotes() != null ? order.getNotes() + " | " + request.getNote() : request.getNote());
        }

        Order saved = orderRepository.save(order);
        log.info("Order {} return decision processed. New status: {}", order.getOrderCode(), saved.getStatus());

        try {
            if (saved.getUser() != null) {
                String message = switch (saved.getStatus()) {
                    case RETURN_APPROVED -> "Yêu cầu đổi trả đơn hàng #" + saved.getOrderCode() + " đã được chấp thuận. Vui lòng đóng gói và chờ shipper thu hồi máy.";
                    case REFUNDED -> "Đơn hàng #" + saved.getOrderCode() + " đã được hoàn tiền thành công vào tài khoản ngân hàng của bạn.";
                    case RETURN_REJECTED -> "Yêu cầu đổi trả đơn hàng #" + saved.getOrderCode() + " đã bị từ chối. Lý do: " + saved.getReturnRejectReason();
                    default -> "Trạng thái đổi trả đơn hàng #" + saved.getOrderCode() + " đã được cập nhật.";
                };
                notificationService.createNotification(
                        saved.getUser(),
                        "Kết quả xử lý đổi trả #" + saved.getOrderCode(),
                        message,
                        com.techstore.enums.NotificationType.ORDER,
                        saved.getId().toString()
                );
            }
        } catch (Exception e) {
            log.warn("Failed to notify user for return decision: {}", e.getMessage());
        }

        return OrderResponseDto.fromEntity(saved);
    }

    @Override
    @Transactional
    public OrderResponseDto processRefund(Long orderId, String note) {
        Order order = orderRepository.findById(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đơn hàng ID: " + orderId));

        if (order.getStatus() != OrderStatus.RETURN_APPROVED && order.getStatus() != OrderStatus.RETURN_REQUESTED) {
            throw new BadRequestException("Chỉ đơn hàng đang đổi trả mới có thể xác nhận hoàn tiền.");
        }

        order.setStatus(OrderStatus.REFUNDED);
        order.setRefundedAt(LocalDateTime.now());
        if (note != null && !note.isBlank()) {
            order.setNotes(order.getNotes() != null ? order.getNotes() + " | " + note : note);
        }

        restoreInventoryForOrder(order);
        handleCancellationPayment(order);

        Order saved = orderRepository.save(order);
        log.info("Order {} confirmed refunded", order.getOrderCode());

        try {
            if (saved.getUser() != null) {
                notificationService.createNotification(
                        saved.getUser(),
                        "Đã hoàn tiền đơn hàng #" + saved.getOrderCode(),
                        "TechStore đã hoàn tiền đơn hàng #" + saved.getOrderCode() + " qua tài khoản ngân hàng của bạn.",
                        com.techstore.enums.NotificationType.ORDER,
                        saved.getId().toString()
                );
            }
        } catch (Exception e) {
            log.warn("Failed to notify user for refund: {}", e.getMessage());
        }

        return OrderResponseDto.fromEntity(saved);
    }

    private void restoreInventoryForOrder(Order order) {
        Long branchId = order.getBranch() != null ? order.getBranch().getId() : null;
        if (branchId == null) {
            log.warn("Cannot restore inventory for order {}: No branch associated", order.getOrderCode());
            return;
        }

        for (OrderItem item : order.getItems()) {
            Long productId = item.getProduct().getId();
            inventoryRepository.findByProductIdAndBranchIdWithLock(productId, branchId)
                    .ifPresent(inventory -> {
                        inventory.setQuantity(inventory.getQuantity() + item.getQuantity());
                        inventoryRepository.save(inventory);
                        log.info("Restored {} units of product {} to branch {} inventory. New quantity: {}",
                                item.getQuantity(), productId, branchId, inventory.getQuantity());
                    });
        }
    }

    private void handleCancellationPayment(Order order) {
        if (order.getPaymentStatus() == PaymentStatus.PAID) {
            order.setPaymentStatus(PaymentStatus.REFUNDED);
            if (order.getPayment() != null) {
                order.getPayment().setStatus(PaymentStatus.REFUNDED);
            }
        } else if (order.getPaymentStatus() == PaymentStatus.UNPAID) {
            order.setPaymentStatus(PaymentStatus.FAILED);
            if (order.getPayment() != null) {
                order.getPayment().setStatus(PaymentStatus.FAILED);
            }
        }
    }
}


