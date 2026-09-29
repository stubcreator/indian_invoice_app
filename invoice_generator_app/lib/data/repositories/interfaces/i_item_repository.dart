import '../../models/item_model.dart';

abstract class IItemRepository {
  Future<List<ItemModel>> getItems({String? searchQuery});
  Future<ItemModel?> getItemById(int id);
  Future<int> insertItem(ItemModel item);
  Future<int> updateItem(ItemModel item);
  Future<int> deleteItem(int id);
}
