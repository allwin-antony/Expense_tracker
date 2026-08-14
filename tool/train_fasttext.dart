import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// FastText Subword N-Gram Financial SMS Classifier Trainer in Pure Dart
/// 
/// Classes:
/// 0: GENUINE_TRANSACTION (debit, credit, UPI, ATM, salary, refund)
/// 1: PROMOTIONAL_SPAM (fake loans, pre-approved loan marketing, credit limit increase, spam)
/// 2: OTP_SECURITY (OTPs, 2FA, login verification)
/// 3: INFORMATIONAL (balance alerts, mini-statement, bill due reminders)

const int numClasses = 4;
const int numBuckets = 8192; // 8K hashing buckets for subword n-grams
const int embeddingDim = 16;  // 16-dimensional embedding vectors
const int minNgram = 3;
const int maxNgram = 6;

/// 32-bit FNV-1a Hash Algorithm
int fnv1aHash(String str) {
  var hash = 2166136261;
  final codeUnits = str.codeUnits;
  for (var i = 0; i < codeUnits.length; i++) {
    hash ^= codeUnits[i];
    hash = (hash * 16777619) & 0xFFFFFFFF;
  }
  return hash.abs() % numBuckets;
}

/// Extracts words and character n-grams (subwords) for FastText
List<int> extractFeatureIndices(String text) {
  final clean = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  final words = clean.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
  final indices = <int>[];

  for (final word in words) {
    // Word hash
    indices.add(fnv1aHash(word));

    // Subword character n-grams
    final bounded = '<$word>';
    final len = bounded.length;
    for (var n = minNgram; n <= maxNgram; n++) {
      for (var i = 0; i <= len - n; i++) {
        final ngram = bounded.substring(i, i + n);
        indices.add(fnv1aHash(ngram));
      }
    }
  }

  return indices.isEmpty ? [0] : indices;
}

class FastTextTrainer {
  final List<List<double>> embeddings; // [numBuckets][embeddingDim]
  final List<List<double>> outputWeights; // [numClasses][embeddingDim]
  final List<double> outputBias; // [numClasses]
  final Random _rng = Random(42);

  FastTextTrainer()
      : embeddings = List.generate(
          numBuckets,
          (_) => List.generate(embeddingDim, (_) => (Random(42).nextDouble() - 0.5) * 0.05),
        ),
        outputWeights = List.generate(
          numClasses,
          (_) => List.generate(embeddingDim, (_) => (Random(42).nextDouble() - 0.5) * 0.05),
        ),
        outputBias = List.filled(numClasses, 0.0);

  List<double> computeHidden(List<int> features) {
    final h = List.filled(embeddingDim, 0.0);
    for (final idx in features) {
      final emb = embeddings[idx];
      for (var d = 0; d < embeddingDim; d++) {
        h[d] += emb[d];
      }
    }
    final scale = 1.0 / features.length;
    for (var d = 0; d < embeddingDim; d++) {
      h[d] *= scale;
    }
    return h;
  }

  List<double> predictProbs(List<int> features) {
    final h = computeHidden(features);
    final logits = List.filled(numClasses, 0.0);
    for (var c = 0; c < numClasses; c++) {
      var sum = outputBias[c];
      for (var d = 0; d < embeddingDim; d++) {
        sum += outputWeights[c][d] * h[d];
      }
      logits[c] = sum;
    }

    final maxL = logits.reduce(max);
    final exps = logits.map((l) => exp(l - maxL)).toList();
    final sumExp = exps.reduce((a, b) => a + b);
    return exps.map((e) => e / sumExp).toList();
  }

  void trainSample(List<int> features, int label, double lr) {
    final h = computeHidden(features);
    final probs = predictProbs(features);

    // Compute gradient for output layer & backprop to hidden
    final dLogits = List.filled(numClasses, 0.0);
    for (var c = 0; c < numClasses; c++) {
      dLogits[c] = probs[c] - (c == label ? 1.0 : 0.0);
      outputBias[c] -= lr * dLogits[c];
    }

    final dH = List.filled(embeddingDim, 0.0);
    for (var c = 0; c < numClasses; c++) {
      for (var d = 0; d < embeddingDim; d++) {
        dH[d] += dLogits[c] * outputWeights[c][d];
        outputWeights[c][d] -= lr * dLogits[c] * h[d];
      }
    }

    // Backprop to embedding table
    final scale = lr / features.length;
    for (final idx in features) {
      for (var d = 0; d < embeddingDim; d++) {
        embeddings[idx][d] -= scale * dH[d];
      }
    }
  }

