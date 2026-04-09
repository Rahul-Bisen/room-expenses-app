import 'package:flutter/material.dart';
import 'models.dart';
import 'api_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final String month;
  final List<String> activeMembers;
  final MonthlyExpenseItem? editExpense;

  const AddExpenseScreen({
    super.key,
    required this.month,
    required this.activeMembers,
    this.editExpense,
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

  bool get _isEditing => widget.editExpense != null;

  @override
  void initState() {
    super.initState();
    for (var m in widget.activeMembers) {
      _memberControllers[m] = TextEditingController(text: '0');
    }

    if (_isEditing) {
      final exp = widget.editExpense!;
      _dateController.text = exp.date;
      _descriptionController.text = exp.expense;
      _costController.text = exp.cost.toString();
      _splitController.text = exp.split.toString();
      _paidBy = exp.paidBy;
      for (var m in widget.activeMembers) {
        _memberControllers[m]?.text = (exp.memberAmounts[m] ?? 0).toStringAsFixed(2);
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
        await _api.addTransaction(widget.month, body);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Expense' : 'Add Expense'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Expense Type
            if (!_isEditing)
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'monthly', label: Text('Monthly'), icon: Icon(Icons.calendar_month)),
                  ButtonSegment(value: 'variable', label: Text('Variable'), icon: Icon(Icons.shopping_cart)),
                ],
                selected: {_expenseType},
                onSelectionChanged: (s) => setState(() => _expenseType = s.first),
              ),
            const SizedBox(height: 16),

            // Date
            TextFormField(
              controller: _dateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Date',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
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
                labelText: _expenseType == 'variable' ? 'Transaction' : 'Expense',
                border: const OutlineInputBorder(),
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
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
              onChanged: (_) {
                if (_expenseType == 'monthly') _calculateSplit();
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
              initialValue: _paidBy,
              decoration: const InputDecoration(
                labelText: 'Paid By',
                border: OutlineInputBorder(),
              ),
              items: widget.activeMembers
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _paidBy = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Split (for monthly only)
            if (_expenseType == 'monthly') ...[
              TextFormField(
                controller: _splitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Split',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _calculateSplit(),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  if (int.tryParse(v) == null) return 'Integer required';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Member amounts
              const Text('Member Amounts', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 8),
              ...widget.activeMembers.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextFormField(
                  controller: _memberControllers[m],
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: m,
                    border: const OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                ),
              )),
            ],

            const SizedBox(height: 24),

            // Submit
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isEditing
                        ? 'Save Expense'
                        : _expenseType == 'variable'
                            ? 'Add Variable Expense'
                            : 'Add Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
