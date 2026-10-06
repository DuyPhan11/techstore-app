package com.techstore;

import com.techstore.dto.CheckoutRequest;
import com.techstore.entity.*;
import com.techstore.enums.*;
import com.techstore.exception.BadRequestException;
import com.techstore.repository.*;
import com.techstore.service.CheckoutService;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.*;
import static org.junit.jupiter.api.Assertions.*;

@SpringBootTest
@ActiveProfiles("test")
class CheckoutConcurrencyTest {
    @Autowired CheckoutService checkout;
    @Autowired UserRepository users;
    @Autowired CartRepository carts;
    @Autowired CartItemRepository items;
    @Autowired ProductRepository products;
    @Autowired InventoryRepository inventories;
    @Autowired CouponRepository coupons;
    @Autowired BranchRepository branches;
    @Autowired CategoryRepository categories;
    @Autowired BrandRepository brands;
    @Autowired PlatformTransactionManager transactions;
    @Autowired JdbcTemplate jdbc;

    @Test
    void simultaneousCheckoutsOfOneCartCreateOnlyOneOrder() throws Exception {
        exercise(false);
    }

    @Test
    void simultaneousCustomersCannotSpendLastCouponTwice() throws Exception {
        exercise(true);
    }

    private void exercise(boolean sharedCoupon) throws Exception {
        var tx = new TransactionTemplate(transactions);
        var fixtureUsers = new ArrayList<User>();
        var productIds = new ArrayList<Long>();
        String code = "RACE-" + UUID.randomUUID().toString().substring(0, 8);
        try {
            tx.executeWithoutResult(status -> {
                for (int i = 0; i < (sharedCoupon ? 2 : 1); i++) {
                    String suffix = UUID.randomUUID().toString();
                    User user = users.save(User.builder().email(suffix + "@example.invalid")
                            .phone("09" + String.format("%08d", Math.floorMod(UUID.randomUUID().getLeastSignificantBits(), 100000000L)))
                            .fullName("Concurrency fixture").password("test-only").status(UserStatus.ACTIVE).build());
                    fixtureUsers.add(user);
                    Product product = products.save(Product.builder().name("Concurrency fixture").sku(suffix)
                            .slug(suffix).price(BigDecimal.valueOf(100000)).costPrice(BigDecimal.valueOf(50000))
                            .category(categories.findById(1L).orElseThrow()).brand(brands.findById(1L).orElseThrow()).build());
                    productIds.add(product.getId());
                    inventories.save(Inventory.builder().product(product).branch(branches.findById(1L).orElseThrow())
                            .quantity(10).minStockAlert(1).build());
                    Cart cart = carts.save(Cart.builder().user(user).build());
                    items.save(CartItem.builder().cart(cart).product(product).quantity(1).build());
                }
                if (sharedCoupon) coupons.save(Coupon.builder().code(code).discountType(DiscountType.FIXED_AMOUNT)
                        .discountValue(BigDecimal.valueOf(1000)).minOrderAmount(BigDecimal.ZERO).usageLimit(1)
                        .usedCount(0).isActive(true).startDate(LocalDateTime.now().minusDays(1))
                        .endDate(LocalDateTime.now().plusDays(1)).build());
            });
            ExecutorService executor = Executors.newFixedThreadPool(2);
            try {
                var ready = new CountDownLatch(2);
                var start = new CountDownLatch(1);
                var futures = new ArrayList<Future<Boolean>>();
                for (int i = 0; i < 2; i++) {
                    User user = fixtureUsers.get(sharedCoupon ? i : 0);
                    futures.add(executor.submit(() -> {
                        ready.countDown();
                        if (!start.await(5, TimeUnit.SECONDS)) throw new IllegalStateException("Start timed out");
                        try {
                            checkout.checkout(user, CheckoutRequest.builder().recipientName("Fixture")
                                    .recipientPhone("0912345678").shippingAddress("Fixture address").branchId(1L)
                                    .paymentMethod(PaymentMethod.COD).couponCode(sharedCoupon ? code : null).build());
                            return true;
                        } catch (BadRequestException expected) { return false; }
                    }));
                }
                assertTrue(ready.await(5, TimeUnit.SECONDS));
                start.countDown();
                int successes = 0;
                for (var future : futures) if (future.get(20, TimeUnit.SECONDS)) successes++;
                assertEquals(1, successes);
            } finally {
                executor.shutdown();
            }
            tx.executeWithoutResult(status -> {
                int remaining = productIds.stream().mapToInt(id -> inventories.findByProductIdAndBranchId(id, 1L).orElseThrow().getQuantity()).sum();
                assertEquals(productIds.size() * 10 - 1, remaining);
                int orders = fixtureUsers.stream().mapToInt(user -> jdbc.queryForObject("select count(*) from orders where user_id = ?", Integer.class, user.getId())).sum();
                assertEquals(1, orders);
                if (sharedCoupon) {
                    assertEquals(1, coupons.findByCode(code).orElseThrow().getUsedCount());
                    assertEquals(1, jdbc.queryForObject("select count(*) from coupon_usages cu join coupons c on c.id=cu.coupon_id where c.code=?", Integer.class, code));
                }
            });
        } finally {
            tx.executeWithoutResult(status -> {
                for (User user : fixtureUsers) {
                    jdbc.update("delete from coupon_usages where user_id=?", user.getId());
                    jdbc.update("delete p from payments p join orders o on o.id=p.order_id where o.user_id=?", user.getId());
                    jdbc.update("delete i from order_items i join orders o on o.id=i.order_id where o.user_id=?", user.getId());
                    jdbc.update("delete from orders where user_id=?", user.getId());
                    jdbc.update("delete i from cart_items i join carts c on c.id=i.cart_id where c.user_id=?", user.getId());
                    jdbc.update("delete from carts where user_id=?", user.getId());
                    jdbc.update("delete from users where id=?", user.getId());
                }
                for (Long id : productIds) {
                    jdbc.update("delete from inventories where product_id=?", id);
                    jdbc.update("delete from products where id=?", id);
                }
                jdbc.update("delete from coupons where code=?", code);
            });
        }
    }
}
