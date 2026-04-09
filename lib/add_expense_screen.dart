import 'package:flutter/material.dart';
import 'models.dart';
import 'api_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final String month;
  final List<String> activeMembers;
  final MonthlyExpenseItem? editExpense;
  final MonthlyTransaction? editTransaction;

  const AddExpenseScreen({
    super.key,
    required this.month,
    required this.activeMembers,
    this.editExpense,
    this.editTransaction,
  });

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  String _expenseType = 'monthly';
  final _dateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _splitController = TextEditingController(text: '3');
  String? _paidBy;
  final Map<String, TextEditingController> _memberControllers = {};
  bool _saving = false;

  bool get _isEditing => widget.editExpense != null || widget.editTransaction != null;

  @override
  void initState() {
    super.initState();
    for (var m in widget.activeMembers) {
      _memberControllers[m] = TextEditingController(text: '0');
    }

    if (_isEditing) {
      if (widget.editExpense != null) {
        final exp = widget.editExpense!;
        _dateController.text = exp.date;
        _descriptionController.text = exp.expense;
        _costController.text = exp.cost.toString();
        _splitController.text = exp.split.toString();
        _paidBy = exp.paidBy;
        for (var m in widget.activeMembers) {
          _memberControllers[m]?.text = (exp.memberAmounts[m] ?? 0).toStringAsFixed(2);
        }
      } else if (widget.editTransaction != null) {
        final tx = widget.editTransaction!;
        _expenseType = 'variable';
        _dateController.text = tx.date;
        _descriptionController.text = tx.transaction;
        _costController.text = tx.cost.toString();
        _paidBy = tx.paidBy;
      }
    } else {
      _dateController.text = _todayString();
    }
  }

  @override
  void dispose() {
    _dateController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    _splitController.dispose();
    for (var c in _memberControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _calculateSplit() {
    final cost = double.tryParse(_costController.text) ?? 0;
    final split = int.tryParse(_splitController.text) ?? 0;
    if (split <= 0) return;
    final share = (cost / split * 100).round() / 100;
    for (var m in widget.activeMembers) {
      _memberControllers[m]?.text = share.toStringAsFixed(2);
    }
    setState(() {});
  }

  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(_dateController.text) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      _dateController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_paidBy == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Paid By')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      if (_expenseType == 'variable') {
        final body = {
          'date': _dateController.text,
          'transaction': _descriptionController.text,
          'cost': double.tryParse(_costController.text) ?? 0,
          'paidBy': _paidBy,
        };
        if (widget.editTransaction != null) {
          await _api.updateTransaction(widget.month, widget.editTransaction!.id!, body);
        } else {
          await _api.addTransaction(widget.month, body);
        }
      } else {
        final memberAmounts = <String, double>{};
        for (var m in widget.activeMembers) {
          memberAmounts[m] = double.tryParse(_memberControllers[m]?.text ?? '0') ?? 0;
        }
        final body = {
          'date': _dateController.text,
          'expense': _descriptionController.text,
          'cost': double.tryParse(_costController.text) ?? 0,
          'paidBy': _paidBy,
          'split': int.tryParse(_splitController.text) ?? 1,
          'memberAmounts': memberAmounts,
        };
        if (_isEditing) {
          await _api.updateExpense(widget.month, widget.editExpense!.id!, body);
        } else {
          await _api.addExpense(widget.month, body);
        }
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVariable = _expenseType == 'variable';
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'New Expense'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Expense Type Selector
            if (!_isEditing)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _typeChip('monthly', 'Monthly', Icons.calendar_month_rounded, const Color(0xFF6366F1)),
                    const SizedBox(width: 4),
                    _typeChip('variable', 'Variable', Icons.shopping_bag_rounded, const Color(0xFFF59E0B)),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Form Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isVariable ? 'Variable Expense Details' : 'Monthly Expense Details',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),

                  // Date
                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Date',
                      prefixIcon: const Icon(Icons.calendar_today_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.edit_calendar_rounded, size: 20),
                        onPressed: _pickDate,
                      ),
                    ),
                    onTap: _pickDate,
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: isVariable ? 'Transaction' : 'Expense',
                      prefixIcon: Icon(isVariable ? Icons.receipt_rounded : Icons.description_rounded, size: 20),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Cost
                  TextFormField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cost',
                      prefixIcon: Icon(Icons.currency_rupee_rounded, size: 20),
                    ),
                    onChanged: (_) {
                      if (!isVariable) _calculateSplit();
                    },
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Paid By
                  DropdownButtonFormField<String>(
                    value: _paidBy,
                    decoration: const InputDecoration(
                      labelText: 'Paid By',
                      prefixIcon: Icon(Icons.person_rounded, size: 20),
                    ),
                    items: widget.activeMembers
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) => setState(() => _paidBy = v),
                    validator: (v) => v == null ? 'Required' : null,
                  ),
                ],
              ),
            ),

            // Split & Member Amounts (for monthly only)
            if (!isVariable) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Split Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _splitController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Split Among',
                        prefixIcon: Icon(Icons.call_split_rounded, size: 20),
                      ),
                      onChanged: (_) => _calculateSplit(),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (int.tryParse(v) == null) return 'Integer required';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFF6366F1)),
                        ),
                        const SizedBox(width: 8),
                        const Text('Member Amounts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...widget.activeMembers.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: TextFormField(
                        controller: _memberControllers[m],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: m,
                          prefixIcon: CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFF6366F1).withAlpha(25),
                            child: Text(
                              m.isNotEmpty ? m[0] : '?',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF6366F1)),
                            ),
                          ),
                          prefixText: '₹ ',
                        ),
                      ),
                    )),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_isEditing ? Icons.save_rounded : Icons.add_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            _isEditing
                                ? 'Save Changes'
                                : isVariable
                                    ? 'Add Variable Expense'
                                    : 'Add Monthly Expense',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(String value, String label, IconData icon, Color color) {
    final selected = _expenseType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _expenseType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: selected ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
