class MonthlyExpenseItem {
  final int? id;
  final int? srNo;
  final String date;
  final String expense;
  final double cost;
  final String paidBy;
  final int split;
  final Map<String, double> memberAmounts;

  MonthlyExpenseItem({
    this.id,
    this.srNo,
    required this.date,
    required this.expense,
    required this.cost,
    required this.paidBy,
    required this.split,
    required this.memberAmounts,
  });

  factory MonthlyExpenseItem.fromJson(Map<String, dynamic> json) {
    final raw = json['memberAmounts'] as Map<String, dynamic>? ?? {};
    return MonthlyExpenseItem(
      id: json['id'] as int?,
      srNo: json['srNo'] as int?,
      date: json['date']?.toString() ?? '',
      expense: json['expense']?.toString() ?? '',
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      paidBy: json['paidBy']?.toString() ?? '',
      split: (json['split'] as num?)?.toInt() ?? 1,
      memberAmounts: raw.map((k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0)),
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'expense': expense,
        'cost': cost,
        'paidBy': paidBy,
        'split': split,
        'memberAmounts': memberAmounts,
      };
}

class MonthlyTransaction {
  final int? id;
  final String date;
  final String transaction;
  final double cost;
  final String paidBy;

  MonthlyTransaction({
    this.id,
    required this.date,
    required this.transaction,
    required this.cost,
    required this.paidBy,
  });

  factory MonthlyTransaction.fromJson(Map<String, dynamic> json) {
    return MonthlyTransaction(
      id: json['id'] as int?,
      date: json['date']?.toString() ?? '',
      transaction: json['transaction']?.toString() ?? '',
      cost: (json['cost'] as num?)?.toDouble() ?? 0,
      paidBy: json['paidBy']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'transaction': transaction,
        'cost': cost,
        'paidBy': paidBy,
      };
}

class MonthMemberInfo {
  final String name;
  bool active;
  final double fixedContribution;

  MonthMemberInfo({
    required this.name,
    required this.active,
    required this.fixedContribution,
  });

  factory MonthMemberInfo.fromJson(Map<String, dynamic> json) {
    return MonthMemberInfo(
      name: json['name']?.toString() ?? '',
      active: json['active'] as bool? ?? true,
      fixedContribution: (json['fixedContribution'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MonthlySummary {
  final double totalExpense;
  final double variableExpenseTotal;
  final double variableShare;
  final double totalFixedContribution;
  final Map<String, double> fixedContributions;
  final Map<String, double> rationPaid;
  final Map<String, double> totalDue;
  final List<String> activeMembers;

  MonthlySummary({
    required this.totalExpense,
    required this.variableExpenseTotal,
    required this.variableShare,
    required this.totalFixedContribution,
    required this.fixedContributions,
    required this.rationPaid,
    required this.totalDue,
    required this.activeMembers,
  });

  factory MonthlySummary.fromJson(Map<String, dynamic> json) {
    return MonthlySummary(
      totalExpense: (json['totalExpense'] as num?)?.toDouble() ?? 0,
      variableExpenseTotal: (json['variableExpenseTotal'] as num?)?.toDouble() ?? 0,
      variableShare: (json['variableShare'] as num?)?.toDouble() ?? 0,
      totalFixedContribution: (json['totalFixedContribution'] as num?)?.toDouble() ?? 0,
      fixedContributions: _toDoubleMap(json['fixedContributions']),
      rationPaid: _toDoubleMap(json['rationPaid']),
      totalDue: _toDoubleMap(json['totalDue']),
      activeMembers: (json['activeMembers'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class MonthlyResponse {
  final String month;
  final List<MonthlyExpenseItem> expenses;
  final List<MonthlyTransaction> transactions;
  final Map<String, double> fixedContributions;
  final List<String> activeMembers;
  final List<MonthMemberInfo> monthMembers;
  final MonthlySummary summary;

  MonthlyResponse({
    required this.month,
    required this.expenses,
    required this.transactions,
    required this.fixedContributions,
    required this.activeMembers,
    required this.monthMembers,
    required this.summary,
  });

  factory MonthlyResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return MonthlyResponse(
      month: json['month']?.toString() ?? '',
      expenses: (data['expenses'] as List?)?.map((e) => MonthlyExpenseItem.fromJson(e)).toList() ?? [],
      transactions: (data['transactions'] as List?)?.map((e) => MonthlyTransaction.fromJson(e)).toList() ?? [],
      fixedContributions: _toDoubleMap(data['fixedContributions']),
      activeMembers: (data['activeMembers'] as List?)?.map((e) => e.toString()).toList() ?? [],
      monthMembers: (data['monthMembers'] as List?)?.map((e) => MonthMemberInfo.fromJson(e)).toList() ?? [],
      summary: MonthlySummary.fromJson(json['summary'] as Map<String, dynamic>? ?? {}),
    );
  }
}

Map<String, double> _toDoubleMap(dynamic raw) {
  if (raw == null) return {};
  return (raw as Map<String, dynamic>).map((k, v) => MapEntry(k, (v as num?)?.toDouble() ?? 0));
}
