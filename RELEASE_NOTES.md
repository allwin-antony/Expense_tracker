# 🚀 Release `v2.0.1` — Native 7-Layer Background Defense, Adaptive `AppToast` & Performance Fixes

We are excited to announce **Release `v2.0.1`**! This update brings full native Kotlin background filtering parity, an all-new theme-adaptive floating toast notification engine, silent UI refresh optimizations, and enhanced financial SMS security.

---

## 🌟 What's New in `v2.0.1`

### 🛡️ 1. Native 7-Layer Background SMS Defense Shield (`SmsReceiver.kt`)
* **1:1 Regex Parity**: Upgraded the native Android Kotlin background receiver with full regex pipeline parity matching Dart's `MessageParserPipeline`.
* **Zero Ghost Notifications**: Background system notifications now run 7-stage verification before triggering alerts:
  1. **Foreground Suppression**: Automatically suppresses system bar alerts while the app is actively open.
  2. **OTP & Auth Filter**: Instantly rejects passcodes, OTPs, and security login codes.
  3. **Promotional Filter**: Blocks loan offers, credit card application ads, EMI checks, and cashback spam.
  4. **Anti-Scam Shield**: Rejects phishing links, fake lottery wins, KYC block threats, and APK malware.
  5. **Debit/Credit Intent Matcher**: Requires explicit transaction verbs (`debited`, `credited`, `spent`, `transferred`, `paid to`).
  6. **Amount Matcher**: Strictly requires valid currency symbols (`Rs.`, `INR`, `₹`, `$`, `£`, `€`) with numerical values.
  7. **URL Safety Verification**: Blocks messages containing web links unless accompanied by an authentic bank name, account number, or UTR reference ID.

---

### 🍞 2. Adaptive Floating `AppToast` Notification Engine
* **Theme-Adaptive Styling**: Custom floating overlay designed for both **Light Mode** (Crisp White `#FFFFFF` card with Dark Slate `#0F172A` text) and **Dark Mode** (Dark Slate `#0F172A` card with Crisp White `#FFFFFF` text).
* **Guaranteed Auto-Dismissal**: Uses an independent Dart `Timer` to guarantee automatic 3-second fade-outs, eliminating Flutter `SnackBar` animation freezes.
* **Interactive `UNDO` Button**: Instant tap action to revert transaction deletions or budget exclusion changes.

---

### ⚡ 3. Silent UI Refresh Optimizations
* **No Shimmer Flashing**: Toggling payment inclusion/exclusion or editing transactions updates the dashboard and history lists silently in-place without triggering shimmer loading skeletons.
* **Scroll Offset Preservation**: Maintains pagination count during silent reloads so scrolling positions remain completely stable.

---

### 👁️ 4. Public Privacy Mode & Multi-Currency Processing
* **1-Tap Privacy Toggle**: Obscure summary balance figures (`+₹ ••••••` / `-₹ ••••••`) across Home, Statistics, and History screens.
* **Multi-Currency Engine**: Full parsing support for **USD ($)**, **GBP (£)**, and **EUR (€)** international subscriptions and travel expenses alongside Indian **INR (₹)**.

---

## 🛠️ Technical Improvements & Build Specs

* **Engine**: Flutter SDK `^3.8.1` & Kotlin 2.2.20
* **Test Coverage**: 100% passing test suite (**198/198 unit tests passed**)
* **Static Analysis**: Clean build with **0 analyzer issues**
* **ML Model**: Quantized pure-Dart FastText (`171.5 KB`, `< 0.3ms` latency)
* **Build Artifacts**:
  - `app-arm64-v8a-release.apk` (ARM 64-bit, 20.0 MB)
  - `app-armeabi-v7a-release.apk` (ARM 32-bit, 17.6 MB)
  - `app-x86_64-release.apk` (x86 64-bit, 21.4 MB)
  - `app-release.apk` (Universal Release, 55.3 MB)
  - `app-release.aab` (Google Play App Bundle, 53.9 MB)
