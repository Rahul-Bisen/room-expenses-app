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

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  late int _selectedYear;
  late String _selectedMonthName;
  late List<int> _years;
  late TabController _tabController;

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
    _tabController = TabController(length: 3, vsync: this);
    _loadMonth();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorView()
              : RefreshIndicator(
                  onRefresh: _loadMonth,
                  child: _buildBody(),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddExpense(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense'),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Could not load data',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Colors.grey[500], fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadMonth,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final data = _data!;
    final summary = data.summary;

    return CustomScrollView(
      slivers: [
        // Gradient AppBar with Month Selector
        _buildGradientAppBar(),

        // Content
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 100, top: 8),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.people_rounded,
                        label: 'Members',
                        subtitle: '${data.activeMembers.length} active',
                        color: const Color(0xFF8B5CF6),
                        onTap: _navigateToManageMembers,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.add_chart_rounded,
                        label: 'Add Expense',
                        subtitle: 'Monthly or variable',
                        color: const Color(0xFF6366F1),
                        onTap: _navigateToAddExpense,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Summary Cards
              _buildSummaryCards(summary),
              const SizedBox(height: 16),

              // Expenses Summary
              _buildExpensesSummarySection(summary, data),
              const SizedBox(height: 16),

              // Tabs for Monthly & Variable
              _buildTabbedExpenses(data),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientAppBar() {
    return SliverAppBar(
      expandedHeight: 130,
      floating: false,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA78BFA)],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Room Expenses',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Month Selector Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: Colors.white70, size: 18),
                        const SizedBox(width: 8),
                        DropdownButton<int>(
                          value: _selectedYear,
                          underline: const SizedBox(),
                          iconEnabledColor: Colors.white70,
                          dropdownColor: const Color(0xFF6366F1),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                          items: _years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
                          onChanged: (v) {
                            _selectedYear = v!;
                            _loadMonth();
                          },
                        ),
                        Container(
                          width: 1, height: 20,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          color: Colors.white30,
                        ),
                        Expanded(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedMonthName,
                            underline: const SizedBox(),
                            iconEnabledColor: Colors.white70,
                            dropdownColor: const Color(0xFF6366F1),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards(MonthlySummary summary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _summaryCard('Total', '₹${_formatNumber(summary.totalExpense)}', const Color(0xFF6366F1), Icons.account_balance_wallet_rounded),
          const SizedBox(width: 10),
          _summaryCard('Variable', '₹${_formatNumber(summary.variableExpenseTotal)}', const Color(0xFFF59E0B), Icons.shopping_bag_rounded),
          const SizedBox(width: 10),
          _summaryCard('Fixed', '₹${_formatNumber(summary.totalFixedContribution)}', const Color(0xFF10B981), Icons.home_rounded),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(color: color.withAlpha(20), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.grey[850])),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpensesSummarySection(MonthlySummary summary, MonthlyResponse data) {
    final members = summary.activeMembers;
    if (members.isEmpty) return const SizedBox();

    Map<String, double> monthlyContribution = {};
    for (var exp in data.expenses) {
      final payer = exp.paidBy.trim();
      if (payer.isNotEmpty) {
        monthlyContribution[payer] = (monthlyContribution[payer] ?? 0) + exp.cost;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.people_alt_rounded, size: 18, color: Color(0xFF6366F1)),
                ),
                const SizedBox(width: 10),
                const Text('Member Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ...members.map((m) {
            final due = summary.totalDue[m] ?? 0;
            final isNegative = due > 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color(0xFF6366F1).withAlpha(25),
                    child: Text(
                      m.isNotEmpty ? m[0] : '?',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF6366F1), fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          'Fixed: ₹${_formatNumber(summary.fixedContributions[m] ?? 0)}  ·  Paid: ₹${_formatNumber(monthlyContribution[m] ?? 0)}  ·  Variable: ₹${_formatNumber(summary.rationPaid[m] ?? 0)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isNegative ? Colors.red.withAlpha(20) : Colors.green.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '₹${_formatNumber(due.abs())}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isNegative ? Colors.red[700] : Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildTabbedExpenses(MonthlyResponse data) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // Tab bar
          Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF6366F1),
                borderRadius: BorderRadius.circular(10),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              dividerColor: Colors.transparent,
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: const [
                Tab(text: 'Monthly'),
                Tab(text: 'Variable'),
                Tab(text: 'Details'),
              ],
            ),
          ),
          // Tab content
          SizedBox(
            height: _calculateTabHeight(data),
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMonthlyExpensesList(data),
                _buildVariableExpensesList(data),
                _buildDetailedTable(data),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTabHeight(MonthlyResponse data) {
    final monthlyCount = data.expenses.length;
    final variableCount = data.transactions.length;
    final maxCount = monthlyCount > variableCount ? monthlyCount : variableCount;
    return (maxCount * 72.0 + 60).clamp(200, 600);
  }

  Widget _buildMonthlyExpensesList(MonthlyResponse data) {
    final expenses = data.expenses;
    if (expenses.isEmpty) {
      return _buildEmptyState('No monthly expenses yet', Icons.calendar_month_rounded);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (ctx, i) {
        if (i == expenses.length) {
          return _buildTotalRow(expenses.fold(0.0, (s, e) => s + e.cost));
        }
        final exp = expenses[i];
        return _ExpenseTile(
          title: exp.expense,
          subtitle: '${_formatDate(exp.date)}  ·  Paid by ${exp.paidBy}  ·  Split ${exp.split}',
          amount: exp.cost,
          icon: Icons.receipt_long_rounded,
          color: const Color(0xFF6366F1),
          onLongPress: () => _showExpenseActions(exp),
        );
      },
    );
  }

  Widget _buildVariableExpensesList(MonthlyResponse data) {
    final transactions = data.transactions;
    if (transactions.isEmpty) {
      return _buildEmptyState('No variable expenses yet', Icons.shopping_cart_rounded);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (ctx, i) {
        if (i == transactions.length) {
          return _buildTotalRow(transactions.fold(0.0, (s, t) => s + t.cost));
        }
        final tx = transactions[i];
        return _ExpenseTile(
          title: tx.transaction,
          subtitle: '${_formatDate(tx.date)}  ·  Paid by ${tx.paidBy}',
          amount: tx.cost,
          icon: Icons.shopping_bag_rounded,
          color: const Color(0xFFF59E0B),
          onLongPress: () => _showTransactionActions(tx),
        );
      },
    );
  }

  Widget _buildDetailedTable(MonthlyResponse data) {
    final expenses = data.expenses;
    final members = data.activeMembers;
    if (expenses.isEmpty) {
      return _buildEmptyState('No expenses to show', Icons.table_chart_rounded);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 14,
          headingRowHeight: 40,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 36,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          columns: [
            const DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
            const DataColumn(label: Text('Expense', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
            const DataColumn(label: Text('Cost', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)), numeric: true),
            const DataColumn(label: Text('Paid By', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
            ...members.map((m) => DataColumn(
              label: Text(m, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              numeric: true,
            )),
          ],
          rows: [
            ...expenses.map((exp) => DataRow(
              onLongPress: () => _showExpenseActions(exp),
              cells: [
                DataCell(Text(_formatDate(exp.date), style: const TextStyle(fontSize: 11))),
                DataCell(Text(exp.expense, style: const TextStyle(fontSize: 12))),
                DataCell(Text('₹${_formatNumber(exp.cost)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                DataCell(Text(exp.paidBy, style: const TextStyle(fontSize: 12))),
                ...members.map((m) => DataCell(
                  Text('₹${_formatNumber(exp.memberAmounts[m] ?? 0)}', style: const TextStyle(fontSize: 11)),
                )),
              ],
            )),
            DataRow(
              color: WidgetStateProperty.all(const Color(0xFFEEF2FF)),
              cells: [
                const DataCell(Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF6366F1)))),
                const DataCell(Text('')),
                DataCell(Text(
                  '₹${_formatNumber(expenses.fold(0.0, (s, e) => s + e.cost))}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF6366F1)),
                )),
                const DataCell(Text('')),
                ...members.map((m) => DataCell(Text(
                  '₹${_formatNumber(expenses.fold(0.0, (s, e) => s + (e.memberAmounts[m] ?? 0)))}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF6366F1)),
                ))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(message, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(double total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF6366F1))),
          Text('₹${_formatNumber(total)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Color(0xFF6366F1))),
        ],
      ),
    );
  }

  void _showExpenseActions(MonthlyExpenseItem exp) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF6366F1).withAlpha(25), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.edit_rounded, color: Color(0xFF6366F1), size: 20),
                ),
                title: Text('Edit "${exp.expense}"'),
                onTap: () {
                  Navigator.pop(ctx);
                  _navigateToAddExpense(editExpense: exp);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                ),
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
      ),
    );
  }

  void _showTransactionActions(MonthlyTransaction tx) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.withAlpha(25), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                ),
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
      ),
    );
  }

  Future<bool> _confirmDelete(String item) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withAlpha(25), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.warning_rounded, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Confirm Delete'),
          ],
        ),
        content: Text('Delete $item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
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
      return '${date.substring(8, 10)}-${date.substring(5, 7)}';
    }
    return date;
  }
}

// Reusable action card widget
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// Reusable expense tile widget
class _ExpenseTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final double amount;
  final IconData icon;
  final Color color;
  final VoidCallback? onLongPress;

  const _ExpenseTile({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.icon,
    required this.color,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ],
                ),
              ),
              Text(
                '₹${amount == amount.roundToDouble() ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2)}',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.grey[800]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
