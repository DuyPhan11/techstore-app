import { registerApi } from "../../js/api/auth-api.js";
import { Auth } from "../../js/auth/auth.js";
import { Guard } from "../../js/auth/guard.js";

document.addEventListener("DOMContentLoaded", () => {
    Guard.requireGuest();

    const form = document.getElementById("register-form");
    const fullNameInput = document.getElementById("fullName");
    const emailInput = document.getElementById("email");
    const phoneInput = document.getElementById("phone");
    const passwordInput = document.getElementById("password");
    const confirmPasswordInput = document.getElementById("confirmPassword");
    const termsCheck = document.getElementById("terms");
    const btnRegister = document.getElementById("btn-register");
    const spinner = document.getElementById("register-spinner");
    const alertContainer = document.getElementById("alert-container");

    form.addEventListener("submit", async (e) => {
        e.preventDefault();
        alertContainer.innerHTML = "";
        clearFieldErrors();

        const fullName = fullNameInput.value.trim();
        const email = emailInput.value.trim();
        const phone = phoneInput.value.trim();
        const password = passwordInput.value;
        const confirmPassword = confirmPasswordInput.value;

        // Frontend validation
        let hasError = false;

        if (!fullName) {
            showFieldError(fullNameInput, "err-fullName", "Vui lòng nhập họ và tên.");
            hasError = true;
        }

        if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
            showFieldError(emailInput, "err-email", "Email không hợp lệ.");
            hasError = true;
        }

        if (!phone || !/^(0[3|5|7|8|9])([0-9]{8})$/.test(phone)) {
            showFieldError(phoneInput, "err-phone", "Số điện thoại không hợp lệ (10 chữ số, đầu 03, 05, 07, 08, 09).");
            hasError = true;
        }

        if (!password || password.length < 6) {
            showFieldError(passwordInput, "err-password", "Mật khẩu phải có tối thiểu 6 ký tự.");
            hasError = true;
        }

        if (password !== confirmPassword) {
            showFieldError(confirmPasswordInput, "err-confirmPassword", "Mật khẩu nhập lại không khớp.");
            hasError = true;
        }

        if (!termsCheck.checked) {
            showAlert("Vui lòng đồng ý với điều khoản sử dụng.", "warning");
            hasError = true;
        }

        if (hasError) return;

        try {
            setLoading(true);
            const response = await registerApi({ fullName, email, phone, password });

            if (response && response.success) {
                const { token, user } = response.data;
                Auth.setAuth(token, user);

                showAlert("Đăng ký thành công! Đang chuyển hướng...", "success");
                setTimeout(() => {
                    window.location.href = "../../index.html";
                }, 1200);
            } else {
                showAlert(response?.message || "Đăng ký không thành công.", "danger");
            }
        } catch (error) {
            if (error.data?.errors) {
                // Backend field validation errors
                Object.entries(error.data.errors).forEach(([field, msg]) => {
                    const input = document.getElementById(field);
                    const errEl = document.getElementById(`err-${field}`);
                    if (input && errEl) {
                        showFieldError(input, `err-${field}`, msg);
                    }
                });
            } else {
                showAlert(error.data?.message || error.message || "Lỗi khi đăng ký tài khoản.", "danger");
            }
        } finally {
            setLoading(false);
        }
    });

    function showFieldError(inputEl, errorElId, message) {
        inputEl.classList.add("is-invalid");
        const errorEl = document.getElementById(errorElId);
        if (errorEl) {
            errorEl.textContent = message;
            errorEl.style.display = "block";
        }
    }

    function clearFieldErrors() {
        document.querySelectorAll(".form-control").forEach(el => el.classList.remove("is-invalid"));
        document.querySelectorAll(".invalid-feedback").forEach(el => el.style.display = "none");
    }

    function showAlert(message, type = "danger") {
        alertContainer.innerHTML = `
            <div class="alert alert-${type} alert-dismissible fade show" role="alert">
                <i class="bi bi-info-circle-fill me-2"></i> ${message}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        `;
    }

    function setLoading(isLoading) {
        if (isLoading) {
            btnRegister.disabled = true;
            spinner.classList.remove("d-none");
        } else {
            btnRegister.disabled = false;
            spinner.classList.add("d-none");
        }
    }
});
