import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/client_model.dart';
import '../../../../providers/client_provider.dart';
import '../../clients/client_form_screen.dart';

class ClientSelectSheet extends StatefulWidget {
  final Function(ClientModel client) onClientSelected;

  const ClientSelectSheet({super.key, required this.onClientSelected});

  @override
  State<ClientSelectSheet> createState() => _ClientSelectSheetState();
}

class _ClientSelectSheetState extends State<ClientSelectSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clientProvider = context.watch<ClientProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Customer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search & Add Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => clientProvider.loadClients(query: val),
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone, GSTIN...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.cardBorder),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  final newClient = await Navigator.push<ClientModel>(
                    context,
                    MaterialPageRoute(builder: (_) => const ClientFormScreen()),
                  );
                  if (newClient != null) {
                    widget.onClientSelected(newClient);
                    if (mounted) Navigator.pop(context);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Client List
          Expanded(
            child: clientProvider.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : clientProvider.clients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.people_outline_rounded, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 12),
                            const Text('No clients found', style: TextStyle(color: AppColors.textSecondary)),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () async {
                                final newClient = await Navigator.push<ClientModel>(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ClientFormScreen()),
                                );
                                if (newClient != null) {
                                  widget.onClientSelected(newClient);
                                  if (mounted) Navigator.pop(context);
                                }
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add New Customer'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: clientProvider.clients.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final client = clientProvider.clients[index];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.1),
                              child: Text(
                                client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                              ),
                            ),
                            title: Text(
                              client.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (client.gstin != null && client.gstin!.isNotEmpty)
                                  Text(
                                    'GSTIN: ${client.gstin}',
                                    style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
                                  ),
                                if (client.state != null && client.state!.isNotEmpty)
                                  Text(
                                    'Place of Supply: ${client.state}${client.stateCode != null ? " (${client.stateCode})" : ""}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                            onTap: () {
                              widget.onClientSelected(client);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
