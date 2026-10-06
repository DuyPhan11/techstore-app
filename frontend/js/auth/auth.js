const TOKEN_KEY = "techstore_token";
const USER_KEY = "techstore_user";

export const Auth = {
    getToken() {
        return localStorage.getItem(TOKEN_KEY);
    },

    getUser() {
        try {
            const userJson = localStorage.getItem(USER_KEY);
            return userJson ? JSON.parse(userJson) : null;
        } catch (e) {
            console.error("Failed to parse user from localStorage", e);
            return null;
        }
    },

    setAuth(token, user) {
        if (token) localStorage.setItem(TOKEN_KEY, token);
        if (user) localStorage.setItem(USER_KEY, JSON.stringify(user));
    },

    clearAuth() {
        localStorage.removeItem(TOKEN_KEY);
        localStorage.removeItem(USER_KEY);
    },

    isAuthenticated() {
        try {
            const token = this.getToken();
            const payload = JSON.parse(atob(token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/')));
            if (!payload.exp || payload.exp * 1000 <= Date.now()) {
                this.clearAuth();
                return false;
            }
            return !!this.getUser();
        } catch {
            this.clearAuth();
            return false;
        }
    },

    hasRole(role) {
        const user = this.getUser();
        if (!user || !user.roles) return false;
        return user.roles.includes(role) || user.roles.includes(`ROLE_${role}`);
    },

    isAdmin() {
        return this.hasRole("ROLE_ADMIN") || this.hasRole("ADMIN");
    },

    isStaff() {
        return this.hasRole("ROLE_STAFF") || this.hasRole("STAFF") || this.isAdmin();
    },

    logout(redirectUrl = "/index.html") {
        this.clearAuth();
        window.location.href = redirectUrl;
    }
};

// Function-style API used by catalog, cart and checkout pages.
// Forward through Auth so methods retain their object context.
export const isAuthenticated = () => Auth.isAuthenticated();
export const isAdmin = () => Auth.isAdmin();
export const isStaff = () => Auth.isStaff();
export const getCurrentUser = () => Auth.getUser();
export const logout = (redirectUrl) => Auth.logout(redirectUrl);
