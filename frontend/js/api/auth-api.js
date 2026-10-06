import { apiRequest } from "./api-client.js";

export function registerApi(userData) {
    return apiRequest("/auth/register", {
        method: "POST",
        body: userData
    });
}

export function loginApi(credentials) {
    return apiRequest("/auth/login", {
        method: "POST",
        body: credentials
    });
}

export function forgotPasswordApi(email) {
    return apiRequest("/auth/forgot-password", {
        method: "POST",
        body: { email }
    });
}

export function resetPasswordApi(resetData) {
    return apiRequest("/auth/reset-password", {
        method: "POST",
        body: resetData
    });
}

export function getMeApi() {
    return apiRequest("/auth/me", {
        method: "GET"
    });
}
