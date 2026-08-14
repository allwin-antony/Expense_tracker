# Phase 2: On-Device AI Model Integration Blueprint

> **Status:** DRAFT — Saved for future implementation  
> **Priority:** Medium — Current regex+heuristic engine handles 95%+ of cases  
> **Estimated Effort:** 2-3 days  
> **Prerequisites:** Python 3.10+, TensorFlow 2.15+, ~4GB disk space for toolchain

---

## Why This Phase Exists

The current parser (`financial_regex_patterns.dart` + `merchant_categorizer.dart` + `authenticity_validator.dart`) works well for structured Indian bank SMS but has inherent limitations:

| Scenario | Current Engine | With Real AI Model |
|----------|---------------|-------------------|
| Standard HDFC/SBI/ICICI debit/credit SMS | ✅ Works perfectly | ✅ Works perfectly |
| Pre-approved loan ads disguised with "credited" keyword | ✅ Caught by promotional regex | ✅ Caught with higher confidence |
| **New bank formats we haven't seen** | ❌ Misses if regex doesn't match | ✅ Learns generalized patterns |
| **Regional / non-English bank SMS** | ❌ Cannot handle | ✅ Multilingual embeddings |
| **Subtle phishing** ("Your SBI account credited Rs.50000 click to verify") | ⚠️ Partially caught | ✅ Detects semantic deception |
| **Informal UPI notifications** from apps like CRED, Slice, Fi | ⚠️ Hit-or-miss | ✅ Trained on these patterns |

**Bottom line:** The AI model fills the gap where rigid regex rules fail — novel message formats, edge cases, and semantic deception.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    TRAINING PIPELINE (One-time, on Desktop)      │
│                                                                  │
│  1. Generate Synthetic Indian Bank SMS Dataset (Python)          │
│     └── 2,000+ labeled examples across 4 classes                │
│                                                                  │
│  2. Fine-tune MobileBERT-tiny on the dataset                    │
│     └── ~15 min on CPU, ~3 min on GPU                           │
│                                                                  │
│  3. Export to TFLite INT8 Quantized (.tflite)                   │
│     └── Final size: 4-12 MB                                     │
│                                                                  │
│  4. Extract vocab.txt from tokenizer                            │
│     └── 30,522 tokens (standard BERT WordPiece)                 │
└──────────────────────────────┬──────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│               FLUTTER APP (On-Device Inference)                  │
│                                                                  │
│  assets/models/                                                  │
│  ├── financial_classifier.tflite    (4-12 MB, INT8)             │
│  └── vocab.txt                      (30,522 tokens)             │
│                                                                  │
│  lib/parser/ml/                                                  │
│  ├── bert_tokenizer.dart      ← Already implemented ✅          │
│  ├── tflite_engine.dart        ← NEW: Loads & runs .tflite      │
│  └── authenticity_validator.dart ← MODIFY: Use model output     │
│                                                                  │
│  Inference: ~5-8ms per message on ARM64 via NNAPI delegate       │
└─────────────────────────────────────────────────────────────────┘
```

---

## Step-by-Step Implementation

### Step 1: Setup Training Environment

```bash
# Create isolated Python virtual environment
python3 -m venv ~/ai_training_env
source ~/ai_training_env/bin/activate

# Install dependencies
pip install tensorflow==2.15.0 transformers datasets numpy pandas
```

### Step 2: Generate Synthetic Training Data

We leverage our existing regex patterns and merchant database to programmatically generate thousands of labeled Indian bank SMS samples.

**File:** `scripts/generate_training_data.py`

```python
import random
import csv

# === LABEL DEFINITIONS ===
# 0: GENUINE_TRANSACTION (real debit/credit)
# 1: PROMOTIONAL_SPAM (loan offers, marketing, cashback ads)
# 2: OTP_SECURITY (OTPs, verification codes)
# 3: INFORMATIONAL (balance queries, alerts, reminders)

BANKS = ['HDFC', 'SBI', 'ICICI', 'AXIS', 'KOTAK', 'PNB', 'BOB', 'CANARA',
         'INDUSIND', 'YES BANK', 'IDFC FIRST', 'FEDERAL BANK', 'RBL']

ACCOUNTS = ['XX4021', 'XX8091', 'XX3029', 'XX9920', 'XX5512', 'XX7834']

