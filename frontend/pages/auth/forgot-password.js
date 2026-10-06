import { forgotPasswordApi, resetPasswordApi } from "../../js/api/auth-api.js";

document.addEventListener("DOMContentLoaded", () => {
    const forgotForm = document.getElementById("forgot-form");
    const resetForm = document.getElementById("reset-form");
    const emailInput = document.getElementById("email");
    const tokenInput = document.getElementById("token");
    const newPasswordInput = document.getElementById("newPassword");
    const btnRequestToken = document.getElementById("btn-request-token");
    const btnResetPassword = document.getElementById("btn-reset-password");
    const forgotSpinner = document.getElementById("forgot-spinner");
    const resetSpinner = document.getElementById("reset-spinner");
    const alertContainer = document.getElementById("alert-container");

    const resetToken = new URLSearchParams(location.hash.slice(1)).get('token');
    if (resetToken) {
        tokenInput.value = resetToken;
        resetForm.classList.remove('d-none');
        forgotForm.classList.add('d-none');
        history.replaceState(null, '', location.pathname);
    }

    // Step 1: Request email
    forgotForm.addEventListener("submit", async (e) => {
        e.preventDefault();
        alertContainer.innerHTML = "";

        const email = emailInput.value.trim();
        if (!email) return;

        try {
            btnRequestToken.disabled = true;
            forgotSpinner.classList.remove("d-none");

            const response = await forgotPasswordApi(email);

            if (response && response.success) {
                showAlert(response.message, "success");
            } else {
                showAlert(response?.message || "Không thể gửi yêu cầu.", "danger");
            }
        } catch (error) {
            showAlert(error.data?.message || error.message || "Lỗi khi xử lý yêu cầu.", "danger");
        } finally {
            btnRequestToken.disabled = false;
            forgotSpinner.classList.add("d-none");
        }
    });

    // Step 2: Reset password
    resetForm.addEventListener("submit", async (e) => {
        e.preventDefault();
        alertContainer.innerHTML = "";

        const token = tokenInput.value.trim();
        const newPassword = newPasswordInput.value;

        if (!token || !newPassword || newPassword.length < 6) {
            showAlert("Vui lòng nhập token và mật khẩu mới tối thiểu 6 ký tự.", "danger");
            return;
        }

        try {
            btnResetPassword.disabled = true;
            resetSpinner.classList.remove("d-none");

            const response = await resetPasswordApi({ token, newPassword });

            if (response && response.success) {
                showAlert("Đổi mật khẩu thành công! Chuyển hướng về trang đăng nhập...", "success");
                setTimeout(() => {
                    window.location.href = "./login.html";
                }, 1500);
            } else {
                showAlert(response?.message || "Không thể đặt lại mật khẩu.", "danger");
            }
        } catch (error) {
            showAlert(error.data?.message || error.message || "Mã xác thực không hợp lệ hoặc đã hết hạn.", "danger");
        } finally {
            btnResetPassword.disabled = false;
            resetSpinner.classList.add("d-none");
        }
    });

    function showAlert(message, type = "danger") {
        alertContainer.innerHTML = `
            <div class="alert alert-${type} alert-dismissible fade show" role="alert">
                ${escapeHtml(message)}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        `;
    }
});

function escapeHtml(value) { const el = document.createElement("span"); el.textContent = value; return el.innerHTML; }