  Map<String, dynamic> exportWeights() {
    return {
      'model': 'FastText-Financial-Classifier-v1',
      'numClasses': numClasses,
      'numBuckets': numBuckets,
      'embeddingDim': embeddingDim,
      'minNgram': minNgram,
      'maxNgram': maxNgram,
      'labels': ['GENUINE_TRANSACTION', 'PROMOTIONAL_SPAM', 'OTP_SECURITY', 'INFORMATIONAL'],
      'embeddings': embeddings.map((row) => row.map((v) => double.parse(v.toStringAsFixed(4))).toList()).toList(),
      'outputWeights': outputWeights.map((row) => row.map((v) => double.parse(v.toStringAsFixed(4))).toList()).toList(),
      'outputBias': outputBias.map((v) => double.parse(v.toStringAsFixed(4))).toList(),
    };
  }
}

/// Programmatic Synthetic Indian Bank SMS Dataset Generator
List<Map<String, dynamic>> generateDataset() {
  final rng = Random(1337);
  final samples = <Map<String, dynamic>>[];

  final banks = [
    'HDFC Bank', 'SBI', 'ICICI Bank', 'Axis Bank', 'Kotak Bank',
    'Punjab National Bank', 'Bank of Baroda', 'Canara Bank', 'IndusInd Bank',
    'YES Bank', 'IDFC FIRST Bank', 'Federal Bank', 'RBL Bank', 'Union Bank'
  ];

  final merchants = [
    'Swiggy', 'Zomato', 'Amazon', 'Flipkart', 'Uber', 'Ola', 'Blinkit',
    'Zepto', 'Myntra', 'Ajio', 'Dominos', 'KFC', 'Starbucks', 'McDonalds',
    'Bescom', 'Airtel', 'Jio', 'Tata Power', 'HP Petrol', 'BPCL', 'Shell',
    'Apollo Pharmacy', 'Netmeds', 'Decathlon', 'BookMyShow', 'Nykaa'
  ];

  final amounts = ['120.00', '450.50', '899.00', '1450.00', '2500.00', '4999.00', '12400.00', '35000.00', '75000.00', '125000.00'];
  final accounts = ['XX4021', 'XX8091', 'XX3029', 'XX9920', 'XX5512', 'XX7834', 'XX1104', 'XX6723'];
  final refs = ['421890123456', '987654321098', '110293847561', '665544332211', '890123456789'];
  final dates = ['14-Aug-2026', '12-Aug-2026', '01-Aug-2026', '28-Jul-2026', '15-Aug-2026'];

  // 1. CLASS 0: GENUINE TRANSACTIONS (1,000 samples)
  final genuineTemplates = [
    "Dear Customer, Rs.{amt} has been debited from your {bank} A/c {acc} to {merch} on {date} via UPI Ref {ref}. Avl Bal: Rs 15,240.00",
    "Your {bank} Credit Card ending {acc} was spent for INR {amt} at {merch} on {date}. Avl Limit: INR 85,000.00",
    "INR {amt} debited from A/c {acc} ({bank}) for payment to {merch}. UPI Ref: {ref}",
    "{bank}: Rs.{amt} withdrawn from ATM at {merch} from A/c {acc} on {date}. Avl Bal Rs 5,400.00",
    "Alert: Rs.{amt} has been deducted from your {bank} A/c {acc} towards {merch}. Ref No {ref}",
    "Salary of INR {amt} has been credited to your {bank} A/c {acc} on {date} by ACME CORP. Avl Bal: INR 95,000.00",
    "Refund of INR {amt} has been credited to your {bank} A/c {acc} from {merch}. Ref: {ref}",
    "INR {amt} credited to A/c {acc} ({bank}). NEFT inward from {merch}. Ref: {ref}",
    "Dear Customer, Rs.{amt} has been received in your {bank} A/c {acc} via UPI from John Doe. Ref {ref}",
    "Your a/c no. {acc} is debited for Rs.{amt} on {date} and credited to VPA {merch}@upi (UPI Ref no {ref}).",
    "Paid Rs.{amt} to {merch} successfully using {bank} NetBanking on {date}. Txn ID: {ref}",
  ];

  for (var i = 0; i < 1000; i++) {
    final t = genuineTemplates[rng.nextInt(genuineTemplates.length)];
    final text = t
        .replaceAll('{amt}', amounts[rng.nextInt(amounts.length)])
        .replaceAll('{bank}', banks[rng.nextInt(banks.length)])
        .replaceAll('{acc}', accounts[rng.nextInt(accounts.length)])
        .replaceAll('{merch}', merchants[rng.nextInt(merchants.length)])
        .replaceAll('{date}', dates[rng.nextInt(dates.length)])
        .replaceAll('{ref}', refs[rng.nextInt(refs.length)]);
    samples.add({'text': text, 'label': 0});
  }

  // 2. CLASS 1: PROMOTIONAL SPAM & FAKE LOAN ADS (1,000 samples)
  final promoTemplates = [
    "Good news! Pre-approved personal loan of upto Rs.{amt} is credited instantly when you apply on {bank}. Click to avail: https://bit.ly/loan",
    "Congratulations! You are eligible for an instant personal loan of up to Rs. {amt} with zero documentation. Apply now: http://u3.mnge.co/x",
    "{bank}: Get Rs.{amt} cashback on your next order! Use code SAVE50. Shop now on {merch}: https://tinyurl.com/xyz",
    "Dear Customer, your {bank} credit card limit has been enhanced to Rs.{amt}. Avail this exclusive offer now: http://offers.bank.com",
    "Win up to Rs.{amt}! Spin the wheel on {merch} app today. Limited period festive offer. T&C apply. Click: https://deal.in/win",
    "Pre-qualified personal loan of Rs.{amt} waiting for you! Instant disbursal into your account. Click here: https://quickcash.loan",
    "Flat Rs.{amt} off on {merch}! Order now and save big. Use coupon CODE100 at checkout: https://shop.now",
    "Need urgent cash? Get instant loan up to Rs.{amt} credited in 5 minutes without salary slip. Download app: https://easyloan.in",
    "Special offer: Zero interest EMI available on {merch} with your {bank} card. Shop now: https://emi.deals.com",
    "Exclusive reward: Rs.{amt} voucher credited to your wallet! Claim before midnight: https://claim-reward.xyz",
    "Your loan approval is ready for Rs.{amt}. Disbursal directly to bank account. Complete KYC: https://loan-kyc.com",
  ];

  for (var i = 0; i < 1000; i++) {
    final t = promoTemplates[rng.nextInt(promoTemplates.length)];
    final text = t
        .replaceAll('{amt}', amounts[rng.nextInt(amounts.length)])
        .replaceAll('{bank}', banks[rng.nextInt(banks.length)])
        .replaceAll('{merch}', merchants[rng.nextInt(merchants.length)]);
    samples.add({'text': text, 'label': 1});
  }

  // 3. CLASS 2: OTP & SECURITY ALERTS (600 samples)
  final otpTemplates = [
    "Your OTP for transaction of INR {amt} at {merch} is {otp}. Do not share this OTP with anyone, including bank staff.",
    "{otp} is your one time password for {bank} Bank NetBanking login. Valid for 5 mins. Do not share.",
    "Your verification code for {merch} payment of Rs.{amt} is {otp}. OTP expires in 3 minutes.",
    "Dear Customer, {otp} is the secret OTP for your {bank} card transaction. Never disclose it to callers.",
    "{otp} is the OTP for linking your bank account on UPI. If not requested by you, call 1800-12345.",
    "Use OTP {otp} to authenticate your login on {merch} app. Valid for 10 minutes.",
  ];

  for (var i = 0; i < 600; i++) {
    final t = otpTemplates[rng.nextInt(otpTemplates.length)];
    final otp = (100000 + rng.nextInt(900000)).toString();
    final text = t
        .replaceAll('{amt}', amounts[rng.nextInt(amounts.length)])
        .replaceAll('{bank}', banks[rng.nextInt(banks.length)])
        .replaceAll('{merch}', merchants[rng.nextInt(merchants.length)])
        .replaceAll('{otp}', otp);
    samples.add({'text': text, 'label': 2});
  }

  // 4. CLASS 3: INFORMATIONAL & BALANCE ALERTS (600 samples)
  final infoTemplates = [
    "Dear Customer, your available balance in A/C {acc} is INR {amt} as on {date}.",
    "{bank} Bank: Avl Bal in A/c {acc} is Rs.{amt} as of {date}. For mini statement give missed call to 1800112211.",
    "Your {bank} A/c {acc} total clear balance is Rs.{amt}. Thank you for banking with us.",
    "Bill payment reminder: Rs.{amt} for your {merch} connection is due on {date}. Pay before due date to avoid late fee.",
    "Dear Customer, your {bank} credit card bill for Rs.{amt} is generated. Total Due Date: {date}. Minimum due: Rs.500.",
    "Your monthly e-statement for {bank} account {acc} for July 2026 has been sent to your registered email.",
  ];

  for (var i = 0; i < 600; i++) {
    final t = infoTemplates[rng.nextInt(infoTemplates.length)];
    final text = t
        .replaceAll('{amt}', amounts[rng.nextInt(amounts.length)])
        .replaceAll('{bank}', banks[rng.nextInt(banks.length)])
        .replaceAll('{acc}', accounts[rng.nextInt(accounts.length)])
        .replaceAll('{merch}', merchants[rng.nextInt(merchants.length)])
        .replaceAll('{date}', dates[rng.nextInt(dates.length)]);
    samples.add({'text': text, 'label': 3});
  }

  samples.shuffle(rng);
  return samples;
}

