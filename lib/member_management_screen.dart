import 'package:flutter/material.dart';
import 'models.dart';
import 'api_service.dart';

class MemberManagementScreen extends StatefulWidget {
  final String month;
  final List<MonthMemberInfo> members;

  const MemberManagementScreen({
    super.key,
    required this.month,
    required this.members,
  });

  @override
  State<MemberManagementScreen> createState() => _MemberManagementScreenState();
}

class _MemberManagementScreenState extends State<MemberManagementScreen> {
  final ApiService _api = ApiService();
  final _nameController = TextEditingController();
  late List<MonthMemberInfo> _members;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _members = List.from(widget.members);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addMember() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    try {
      final member = await _api.addMonthMember(widget.month, name);
      setState(() {
        _members.add(member);
        _changed = true;
      });
      _nameController.clear();
    } catch (e) {
      _showSnack('Failed to add member: $e');
    }
  }

  Future<void> _toggleStatus(MonthMemberInfo member) async {
    try {
      await _api.updateMemberStatus(widget.month, member.name, !member.active);
      setState(() {
        member.active = !member.active;
        _changed = true;
      });
    } catch (e) {
      _showSnack('Failed to update status: $e');
    }
  }

  Future<void> _deleteMember(MonthMemberInfo member) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text('Remove ${member.name} from this month?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _api.deleteMember(widget.month, member.name);
      setState(() {
        _members.remove(member);
        _changed = true;
      });
    } catch (e) {
      _showSnack('Failed to delete member: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _changed) {
          // Return true to indicate data changed
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manage Members'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _changed),
          ),
        ),
        body: Column(
          children: [
            // Add member row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Member name',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      textCapitalization: TextCapitalization.characters,
                      onSubmitted: (_) => _addMember(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _addMember,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Member list
            Expanded(
              child: _members.isEmpty
                  ? const Center(child: Text('No members for this month'))
                  : ListView.builder(
                      itemCount: _members.length,
                      itemBuilder: (ctx, i) {
                        final m = _members[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: m.active ? Colors.green[100] : Colors.grey[300],
                              child: Text(
                                m.name.isNotEmpty ? m.name[0] : '?',
                                style: TextStyle(
                                  color: m.active ? Colors.green[800] : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: m.active ? Colors.green[50] : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    m.active ? 'Active' : 'Paused',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: m.active ? Colors.green[700] : Colors.grey[600],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Fixed ₹${m.fixedContribution.toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextButton(
                                  onPressed: () => _toggleStatus(m),
                                  child: Text(m.active ? 'Pause' : 'Reactivate'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                  onPressed: () => _deleteMember(m),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
