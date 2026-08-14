import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';

/// Semantic classification classes for FastText SMS model
enum SmsClassification {
  genuineTransaction, // 0: Legitimate debit/credit/UPI/ATM/salary/refund
  promotionalSpam,    // 1: Loan marketing, limit increase, fake credit ads, scams
  otpSecurity,        // 2: One-time passwords, 2FA, login verification
  informational,      // 3: Available balance checks, mini-statement, bill reminders
}

/// Structured inference result from FastText classifier
class FastTextResult {
  final SmsClassification classification;
  final double confidence;
  final Map<SmsClassification, double> probabilities;
  final int inferenceTimeUs; // Microseconds

  const FastTextResult({
    required this.classification,
    required this.confidence,
    required this.probabilities,
    required this.inferenceTimeUs,
  });

  bool get isGenuine => classification == SmsClassification.genuineTransaction;
  bool get isSpam => classification == SmsClassification.promotionalSpam;
  bool get isOtp => classification == SmsClassification.otpSecurity;
  bool get isInfo => classification == SmsClassification.informational;

  @override
  String toString() =>
      'FastTextResult(${classification.name}, ${(confidence * 100).toStringAsFixed(1)}%, ${inferenceTimeUs}µs)';
}

/// Ultra-lightweight On-Device FastText Classifier in Pure Dart (< 0.3ms latency)
class FastTextEngine {
  static final FastTextEngine instance = FastTextEngine._();
  FastTextEngine._();

  bool _isReady = false;
  int _numClasses = 4;
  int _numBuckets = 8192;
  int _embeddingDim = 16;
  int _minNgram = 3;
  int _maxNgram = 6;

  List<List<double>>? _embeddings;
  List<List<double>>? _outputWeights;
  List<double>? _outputBias;

  bool get isReady => _isReady;

  /// Loads FastText model weights asynchronously from Flutter asset bundle or file
  Future<void> initialize({String assetPath = 'assets/models/financial_fasttext.json'}) async {
    if (_isReady) return;
    try {
      String jsonStr;
      try {
        jsonStr = await rootBundle.loadString(assetPath);
      } catch (_) {
        // Fallback for tests running outside Flutter widget tree
        final file = File(assetPath);
        if (file.existsSync()) {
          jsonStr = file.readAsStringSync();
        } else {
          return;
        }
      }

      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      loadFromJson(jsonMap);
    } catch (e) {
      // Graceful fallback to heuristic engine if model load fails
      _isReady = false;
    }
  }

  /// Loads model parameters directly from parsed JSON map
  void loadFromJson(Map<String, dynamic> jsonMap) {
    _numClasses = jsonMap['numClasses'] as int? ?? 4;
    _numBuckets = jsonMap['numBuckets'] as int? ?? 8192;
    _embeddingDim = jsonMap['embeddingDim'] as int? ?? 16;
    _minNgram = jsonMap['minNgram'] as int? ?? 3;
    _maxNgram = jsonMap['maxNgram'] as int? ?? 6;

    final embRaw = jsonMap['embeddings'] as List<dynamic>;
    _embeddings = embRaw.map((row) => (row as List<dynamic>).map((v) => (v as num).toDouble()).toList()).toList();

    final weightsRaw = jsonMap['outputWeights'] as List<dynamic>;
    _outputWeights = weightsRaw.map((row) => (row as List<dynamic>).map((v) => (v as num).toDouble()).toList()).toList();

    final biasRaw = jsonMap['outputBias'] as List<dynamic>;
    _outputBias = biasRaw.map((v) => (v as num).toDouble()).toList();

    _isReady = true;
  }

  /// 32-bit FNV-1a Hash Algorithm
  int _fnv1aHash(String str) {
    var hash = 2166136261;
    final codeUnits = str.codeUnits;
    for (var i = 0; i < codeUnits.length; i++) {
      hash ^= codeUnits[i];
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash.abs() % _numBuckets;
  }

  /// Extracts subword n-gram and word feature indices
  List<int> _extractFeatureIndices(String text) {
    final clean = text.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    final words = clean.split(RegExp(r'\s+')).where((w) => w.length > 1).toList();
    final indices = <int>[];

    for (final word in words) {
      indices.add(_fnv1aHash(word));
      final bounded = '<$word>';
      final len = bounded.length;
      for (var n = _minNgram; n <= _maxNgram; n++) {
        for (var i = 0; i <= len - n; i++) {
          indices.add(_fnv1aHash(bounded.substring(i, i + n)));
        }
      }
    }

    return indices.isEmpty ? [0] : indices;
  }

  /// Classifies financial SMS into Genuine, Promotional Spam, OTP, or Informational
  FastTextResult? classify(String text) {
    if (!_isReady || _embeddings == null || _outputWeights == null || _outputBias == null) {
      return null;
    }

    final stopwatch = Stopwatch()..start();
    final features = _extractFeatureIndices(text);

    // Compute averaged hidden embedding vector: h = (1/N) * sum(E[w])
    final h = List.filled(_embeddingDim, 0.0);
    for (final idx in features) {
      final emb = _embeddings![idx];
      for (var d = 0; d < _embeddingDim; d++) {
        h[d] += emb[d];
      }
    }
    final scale = 1.0 / features.length;
    for (var d = 0; d < _embeddingDim; d++) {
      h[d] *= scale;
    }

    // Linear projection: logits = W * h + b
    final logits = List.filled(_numClasses, 0.0);
    for (var c = 0; c < _numClasses; c++) {
      var sum = _outputBias![c];
      final wRow = _outputWeights![c];
      for (var d = 0; d < _embeddingDim; d++) {
        sum += wRow[d] * h[d];
      }
      logits[c] = sum;
    }

    // Softmax normalization
    final maxL = logits.reduce(max);
    final exps = logits.map((l) => exp(l - maxL)).toList();
    final sumExp = exps.reduce((a, b) => a + b);
    final probs = exps.map((e) => e / sumExp).toList();

    var best = 0;
    for (var c = 1; c < _numClasses; c++) {
      if (probs[c] > probs[best]) best = c;
    }

    stopwatch.stop();

    return FastTextResult(
      classification: SmsClassification.values[best],
      confidence: probs[best],
      probabilities: {
        SmsClassification.genuineTransaction: probs[0],
        SmsClassification.promotionalSpam: probs[1],
        SmsClassification.otpSecurity: probs[2],
        SmsClassification.informational: probs[3],
      },
      inferenceTimeUs: stopwatch.elapsedMicroseconds,
    );
  }
}
