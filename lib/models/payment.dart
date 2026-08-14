enum TransactionType {
  debit,
  credit;

  String get displayName => this == TransactionType.debit ? 'Expense' : 'Income';
  bool get isExpense => this == TransactionType.debit;
  bool get isIncome => this == TransactionType.credit;

  static TransactionType fromString(String? value) {
    if (value == null) return TransactionType.debit;
    final normalized = value.toLowerCase().trim();
    if (normalized == 'credit' || normalized == 'income') {
      return TransactionType.credit;
    }
    return TransactionType.debit;
  }
}

enum PaymentMode {
  upi,
  card,
  netBanking,
  cash,
  other;

  String get displayName {
    switch (this) {
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.card:
        return 'Card';
      case PaymentMode.netBanking:
        return 'Net Banking';
      case PaymentMode.cash:
        return 'Cash';
      case PaymentMode.other:
        return 'Other';
    }
  }

  static PaymentMode fromString(String? value) {
    if (value == null) return PaymentMode.upi;
    final normalized = value.toLowerCase().trim();
    if (normalized.contains('card')) return PaymentMode.card;
    if (normalized.contains('net') || normalized.contains('bank')) {
      return PaymentMode.netBanking;
    }
    if (normalized.contains('cash')) return PaymentMode.cash;
    if (normalized.contains('other')) return PaymentMode.other;
    return PaymentMode.upi;
  }
}

enum PaymentSource {
  manual,
  sms,
  notification,
  clipboard;

  String get displayName {
    switch (this) {
      case PaymentSource.manual:
        return 'Manual';
      case PaymentSource.sms:
        return 'SMS';
      case PaymentSource.notification:
        return 'Notification';
      case PaymentSource.clipboard:
        return 'Clipboard';
    }
  }

  static PaymentSource fromString(String? value) {
    if (value == null) return PaymentSource.manual;
    final normalized = value.toLowerCase().trim();
    if (normalized == 'sms') return PaymentSource.sms;
    if (normalized == 'notification') return PaymentSource.notification;
    if (normalized == 'clipboard') return PaymentSource.clipboard;
    return PaymentSource.manual;
  }
}

class Payment {
  final int? id;
  final String description;
  final double amount;
  final TransactionType type;
  final String category;
  final PaymentMode paymentMode;
  final PaymentSource source;
  final String? accountReference;
  final String? rawMessage;
  final double? confidence;
  final DateTime date;
  final String? notes;

  Payment({
    this.id,
    required this.description,
    required this.amount,
    this.type = TransactionType.debit,
    required this.category,
    this.paymentMode = PaymentMode.upi,
    this.source = PaymentSource.manual,
    this.accountReference,
    this.rawMessage,
    this.confidence,
    required this.date,
    this.notes,
  });

  bool get isExpense => type == TransactionType.debit;
  bool get isIncome => type == TransactionType.credit;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type.name,
      'category': category,
      'paymentMode': paymentMode.name,
      'source': source.name,
      'accountReference': accountReference,
      'rawMessage': rawMessage,
      'confidence': confidence,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  static Payment fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      description: (map['description'] ?? '') as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: TransactionType.fromString(map['type'] as String?),
      category: (map['category'] ?? 'Other Expense') as String,
      paymentMode: PaymentMode.fromString(map['paymentMode'] as String?),
      source: PaymentSource.fromString(map['source'] as String?),
      accountReference: map['accountReference'] as String?,
      rawMessage: map['rawMessage'] as String?,
      confidence: (map['confidence'] as num?)?.toDouble(),
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : DateTime.now(),
      notes: map['notes'] as String?,
    );
  }

  Payment copyWith({
    int? id,
    String? description,
    double? amount,
    TransactionType? type,
    String? category,
    PaymentMode? paymentMode,
    PaymentSource? source,
    String? accountReference,
    String? rawMessage,
    double? confidence,
    DateTime? date,
    String? notes,
  }) {
    return Payment(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      paymentMode: paymentMode ?? this.paymentMode,
      source: source ?? this.source,
      accountReference: accountReference ?? this.accountReference,
      rawMessage: rawMessage ?? this.rawMessage,
      confidence: confidence ?? this.confidence,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}