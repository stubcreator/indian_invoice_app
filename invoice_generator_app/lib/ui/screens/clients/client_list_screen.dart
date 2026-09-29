import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/client_provider.dart';
import '../../common/app_card.dart';
import '../../common/empty_state_view.dart';
import 'client_form_screen.dart';

class ClientListScreen extends StatefulWidget {
  const ClientListScreen({super.key});

  @override
  State<ClientListScreen> createState() => _ClientListScreenState();
}

class _ClientListScreenState extends State<ClientListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientProvider = context.watch<ClientProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customers & Clients'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Add Customer', style: TextStyle(fontWeight: FontWeight.w600)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ClientFormScreen()),
          );
        },
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => clientProvider.loadClients(query: val),
              decoration: InputDecoration(
                hintText: 'Search by name, company, GSTIN...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          clientProvider.loadClients();
                        },
                      )
                    : null,
              ),
            ),
          ),

          // List
          Expanded(
            child: clientProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : clientProvider.clients.isEmpty
                    ? EmptyStateView(
                        icon: Icons.people_outline_rounded,
                        title: 'No Customers Yet',
                        message: 'Add customers to quickly select them when creating invoices.',
                        buttonText: 'Add First Customer',
                        onButtonPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ClientFormScreen()),
                          );
                        },
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: clientProvider.clients.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final client = clientProvider.clients[index];
                          return AppCard(
                            padding: const EdgeInsets.all(14),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ClientFormScreen(client: client)),
                              );
                            },
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  child: Text(
                                    client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        client.name,
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                      ),
                                      if (client.companyName != null)
                                        Text(
                                          client.companyName!,
                                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                                        ),
                                      if (client.gstin != null && client.gstin!.isNotEmpty)
                                        Text(
                                          'GSTIN: ${client.gstin}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary),
                                        ),
                                      if (client.state != null)
                                        Text(
                                          'POS: ${client.state} (${client.stateCode ?? ""})',
                                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                        ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.primary),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => ClientFormScreen(client: client)),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.danger),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('Delete Customer?'),
                                        content: Text('Are you sure you want to delete ${client.name}?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      clientProvider.deleteClient(client.id!);
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
