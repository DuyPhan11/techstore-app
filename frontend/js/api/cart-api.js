import { apiRequest } from "./api-client.js";

/**
 * Cart API Service for TechStore
 * Handles customer shopping cart actions
 */
export const CartApi = {
    /**
     * Get current user's cart
     */
    async getCart() {
        return apiRequest("/cart", {
            method: "GET"
        });
    },

    /**
     * Add product to cart
     */
    async addToCart(productId, quantity = 1) {
        return apiRequest("/cart/items", {
            method: "POST",
            body: {
                productId: Number(productId),
                quantity: Number(quantity)
            }
        });
    },

    /**
     * Update item quantity in cart
     */
    async updateQuantity(productId, quantity) {
        return apiRequest(`/cart/items/${productId}`, {
            method: "PUT",
            body: {
                quantity: Number(quantity)
            }
        });
    },

    /**
     * Remove item from cart
     */
    async removeItem(productId) {
        return apiRequest(`/cart/items/${productId}`, {
            method: "DELETE"
        });
    },

    /**
     * Clear all items in cart
     */
    async clearCart() {
        return apiRequest("/cart", {
            method: "DELETE"
        });
    }
};

/**
 * Helper to update cart badge in navbar across pages
 */
export async function updateCartBadge() {
    const badge = document.getElementById("cart-badge") || document.getElementById("cartCountBadge");
    if (!badge) return;

    const token = localStorage.getItem("techstore_token");
    if (!token) {
        badge.textContent = "0";
        badge.style.display = "none";
        return;
    }

    try {
        const res = await CartApi.getCart();
        const totalItems = res?.data?.totalItems || 0;
        badge.textContent = totalItems;
        badge.style.display = totalItems > 0 ? "inline-block" : "none";
    } catch {
        // If not logged in or error, hide badge
        badge.textContent = "0";
        badge.style.display = "none";
    }
}
