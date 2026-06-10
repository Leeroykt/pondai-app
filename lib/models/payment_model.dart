class PaymentModel {
  final int? id;
  final int? assignmentId;
  final String studentName;
  final double amount;
  final String paymentDate;
  final String monthPaidFor;
  final String method;
  final String notes;
  final bool isSynced;
  final String? localId;

  PaymentModel({
    this.id,
    this.assignmentId,
    this.studentName = '',
    required this.amount,
    required this.paymentDate,
    required this.monthPaidFor,
    this.method = 'cash',
    this.notes = '',
    this.isSynced = true,
    this.localId,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> j) => PaymentModel(
    id: j['id'],
    assignmentId: j['assignment_id'],
    studentName: j['assignment']?['student']?['full_name'] ?? '',
    amount: (j['amount'] ?? 0).toDouble(),
    paymentDate: j['payment_date'] ?? '',
    monthPaidFor: j['month_paid_for'] ?? '',
    method: j['method'] ?? 'cash',
    notes: j['notes'] ?? '',
    isSynced: true,
  );

  factory PaymentModel.fromLocal(Map<String, dynamic> j) => PaymentModel(
    id: j['server_id'],
    localId: j['local_id'],
    assignmentId: j['assignment_id'],
    studentName: j['student_name'] ?? '',
    amount: (j['amount'] ?? 0).toDouble(),
    paymentDate: j['payment_date'] ?? '',
    monthPaidFor: j['month_paid_for'] ?? '',
    method: j['method'] ?? 'cash',
    notes: j['notes'] ?? '',
    isSynced: j['is_synced'] == 1,
  );

  Map<String, dynamic> toJson() => {
    'assignment_id': assignmentId,
    'amount': amount,
    'payment_date': paymentDate,
    'month_paid_for': monthPaidFor,
    'method': method,
    'notes': notes,
  };

  Map<String, dynamic> toLocal(String localId) => {
    'local_id': localId,
    'server_id': id,
    'assignment_id': assignmentId,
    'student_name': studentName,
    'amount': amount,
    'payment_date': paymentDate,
    'month_paid_for': monthPaidFor,
    'method': method,
    'notes': notes,
    'is_synced': isSynced ? 1 : 0,
  };
  
  PaymentModel copyWith({
    int? id,
    int? assignmentId,
    String? studentName,
    double? amount,
    String? paymentDate,
    String? monthPaidFor,
    String? method,
    String? notes,
    bool? isSynced,
    String? localId,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      assignmentId: assignmentId ?? this.assignmentId,
      studentName: studentName ?? this.studentName,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      monthPaidFor: monthPaidFor ?? this.monthPaidFor,
      method: method ?? this.method,
      notes: notes ?? this.notes,
      isSynced: isSynced ?? this.isSynced,
      localId: localId ?? this.localId,
    );
  }
}