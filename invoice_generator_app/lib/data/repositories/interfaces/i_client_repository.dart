import '../../models/client_model.dart';

abstract class IClientRepository {
  Future<List<ClientModel>> getClients({String? searchQuery});
  Future<ClientModel?> getClientById(int id);
  Future<int> insertClient(ClientModel client);
  Future<int> updateClient(ClientModel client);
  Future<int> deleteClient(int id);
}
