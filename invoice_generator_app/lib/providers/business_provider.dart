import 'package:flutter/material.dart';
import '../data/models/business_model.dart';
import '../data/repositories/interfaces/i_business_repository.dart';

class BusinessProvider extends ChangeNotifier {
  final IBusinessRepository _repository;

  List<BusinessModel> _businesses = [];
  BusinessModel? _activeBusiness;
  bool _isLoading = false;

  BusinessProvider({required IBusinessRepository repository})
      : _repository = repository {
    loadBusinesses();
  }

  List<BusinessModel> get businesses => _businesses;
  BusinessModel? get activeBusiness => _activeBusiness;
  BusinessModel? get business => _activeBusiness; // Compatibility alias
  bool get isLoading => _isLoading;
  bool get hasBusiness => _activeBusiness != null && _activeBusiness!.businessName.trim().isNotEmpty;

  Future<void> loadBusinesses() async {
    _isLoading = true;
    notifyListeners();

    try {
      _businesses = await _repository.getAllBusinesses();
      _activeBusiness = await _repository.getActiveBusiness();
    } catch (_) {
      _businesses = [];
      _activeBusiness = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Compatibility alias
  Future<void> loadBusiness() async => await loadBusinesses();

  Future<void> selectBusiness(BusinessModel biz) async {
    if (biz.id != null) {
      await _repository.setActiveBusinessId(biz.id!);
      _activeBusiness = biz;
      notifyListeners();
    }
  }

  Future<int?> createBusiness(BusinessModel biz) async {
    _isLoading = true;
    notifyListeners();

    try {
      final id = await _repository.createBusiness(biz);
      await loadBusinesses();
      // Select newly created business
      final created = _businesses.firstWhere((b) => b.id == id, orElse: () => biz.copyWith(id: id));
      await selectBusiness(created);
      return id;
    } catch (_) {
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateBusiness(BusinessModel biz) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.updateBusinessProfile(biz);
      await loadBusinesses();
      if (_activeBusiness?.id == biz.id) {
        _activeBusiness = biz;
      }
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveBusiness(BusinessModel businessModel) async {
    if (businessModel.id != null) {
      return await updateBusiness(businessModel);
    } else {
      final id = await createBusiness(businessModel);
      return id != null;
    }
  }

  Future<bool> deleteBusiness(int id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.deleteBusiness(id);
      await loadBusinesses();
      return true;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
