import 'dart:convert';
import 'package:flutter/services.dart';

class BertInputTokens {
  final List<int> inputIds;
  final List<int> attentionMask;
  final List<String> tokens;

  BertInputTokens({
    required this.inputIds,
    required this.attentionMask,
    required this.tokens,
  });
}

class BertTokenizer {
  static final BertTokenizer instance = BertTokenizer._();
  BertTokenizer._();

  final Map<String, int> _vocab = {};
  bool _isInitialized = false;

  static const int padTokenId = 0;
  static const int unkTokenId = 1;
  static const int clsTokenId = 2;
  static const int sepTokenId = 3;

  /// Loads vocab.txt from assets or string
  Future<void> initialize({String? vocabContent}) async {
    if (_isInitialized) return;

    String content;
    if (vocabContent != null) {
      content = vocabContent;
    } else {
      try {
        content = await rootBundle.loadString('assets/models/vocab.txt');
      } catch (e) {
        // Fallback default inline vocab if asset load fails
        content = '[PAD]\n[UNK]\n[CLS]\n[SEP]\n[MASK]';
      }
    }

    final lines = const LineSplitter().convert(content);
    _vocab.clear();
    for (int i = 0; i < lines.length; i++) {
      final token = lines[i].trim();
      if (token.isNotEmpty) {
        _vocab[token] = i;
      }
    }

    _isInitialized = true;
  }

  /// Basic tokenization: lowercases, splits whitespace & punctuation
  List<String> _basicTokenize(String text) {
    final clean = text.toLowerCase().trim();
    final List<String> tokens = [];
    final StringBuffer currentWord = StringBuffer();

    for (int i = 0; i < clean.length; i++) {
      final char = clean[i];
      final isAlphaNumeric = RegExp(r'[a-zA-Z0-9₹]').hasMatch(char);

      if (isAlphaNumeric) {
        currentWord.write(char);
      } else {
        if (currentWord.isNotEmpty) {
          tokens.add(currentWord.toString());
          currentWord.clear();
        }
        if (char.trim().isNotEmpty) {
          tokens.add(char);
        }
      }
    }

    if (currentWord.isNotEmpty) {
      tokens.add(currentWord.toString());
    }

    return tokens;
  }

  /// WordPiece greedy subword tokenization
  List<String> _wordPieceTokenize(String word) {
    if (word.length > 50) return ['[UNK]'];

    final List<String> subTokens = [];
    int start = 0;

    while (start < word.length) {
      int end = word.length;
      String? curSubStr;

      while (start < end) {
        var subStr = word.substring(start, end);
        if (start > 0) {
          subStr = '##$subStr';
        }

        if (_vocab.containsKey(subStr)) {
          curSubStr = subStr;
          break;
        }
        end--;
      }

      if (curSubStr == null) {
        subTokens.add('[UNK]');
        break;
      }

      subTokens.add(curSubStr);
      start = end;
    }

    return subTokens;
  }

  /// Full encoding producing BERT input tensors (input_ids & attention_mask)
  BertInputTokens encode(String text, {int maxSeqLength = 64}) {
    final basicTokens = _basicTokenize(text);
    final List<String> tokenList = ['[CLS]'];

    for (final word in basicTokens) {
      final subwords = _wordPieceTokenize(word);
      tokenList.addAll(subwords);
      if (tokenList.length >= maxSeqLength - 1) break;
    }

    if (tokenList.length > maxSeqLength - 1) {
      tokenList.removeRange(maxSeqLength - 1, tokenList.length);
    }
    tokenList.add('[SEP]');

    final List<int> inputIds = [];
    final List<int> attentionMask = [];

    for (final token in tokenList) {
      final id = _vocab[token] ?? unkTokenId;
      inputIds.add(id);
      attentionMask.add(1);
    }

    // Zero padding up to maxSeqLength
    while (inputIds.length < maxSeqLength) {
      inputIds.add(padTokenId);
      attentionMask.add(0);
    }

    return BertInputTokens(
      inputIds: inputIds,
      attentionMask: attentionMask,
      tokens: tokenList,
    );
  }
}