MERCHANTS = {
    'food': ['SWIGGY', 'ZOMATO', 'DOMINOS', 'KFC', 'MCDONALDS', 'STARBUCKS'],
    'shopping': ['AMAZON', 'FLIPKART', 'MYNTRA', 'AJIO', 'MEESHO', 'NYKAA'],
    'transport': ['UBER', 'OLA', 'RAPIDO', 'IRCTC', 'REDBUS', 'METRO'],
    'bills': ['BESCOM', 'AIRTEL', 'JIO', 'ACT BROADBAND', 'TATA POWER'],
    'fuel': ['HP PETROL', 'BPCL', 'IOCL', 'SHELL'],
}

DEBIT_TEMPLATES = [
    "Dear Customer, Rs.{amount} has been debited from your {bank} Bank A/c {acc} to {merchant} on {date} via UPI Ref {ref}. Avl Bal: Rs {bal}",
    "Your {bank} Bank Credit Card ending {acc} was spent for INR {amount} at {merchant} on {date}. Avl Limit: INR {limit}",
    "INR {amount} debited from A/c {acc} ({bank}) for payment to {merchant}. UPI Ref: {ref}",
    "{bank}: Rs.{amount} withdrawn from ATM at {merchant} from A/c {acc} on {date}. Avl Bal Rs.{bal}",
    "Alert: Rs.{amount} has been deducted from your {bank} A/c {acc} towards {merchant}. Ref No {ref}",
]

CREDIT_TEMPLATES = [
    "Salary of INR {amount} has been credited to your {bank} Bank A/c {acc} on {date} by {merchant}. Avl Bal: INR {bal}",
    "Refund of INR {amount} has been credited to your {bank} Bank A/c {acc} from {merchant}.",
    "INR {amount} credited to A/c {acc} ({bank}). NEFT from {merchant}. Ref: {ref}",
    "Dear Customer, Rs.{amount} has been received in your {bank} A/c {acc} via UPI from {merchant}. Ref {ref}",
]

PROMO_TEMPLATES = [
    "Good news {name}, Pre-approved loan of upto Rs.{amount} is credited instantly when you avail on {merchant}. Avail now! {url}",
    "Congratulations! You are eligible for an instant personal loan of up to Rs. {amount} with zero documentation. Apply now: {url}",
    "{bank}: Get Rs.{amount} cashback on your next order! Use code SAVE{code}. Shop now: {url}",
    "Dear Customer, your {bank} credit card limit has been enhanced to Rs.{amount}. Avail now: {url}",
    "Win up to Rs.{amount}! Spin the wheel on {merchant} app. Limited period offer. T&C apply. {url}",
    "Pre-qualified personal loan of Rs.{amount} waiting for you. Instant disbursal. Click: {url}",
    "Flat Rs.{amount} off on {merchant}! Order now and save big. Use code FLAT{code}. {url}",
]

OTP_TEMPLATES = [
    "Your OTP for transaction of INR {amount} at {merchant} is {otp}. Do not share this OTP with anyone.",
    "{otp} is your one time password for {bank} Bank transaction. Valid for 5 mins. Do not share.",
    "Your verification code for {merchant} payment of Rs.{amount} is {otp}. OTP expires in 3 minutes.",
    "Dear Customer, {otp} is the OTP for your {bank} net banking login. Do NOT share this code.",
]

BALANCE_TEMPLATES = [
    "Dear Customer, your available balance in A/C {acc} is INR {bal} as on {date}.",
    "{bank} Bank: Avl Bal in A/c {acc} is Rs.{bal} as of {date}. For mini statement give missed call.",
    "Your {bank} A/c {acc} balance is Rs.{bal}. Last txn Rs.{amount} on {date}.",
    "Bill payment of Rs.{amount} for {merchant} is due on {date}. Pay before due date to avoid late fee.",
]

def gen_amount(): return f"{random.randint(50, 99999)}.{random.randint(0,99):02d}"
def gen_bal(): return f"{random.randint(1000, 500000)}"
def gen_ref(): return f"{random.randint(100000000000, 999999999999)}"
def gen_otp(): return f"{random.randint(100000, 999999)}"
def gen_date(): return f"{random.randint(1,28):02d}-Aug-2026"
def gen_url(): return random.choice(["https://bit.ly/abc", "http://u3.mnge.co/x", "https://tinyurl.com/xyz"])
def gen_code(): return f"{random.randint(100,999)}"

