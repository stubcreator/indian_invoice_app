import 'package:flutter/material.dart';
import '../data/models/client_model.dart';
import '../data/repositories/interfaces/i_client_repository.dart';

class ClientProvider extends ChangeNotifier {
  final IClientRepository _repository;

  List<ClientModel> _clients = [];
  bool _isLoading = false;
  String _searchQuery = '';
  int? _currentBusinessId;

  ClientProvider({required IClientRepository repository})
      : _repository = repository {
    loadClients();
  }

  List<ClientModel> get clients => _clients;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  int? get currentBusinessId => _currentBusinessId;

  void setBusinessId(int? id) {
    if (_currentBusinessId != id) {
      _currentBusinessId = id;
      loadClients();
    }
  }

  Future<void> loadClients({String? query, int? businessId}) async {
    _isLoading = true;
    if (query != null) _searchQuery = query;
    if (businessId != null) _currentBusinessId = businessId;
    notifyListeners();

    try {
      _clients = await _repository.getClients(
        searchQuery: _searchQuery,
        businessId: _currentBusinessId,
      );
    } catch (_) {
      _clients = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ClientModel?> addClient(ClientModel client) async {
    try {
      final clientWithBiz = client.businessId == null && _currentBusinessId != null
          ? client.copyWith(businessId: _currentBusinessId)
          : client;
      final id = await _repository.insertClient(clientWithBiz);
      final created = clientWithBiz.copyWith(id: id);
      await loadClients(query: _searchQuery);
      return created;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateClient(ClientModel client) async {
    try {
      await _repository.updateClient(client);
      await loadClients(query: _searchQuery);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteClient(int id) async {
    try {
      await _repository.deleteClient(id);
      await loadClients(query: _searchQuery);
      return true;
    } catch (_) {
      return false;
    }
  }
}
