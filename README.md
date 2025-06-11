# 🛒 WinSport - Razorpay Payment Integration

This Flutter project demonstrates **UPI app link-based payments** using **Razorpay**. The app allows users to initiate payments directly via the Razorpay interface and handles success/failure callbacks seamlessly.

---

## 🚀 Features

- ✅ Razorpay payment via App Link
- 🔐 Secure UPI redirection
- 📲 Mobile-optimized experience
- 📷 Screenshot documentation
- 🧾 Transaction success and error handling

---

## 📸 Screenshots

| Home Screen | Razorpay Payment Page | Payment Success |
|-------------|------------------------|------------------|
| ![Home](assets/screenshots/login.jpg) | ![dashboard](assets/screenshots/dashboardd.jpg) | ![product](assets/screenshots/product-detail.jpg) || ![cart](assets/screenshots/cart.jpg) | ![payment](assets/screenshots/payment.jpg)

---

## 💳 How Payments Work

1. User taps **"Pay with Razorpay"**
2. App opens Razorpay UPI app or fallback browser-based payment
3. On success/failure, user is redirected back
4. Result is shown in-app

---

## 🧩 Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  razorpay_flutter: ^1.3.5
  url_launcher: ^6.1.10
