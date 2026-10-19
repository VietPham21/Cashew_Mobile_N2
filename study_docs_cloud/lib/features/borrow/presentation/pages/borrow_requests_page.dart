import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/borrow_viewmodel.dart';
import '../../domain/entities/borrow_request.dart';

class BorrowRequestsPage extends StatefulWidget {
  const BorrowRequestsPage({super.key});

  @override
  State<BorrowRequestsPage> createState() => _BorrowRequestsPageState();
}

class _BorrowRequestsPageState extends State<BorrowRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BorrowViewModel>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _statusColor(BorrowStatus s) {
    switch (s) {
      case BorrowStatus.approved: return Colors.green;
      case BorrowStatus.rejected: return Colors.red;
      default:                    return Colors.orange;
    }
  }

  String _statusLabel(BorrowStatus s) {
    switch (s) {
      case BorrowStatus.approved: return 'Approved';
      case BorrowStatus.rejected: return 'Rejected';
      default:                    return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrow Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.inbox), text: 'Incoming'),
            Tab(icon: Icon(Icons.send), text: 'My Requests'),
          ],
        ),
      ),
      body: Consumer<BorrowViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Incoming requests (owner duyet)
              _buildIncomingTab(vm),
              // Tab 2: My requests (minh da gui)
              _buildMyRequestsTab(vm),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIncomingTab(BorrowViewModel vm) {
    if (vm.incomingRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No incoming borrow requests', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: vm.incomingRequests.length,
        itemBuilder: (context, i) {
          final req = vm.incomingRequests[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.description, size: 18, color: Colors.indigo),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          req.documentTitle,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor(req.status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _statusColor(req.status)),
                        ),
                        child: Text(
                          _statusLabel(req.status),
                          style: TextStyle(color: _statusColor(req.status), fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.person, size: 15, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(req.requesterEmail, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                  if (req.message != null && req.message!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Expanded(child: Text(req.message!, style: const TextStyle(fontSize: 13))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    'Requested: ${req.createdAt.toLocal().toString().substring(0, 16)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  if (req.status == BorrowStatus.pending) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            await vm.reject(req.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Request rejected')),
                              );
                            }
                          },
                          icon: const Icon(Icons.close, color: Colors.red),
                          label: const Text('Reject', style: TextStyle(color: Colors.red)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await vm.approve(req.id);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Request approved!')),
                              );
                            }
                          },
                          icon: const Icon(Icons.check),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyRequestsTab(BorrowViewModel vm) {
    if (vm.myRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('You have not sent any borrow requests', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: vm.loadAll,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: vm.myRequests.length,
        itemBuilder: (context, i) {
          final req = vm.myRequests[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _statusColor(req.status).withOpacity(0.15),
                child: Icon(Icons.description, color: _statusColor(req.status)),
              ),
              title: Text(req.documentTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                'Sent: ${req.createdAt.toLocal().toString().substring(0, 16)}',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(req.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _statusColor(req.status)),
                ),
                child: Text(
                  _statusLabel(req.status),
                  style: TextStyle(color: _statusColor(req.status), fontSize: 12),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
