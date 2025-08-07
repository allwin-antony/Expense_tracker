class Payment {
  final int? id;
  final String description;
  final double amount;
  final String category;
  final DateTime date;
  final String? notes;
  final bool isInitiated; // true for UPI initiated, false for manual entry

  Payment({
    this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    this.notes,
    required this.isInitiated,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'notes': notes,
      'isInitiated': isInitiated ? 1 : 0,
    };
  }

  static Payment fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      description: map['description'],
      amount: map['amount'],
      category: map['category'],
      date: DateTime.parse(map['date']),
      notes: map['notes'],
      isInitiated: map['isInitiated'] == 1,
    );
  }

  Payment copyWith({
    int? id,
    String? description,
    double? amount,
    String? category,
    DateTime? date,
    String? notes,
    bool? isInitiated,
  }) {
    return Payment(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      isInitiated: isInitiated ?? this.isInitiated,
    );
  }
}