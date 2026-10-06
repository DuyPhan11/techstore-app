import { loginApi } from "../../js/api/auth-api.js";
import { Auth } from "../../js/auth/auth.js";
import { Guard } from "../../js/auth/guard.js";

document.addEventListener("DOMContentLoaded", () => {
    // If already logged in, redirect to home
    Guard.requireGuest();

    const form = document.getElementById("login-form");
    const usernameInput = document.getElementById("username");
    const passwordInput = document.getElementById("password");
    const togglePasswordBtn = document.getElementById("toggle-password");
    const btnLogin = document.getElementById("btn-login");
    const spinner = document.getElementById("login-spinner");
    const alertContainer = document.getElementById("alert-container");

    // Toggle password visibility
    togglePasswordBtn?.addEventListener("click", () => {
        const type = passwordInput.getAttribute("type") === "password" ? "text" : "password";
        passwordInput.setAttribute("type", type);
        togglePasswordBtn.innerHTML = type === "password" ? '<i class="bi bi-eye"></i>' : '<i class="bi bi-eye-slash"></i>';
    });

    form.addEventListener("submit", async (e) => {
        e.preventDefault();
        alertContainer.innerHTML = "";

        const username = usernameInput.value.trim();
        const password = passwordInput.value;

        if (!username || !password) {
            showAlert("Vui lòng điền đầy đủ tài khoản và mật khẩu.", "danger");
            return;
        }

        try {
            setLoading(true);
            const response = await loginApi({ username, password });

            if (response && response.success) {
                const { token, user } = response.data;
                Auth.setAuth(token, user);

                showAlert("Đăng nhập thành công! Đang chuyển hướng...", "success");

                // Check query params for redirect
                const urlParams = new URLSearchParams(window.location.search);
                const redirect = urlParams.get("redirect");

                setTimeout(() => {
                    if (redirect && redirect.startsWith("/") && !redirect.startsWith("//") && !redirect.includes("\\")) {
                        window.location.href = redirect;
                    } else if (Auth.isAdmin() || Auth.isStaff()) {
                        window.location.href = "../admin/admin.html";
                    } else {
                        window.location.href = "../../index.html";
                    }
                }, 1000);
            } else {
                showAlert(response?.message || "Đăng nhập thất bại.", "danger");
            }
        } catch (error) {
            showAlert(error.data?.message || error.message || "Tài khoản hoặc mật khẩu không chính xác.", "danger");
        } finally {
            setLoading(false);
        }
    });

    function showAlert(message, type = "danger") {
        alertContainer.innerHTML = `
            <div class="alert alert-${type} alert-dismissible fade show" role="alert">
                <i class="bi bi-exclamation-triangle-fill me-2"></i> ${message}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        `;
    }

    function setLoading(isLoading) {
        if (isLoading) {
            btnLogin.disabled = true;
            spinner.classList.remove("d-none");
        } else {
            btnLogin.disabled = false;
            spinner.classList.add("d-none");
        }
    }
});