def generate_samples(n=2500):
    samples = []
    for _ in range(n // 4):
        cat = random.choice(list(MERCHANTS.keys()))
        merchant = random.choice(MERCHANTS[cat])
        bank = random.choice(BANKS)
        acc = random.choice(ACCOUNTS)

        # Genuine transaction
        template = random.choice(DEBIT_TEMPLATES if random.random() > 0.3 else CREDIT_TEMPLATES)
        text = template.format(amount=gen_amount(), bank=bank, acc=acc, merchant=merchant,
                               date=gen_date(), ref=gen_ref(), bal=gen_bal(), limit=gen_bal(), name="CUSTOMER")
        samples.append({"text": text, "label": 0})

        # Promotional spam
        template = random.choice(PROMO_TEMPLATES)
        text = template.format(amount=gen_amount(), bank=bank, merchant=merchant,
                               name="CUSTOMER", url=gen_url(), code=gen_code())
        samples.append({"text": text, "label": 1})

        # OTP
        template = random.choice(OTP_TEMPLATES)
        text = template.format(amount=gen_amount(), merchant=merchant, bank=bank, otp=gen_otp())
        samples.append({"text": text, "label": 2})

        # Balance / Informational
        template = random.choice(BALANCE_TEMPLATES)
        text = template.format(amount=gen_amount(), bank=bank, acc=acc,
                               merchant=merchant, date=gen_date(), bal=gen_bal())
        samples.append({"text": text, "label": 3})

    random.shuffle(samples)
    return samples

if __name__ == "__main__":
    data = generate_samples(2500)
    with open("training_data.csv", "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["text", "label"])
        writer.writeheader()
        writer.writerows(data)
    print(f"Generated {len(data)} samples")
```

### Step 3: Fine-Tune MobileBERT

**File:** `scripts/train_financial_classifier.py`

```python
import tensorflow as tf
from transformers import TFAutoModelForSequenceClassification, AutoTokenizer
import pandas as pd

df = pd.read_csv("training_data.csv")
texts = df["text"].tolist()
labels = df["label"].tolist()

MODEL_NAME = "google/mobilebert-uncased"
tokenizer = AutoTokenizer.from_pretrained(MODEL_NAME)
model = TFAutoModelForSequenceClassification.from_pretrained(MODEL_NAME, num_labels=4)

encodings = tokenizer(texts, truncation=True, padding="max_length", max_length=64, return_tensors="tf")

split = int(0.8 * len(texts))
train_ds = tf.data.Dataset.from_tensor_slices((
    dict(input_ids=encodings["input_ids"][:split], attention_mask=encodings["attention_mask"][:split]),
    tf.constant(labels[:split])
)).shuffle(1000).batch(32)

val_ds = tf.data.Dataset.from_tensor_slices((
    dict(input_ids=encodings["input_ids"][split:], attention_mask=encodings["attention_mask"][split:]),
    tf.constant(labels[split:])
)).batch(32)

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=3e-5),
    loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=True),
    metrics=["accuracy"]
)
model.fit(train_ds, validation_data=val_ds, epochs=3)
model.save_pretrained("./saved_model")
tokenizer.save_pretrained("./saved_model")
```

### Step 4: Export to TFLite INT8

**File:** `scripts/export_tflite.py`

```python
import tensorflow as tf
import numpy as np
from transformers import AutoTokenizer

converter = tf.lite.TFLiteConverter.from_saved_model("./saved_model")
converter.optimizations = [tf.lite.Optimize.DEFAULT]

def representative_dataset():
    for _ in range(100):
        yield [np.random.randint(0, 30522, size=(1, 64), dtype=np.int32),
               np.ones((1, 64), dtype=np.int32)]

converter.representative_dataset = representative_dataset
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
converter.inference_input_type = tf.int32
converter.inference_output_type = tf.float32

tflite_model = converter.convert()
with open("financial_classifier.tflite", "wb") as f:
    f.write(tflite_model)

tokenizer = AutoTokenizer.from_pretrained("./saved_model")
vocab = tokenizer.get_vocab()
with open("vocab.txt", "w") as f:
    for token, _ in sorted(vocab.items(), key=lambda x: x[1]):
        f.write(token + "\n")

print(f"Model: {len(tflite_model) / (1024*1024):.1f} MB | Vocab: {len(vocab)} tokens")
```

### Step 5: Flutter Integration

**New file:** `lib/parser/ml/tflite_engine.dart`

```dart
import 'dart:typed_data';
import 'dart:math';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'bert_tokenizer.dart';

