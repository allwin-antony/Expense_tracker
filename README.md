# 💸 Expense Tracker – Smart Automated Budget & SMS Expense Manager for Android

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Platform](https://img.shields.io/badge/platform-Android-blue)
![Built with Flutter](https://img.shields.io/badge/built%20with-Flutter-blueviolet)
![Database](https://img.shields.io/badge/database-SQLite-green)
![Privacy](https://img.shields.io/badge/privacy-100%25%20Offline-brightgreen)

**Expense Tracker** is a powerful, offline-first personal finance and budget tracking app built with **Flutter**. It automatically captures, parses, and categorizes bank SMS transactions in real-time — even when the app is completely closed — while keeping 100% of your financial data strictly private on your phone.

> 🔒 **100% Private & Offline**: No cloud servers, no trackers, no accounts required. All data is saved in your local SQLite database.

---

## ✨ Key Features

### 📩 Automated Bank SMS Parser Pipeline
- **Real-time SMS Capturing**: Automatically parses incoming bank SMS messages for UPI, Debit Cards, Credit Cards, NetBanking, and ATM transactions.
- **Smart Regex Engine**: Detects merchants (e.g., Swiggy, Amazon, Uber, Zomato), transaction type (*Debit/Credit*), amount, payment mode, and account last 4 digits.
- **Isolate Offloading**: SMS parsing runs in background Dart Isolates (`compute()`), ensuring **zero frame drops or UI lag** even when processing thousands of messages.

### 🔔 Background SMS Notifications & Action Buttons
- **Closed-App Detection**: Listens for incoming bank SMS via a lightweight native Android `BroadcastReceiver` (`SmsReceiver.kt`), waking up only when a financial SMS arrives.
- **Interactive Notifications**: Shows a high-priority heads-up banner with a **"View & Sync Expense"** action button.
- **Instant Auto-Sync**: Tapping the notification launches the app and immediately syncs the transaction into your database list.

### ⚡ Atomic Batch Sync & Deduplication
- **Custom Sync Ranges**: Sync your inbox by *This Month*, *Last 30 Days*, *Last 90 Days*, *This Year*, *All Time*, or a *Custom Date Range*.
- **Atomic SQLite Batching**: Uses `db.batch()` for 100x faster execution and **zero UI flickering**.
- **Smart Deduplication**: Prevents duplicate entries using exact message hash matching and time/amount proximity checks.

### 📅 Advanced Budgeting & Custom Month Shifting
- **Shift Budget Month**: Assign transactions to different budget months (e.g., a salary received on August 31st can be assigned to September's budget).
- **Batch Date Group Controls**: Bulk exclude or include transactions from budget calculations directly from date headers.
- **Exclude Non-Expenses**: Mark internal transfers or self-withdrawals as excluded to keep your budget metrics accurate.

### 📊 Analytics & Interactive Visualizations
- **Category Breakdown**: Interactive pie charts powered by `fl_chart`.
- **Monthly Spending Trends**: Income vs. Expense tracking, total monthly balance, and daily spending averages.
- **Filtered History View**: Search and filter transactions by category, payment mode, transaction type, or month.

### 🖐️ Micro-Animations & Gesture Controls
- **Accidental-Swipe Protection**: Configured with a 75% drag threshold on transaction cards to prevent accidental editing or deletion while scrolling.
- **Haptic Feedback**: Subtle physical feedback for smooth user interaction.

---

## 🛠️ Technology Stack

* **Framework**: Flutter (Channel stable, v3.47+)
* **Language**: Dart 3.13 / Kotlin 2.2+
* **Database**: SQLite via `sqflite`
* **Parsing Engine**: Custom RegEx Pipeline running in Dart Isolates
* **Android Architecture**: Android 16 (API 36), AGP 8.11.1, Gradle 9.1.0, Java 25 compatibility
* **Permissions**: `RECEIVE_SMS`, `READ_SMS`, `POST_NOTIFICATIONS`

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (v3.24 or higher)
- Android Studio with Android SDK Platform-Tools (API 34+)
- An Android physical device (recommended for testing SMS broadcast triggers) or Emulator

### Installation & Run

1. Clone the repository:
   ```bash
   git clone https://github.com/allwin-antony/Expense_tracker.git
   cd Expense_tracker
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run on your connected Android device:
   ```bash
   flutter run
   ```

---

## 📱 Android Permissions & Battery Optimizations

To ensure background SMS notifications work when the app is closed:

1. **Grant SMS & Notification Permissions**: Allow **SMS** and **Notification** permissions when prompted on first launch.
2. **Auto-start / Background Activity** *(for Xiaomi, Realme, Vivo, Oppo, Samsung)*:
   * Go to **Settings > Apps > Expense Tracker**.
   * Enable **Autostart** / **Allow background activity**.
   * Set Battery Saver setting to **Unrestricted / No Restrictions**.

---

## 🔒 Privacy Guarantee

Expense Tracker does **NOT** upload your messages, financial figures, or personal data to any external server. All processing happens 100% locally on your device.

---

## 📄 License

Distributed under the MIT License. See `LICENSE.md` for details.