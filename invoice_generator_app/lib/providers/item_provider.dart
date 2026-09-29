import 'package:flutter/material.dart';
import '../data/models/item_model.dart';
import '../data/repositories/interfaces/i_item_repository.dart';

class ItemProvider extends ChangeNotifier {
  final IItemRepository _repository;

  List<ItemModel> _items = [];
  bool _isLoading = false;
  String _searchQuery = '';

  ItemProvider({required IItemRepository repository})
      : _repository = repository {
    loadItems();
  }

  List<ItemModel> get items => _items;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;

  Future<void> loadItems({String? query}) async {
    _isLoading = true;
    _searchQuery = query ?? '';
    notifyListeners();

    try {
      _items = await _repository.getItems(searchQuery: _searchQuery);
    } catch (_) {
      _items = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ItemModel?> addItem(ItemModel item) async {
    try {
      final id = await _repository.insertItem(item);
      final created = item.copyWith(id: id);
      await loadItems(query: _searchQuery);
      return created;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateItem(ItemModel item) async {
    try {
      await _repository.updateItem(item);
      await loadItems(query: _searchQuery);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteItem(int id) async {
    try {
      await _repository.deleteItem(id);
      await loadItems(query: _searchQuery);
      return true;
    } catch (_) {
      return false;
    }
  }
}