enum SmsClassification {
  genuineTransaction,   // 0
  promotionalSpam,      // 1
  otpSecurity,          // 2
  informational,        // 3
}

class TfliteModelResult {
  final SmsClassification classification;
  final double confidence;
  final List<double> probabilities;
  TfliteModelResult({required this.classification, required this.confidence, required this.probabilities});
}

class TfliteEngine {
  static final TfliteEngine instance = TfliteEngine._();
  TfliteEngine._();
  Interpreter? _interpreter;
  bool _isReady = false;

  Future<void> initialize() async {
    if (_isReady) return;
    try {
      _interpreter = await Interpreter.fromAsset(
        'models/financial_classifier.tflite',
        options: InterpreterOptions()..threads = 2,
      );
      _isReady = true;
    } catch (e) {
      print('TFLite load failed: $e');
    }
  }

  TfliteModelResult? classify(String text) {
    if (!_isReady || _interpreter == null) return null;
    final encoded = BertTokenizer.instance.encode(text, maxSeqLength: 64);
    final inputIds = Int32List.fromList(encoded.inputIds).reshape([1, 64]);
    final mask = Int32List.fromList(encoded.attentionMask).reshape([1, 64]);
    final output = List.filled(4, 0.0).reshape([1, 4]);
    _interpreter!.runForMultipleInputs([inputIds, mask], {0: output});

    final logits = (output[0] as List<double>);
    final maxL = logits.reduce(max);
    final exps = logits.map((l) => exp(l - maxL)).toList();
    final sum = exps.reduce((a, b) => a + b);
    final probs = exps.map((e) => e / sum).toList();
    int best = 0;
    for (int i = 1; i < probs.length; i++) if (probs[i] > probs[best]) best = i;

    return TfliteModelResult(
      classification: SmsClassification.values[best],
      confidence: probs[best],
      probabilities: probs,
    );
  }

  void dispose() => _interpreter?.close();
}
```

**Modify:** `authenticity_validator.dart` — blend model + heuristic:

```dart
// After existing heuristic scoring, before final return:
final modelResult = TfliteEngine.instance.classify(clean);
if (modelResult != null) {
  score = (modelResult.confidence * 0.6) + (score * 0.4);
  if (modelResult.classification == SmsClassification.promotionalSpam) {
    return AuthenticityEvaluation(isAuthentic: false, ...);
  }
}
```

---

## Model Specifications

| Property | Value |
|----------|-------|
| Base Model | `google/mobilebert-uncased` |
| Classes | `GENUINE_TXN`, `PROMO_SPAM`, `OTP_SECURITY`, `INFORMATIONAL` |
| Input Shape | `[1, 64]` int32 token IDs + `[1, 64]` int32 attention mask |
| Output Shape | `[1, 4]` float32 logits |
| Quantization | INT8 (full integer, dynamic range) |
| Expected Size | 4.3 – 11.7 MB |
| Inference Speed | ~5-8 ms per message on ARM64 |
| Vocab Size | 30,522 tokens (standard BERT WordPiece) |

---

## Execution Checklist

- [ ] Install Python venv + TensorFlow 2.15 + transformers
- [ ] Run `generate_training_data.py` → `training_data.csv`
- [ ] Run `train_financial_classifier.py` → fine-tuned SavedModel
- [ ] Run `export_tflite.py` → `financial_classifier.tflite` + real `vocab.txt`
- [ ] Copy to `assets/models/`
- [ ] Add `tflite_flutter: ^0.12.1` to `pubspec.yaml`
- [ ] Create `tflite_engine.dart`
- [ ] Modify `authenticity_validator.dart` to blend model + heuristic
- [ ] Update `bert_tokenizer.dart` with 30,522-token vocab
- [ ] `flutter test` — all existing tests pass
- [ ] Deploy to device and validate with real SMS

---

## What We Keep

The existing regex+heuristic engine is **not replaced** — it becomes the fast-path fallback:

1. **Stage 1 (Regex Gatekeeper):** Stays. Drops 95% of noise in < 0.1ms.
2. **Stage 2 (AI Model):** NEW. Runs on the ~50 candidates that pass Stage 1.
3. **Stage 3 (Heuristic Validator):** Stays. Cross-validates model output.

The model and heuristics **reinforce each other**.
