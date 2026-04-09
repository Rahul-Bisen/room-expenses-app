import 'package:flutter/material.dart';
import 'models.dart';
import 'api_service.dart';
import 'add_expense_screen.dart';
import 'member_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  late int _selectedYear;
  late String _selectedMonthName;
  late List<int> _years;

  MonthlyResponse? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedYear = now.year;
    _selectedMonthName = _months[now.month - 1];
    _years = List.generate(4, (i) => now.year - 2 + i);
    _loadMonth();
  }

  String get _selectedMonth => '$_selectedYear-$_selectedMonthName';

  Future<void> _loadMonth() async {
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await _api.getMonth(_selectedMonth);
      setState(() { _data = resp; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Room Expenses')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddExpense(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : RefreshIndicator(
                  onRefresh: _loadMonth,
                  child: _buildBody(),
                ),
    );
  }

  Widget _buildBody() {
    final data = _data!;
    final summary = data.summary;

    return ListView(
      padding: const EdgeInsets.only(bottom: 80),
      children: [
        // Month Selector
        _buildMonthSelector(),
        const SizedBox(height: 8),

        // Action Buttons
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _navigateToManageMembers,
                  icon: const Icon(Icons.people, size: 18),
                  label: const Text('Members'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _navigateToAddExpense,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Expense'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Summary Cards
        _buildSummaryCards(summary),
        const SizedBox(height: 12),

        // Expenses Summary Table
        _buildExpensesSummaryTable(summary, data),
        const SizedBox(height: 12),

        // Monthly Expenses
        _buildSectionHeader('Monthly Expenses', Icons.calendar_month),
        _buildMonthlyExpensesTable(data),
        const SizedBox(height: 12),

        // Variable Expenses
        _buildSectionHeader('Variable Expenses', Icons.shopping_cart),
        _buildVariableExpensesTable(data),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.date_range, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButton<int>(
                isExpanded: true,
                value: _selectedYear,
                underline: const SizedBox(),
                items: _years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                onChanged: (v) {
                  _selectedYear = v!;
                  _loadMonth();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedMonthName,
                underline: const SizedBox(),
                items: _months.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) {
                  _selectedMonthName = v!;
                  _loadMonth();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(MonthlySummary summary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _summaryCard('Total\nExpense', summary.totalExpense, Colors.blue),
          _summaryCard('Variable\nExpense', summary.variableExpenseTotal, Colors.orange),
          _summaryCard('Monthly\nExpenses', summary.totalFixedContribution, Colors.green),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, double value, Color color) {
    return Expanded(
      child: Card(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: color, width: 3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              const SizedBox(height: 4),
              Text(
                _formatNumber(value),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildExpensesSummaryTable(MonthlySummary summary, MonthlyResponse data) {
    final members = summary.activeMembers;
    if (members.isEmpty) return const SizedBox();

    // Calculate monthly contribution (sum of costs where member is paidBy)
    Map<String, double> monthlyContribution = {};
    for (var exp in data.expenses) {
      final payer = exp.paidBy.trim();
      if (payer.isNotEmpty) {
        monthlyContribution[payer] = (monthlyContribution[payer] ?? 0) + exp.cost;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 8),
              child: Text('Expenses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 16,
                headingRowHeight: 40,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 36,
                columns: const [
                  DataColumn(label: Text('Member', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  DataColumn(label: Text('Fixed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
                  DataColumn(label: Text('Monthly', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
                  DataColumn(label: Text('Variable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
                  DataColumn(label: Text('Total Due', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
                ],
                rows: members.map((m) {
                  final due = summary.totalDue[m] ?? 0;
                  return DataRow(cells: [
                    DataCell(Text(m, style: const TextStyle(fontSize: 12))),
                    DataCell(Text(_formatNumber(summary.fixedContributions[m] ?? 0), style: const TextStyle(fontSize: 12))),
                    DataCell(Text(_formatNumber(monthlyContribution[m] ?? 0), style: const TextStyle(fontSize: 12))),
                    DataCell(Text(_formatNumber(summary.rationPaid[m] ?? 0), style: const TextStyle(fontSize: 12))),
                    DataCell(Text(
                      _formatNumber(due),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: due > 0 ? Colors.red : Colors.green,
                      ),
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyExpensesTable(MonthlyResponse data) {
    final expenses = data.expenses;
    final members = data.activeMembers;
    if (expenses.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No monthly expenses')));
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 14,
          headingRowHeight: 40,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 36,
          columns: [
            const DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            const DataColumn(label: Text('Expense', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            const DataColumn(label: Text('Cost', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
            const DataColumn(label: Text('Paid By', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            const DataColumn(label: Text('Split', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
            ...members.map((m) => DataColumn(
              label: Text(m, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              numeric: true,
            )),
          ],
          rows: [
            ...expenses.map((exp) => DataRow(
              onLongPress: () => _showExpenseActions(exp),
              cells: [
                DataCell(Text(_formatDate(exp.date), style: const TextStyle(fontSize: 11))),
                DataCell(Text(exp.expense, style: const TextStyle(fontSize: 12))),
                DataCell(Text(_formatNumber(exp.cost), style: const TextStyle(fontSize: 12))),
                DataCell(Text(exp.paidBy, style: const TextStyle(fontSize: 12))),
                DataCell(Text('${exp.split}', style: const TextStyle(fontSize: 12))),
                ...members.map((m) => DataCell(
                  Text(_formatNumber(exp.memberAmounts[m] ?? 0), style: const TextStyle(fontSize: 11)),
                )),
              ],
            )),
            // Total row
            DataRow(
              color: WidgetStateProperty.all(Colors.grey[200]),
              cells: [
                const DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                const DataCell(Text('')),
                DataCell(Text(
                  _formatNumber(expenses.fold(0.0, (s, e) => s + e.cost)),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                )),
                const DataCell(Text('')),
                const DataCell(Text('')),
                ...members.map((m) => DataCell(Text(
                  _formatNumber(expenses.fold(0.0, (s, e) => s + (e.memberAmounts[m] ?? 0))),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                ))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariableExpensesTable(MonthlyResponse data) {
    final transactions = data.transactions;
    if (transactions.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No variable expenses')));
    }

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingRowHeight: 40,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 36,
          columns: const [
            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Transaction', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('Cost', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)), numeric: true),
            DataColumn(label: Text('Paid By', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
          rows: [
            ...transactions.map((tx) => DataRow(
              onLongPress: () => _showTransactionActions(tx),
              cells: [
                DataCell(Text(_formatDate(tx.date), style: const TextStyle(fontSize: 11))),
                DataCell(Text(tx.transaction, style: const TextStyle(fontSize: 12))),
                DataCell(Text(_formatNumber(tx.cost), style: const TextStyle(fontSize: 12))),
                DataCell(Text(tx.paidBy, style: const TextStyle(fontSize: 12))),
              ],
            )),
            // Total row
            DataRow(
              color: WidgetStateProperty.all(Colors.grey[200]),
              cells: [
                const DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                const DataCell(Text('')),
                DataCell(Text(
                  _formatNumber(transactions.fold(0.0, (s, t) => s + t.cost)),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                )),
                const DataCell(Text('')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseActions(MonthlyExpenseItem exp) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text('Edit "${exp.expense}"'),
              onTap: () {
                Navigator.pop(ctx);
                _navigateToAddExpense(editExpense: exp);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text('Delete "${exp.expense}"'),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await _confirmDelete('expense "${exp.expense}"');
                if (confirm && exp.id != null) {
                  try {
                    await _api.deleteExpense(_selectedMonth, exp.id!);
                    _loadMonth();
                  } catch (e) {
                    _showSnack('Failed to delete: $e');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionActions(MonthlyTransaction tx) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text('Delete "${tx.transaction}"'),
              onTap: () async {
                Navigator.pop(ctx);
                final confirm = await _confirmDelete('transaction "${tx.transaction}"');
                if (confirm && tx.id != null) {
                  try {
                    await _api.deleteTransactions([tx.id!]);
                    _loadMonth();
                  } catch (e) {
                    _showSnack('Failed to delete: $e');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(String item) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete $item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _navigateToAddExpense({MonthlyExpenseItem? editExpense}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddExpenseScreen(
          month: _selectedMonth,
          activeMembers: _data?.activeMembers ?? [],
          editExpense: editExpense,
        ),
      ),
    );
    if (result == true) _loadMonth();
  }

  void _navigateToManageMembers() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemberManagementScreen(
          month: _selectedMonth,
          members: _data?.monthMembers ?? [],
        ),
      ),
    );
    if (result == true) _loadMonth();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  String _formatDate(String date) {
    if (date.length >= 10) {
      // "2026-03-31" → "31-03"
      return '${date.substring(8, 10)}-${date.substring(5, 7)}';
    }
    return date;
  }
}