void main() {
  print('========================================================');
  print('🚀 FastText Financial SMS Classifier Trainer (Pure Dart)');
  print('========================================================\n');

  final data = generateDataset();
  print('📊 Generated ${data.length} balanced synthetic SMS samples.');

  final splitIdx = (data.length * 0.85).toInt();
  final trainData = data.sublist(0, splitIdx);
  final testData = data.sublist(splitIdx);
  print('🔹 Training set: ${trainData.length} samples | Test set: ${testData.length} samples\n');

  final trainer = FastTextTrainer();

  // Pre-extract features
  final trainFeatures = trainData.map((s) => extractFeatureIndices(s['text'] as String)).toList();
  final trainLabels = trainData.map((s) => s['label'] as int).toList();

  final testFeatures = testData.map((s) => extractFeatureIndices(s['text'] as String)).toList();
  final testLabels = testData.map((s) => s['label'] as int).toList();

  // Training Loop
  const epochs = 30;
  var initialLr = 0.25;

  print('🏋️ Starting FastText SGD Training (${epochs} Epochs)...');
  final stopwatch = Stopwatch()..start();

  for (var epoch = 1; epoch <= epochs; epoch++) {
    final lr = initialLr * (1.0 - (epoch - 1) / epochs);

    for (var i = 0; i < trainData.length; i++) {
      trainer.trainSample(trainFeatures[i], trainLabels[i], lr);
    }

    if (epoch % 5 == 0 || epoch == epochs) {
      // Evaluate test accuracy
      var correct = 0;
      for (var i = 0; i < testData.length; i++) {
        final probs = trainer.predictProbs(testFeatures[i]);
        var best = 0;
        for (var c = 1; c < numClasses; c++) {
          if (probs[c] > probs[best]) best = c;
        }
        if (best == testLabels[i]) correct++;
      }
      final acc = (correct / testData.length) * 100;
      print('Epoch $epoch/$epochs | LR: ${lr.toStringAsFixed(4)} | Test Accuracy: ${acc.toStringAsFixed(2)}%');
    }
  }

  stopwatch.stop();
  print('\n✅ Training completed in ${stopwatch.elapsedMilliseconds} ms!');

  // Export weights to assets/models/financial_fasttext.json
  final outputDir = Directory('assets/models');
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  final outputFile = File('assets/models/financial_fasttext.json');
  final jsonMap = trainer.exportWeights();
  final jsonString = jsonEncode(jsonMap);
  outputFile.writeAsStringSync(jsonString);

  final sizeKb = (outputFile.lengthSync() / 1024).toStringAsFixed(1);
  print('💾 Exported model weights to ${outputFile.path} ($sizeKb KB)');
  print('✨ FastText Pure Dart Model Ready for On-Device Inference!\n');
}
