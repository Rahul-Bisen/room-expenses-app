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
        backgroundColor: const Color(0xFFF1F5F9),
        appBar: AppBar(
          title: const Text('Manage Members'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context, _changed),
          ),
        ),
        body: Column(
          children: [
            // Add member row
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.person_add_rounded, size: 18, color: Color(0xFF6366F1)),
                      ),
                      const SizedBox(width: 10),
                      const Text('Add New Member', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'Enter member name',
                            prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          onSubmitted: (_) => _addMember(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _addMember,
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: const Text('Add'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Members label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${_members.length} Members',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Text(
                    '${_members.where((m) => m.active).length} active',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Color(0xFF10B981)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Member list
            Expanded(
              child: _members.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('No members for this month', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _members.length,
                      itemBuilder: (ctx, i) {
                        final m = _members[i];
                        final colors = [
                          const Color(0xFF6366F1),
                          const Color(0xFF8B5CF6),
                          const Color(0xFFF59E0B),
                          const Color(0xFF10B981),
                          const Color(0xFFEF4444),
                          const Color(0xFF3B82F6),
                        ];
                        final avatarColor = colors[i % colors.length];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            child: Row(
                              children: [
                                // Avatar
                                Container(
                                  width: 44, height: 44,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [avatarColor, avatarColor.withAlpha(180)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      m.name.isNotEmpty ? m.name[0] : '?',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: m.active ? const Color(0xFF10B981).withAlpha(20) : Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 6, height: 6,
                                                  decoration: BoxDecoration(
                                                    color: m.active ? const Color(0xFF10B981) : Colors.grey,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  m.active ? 'Active' : 'Paused',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: m.active ? const Color(0xFF10B981) : Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Fixed ₹${m.fixedContribution.toStringAsFixed(0)}',
                                            style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Actions
                                TextButton(
                                  onPressed: () => _toggleStatus(m),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    m.active ? 'Pause' : 'Activate',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: m.active ? Colors.orange[700] : const Color(0xFF10B981),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline_rounded, color: Colors.red[400], size: 20),
                                  onPressed: () => _deleteMember(m),
                                  visualDensity: VisualDensity.compact,
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
