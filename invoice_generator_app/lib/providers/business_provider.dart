import 'package:flutter/material.dart';
import '../data/models/business_model.dart';
import '../data/repositories/interfaces/i_business_repository.dart';

class BusinessProvider extends ChangeNotifier {
  final IBusinessRepository _repository;

  BusinessModel? _business;
  bool _isLoading = false;

  BusinessProvider({required IBusinessRepository repository})
      : _repository = repository {
    loadBusiness();
  }

  BusinessModel? get business => _business;
  bool get isLoading => _isLoading;
  bool get hasBusiness => _business != null && _business!.businessName.trim().isNotEmpty;

  Future<void> loadBusiness() async {
    _isLoading = true;
    notifyListeners();

    try {
      _business = await _repository.getBusinessProfile();
    } catch (_) {
      _business = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveBusiness(BusinessModel businessModel) async {
    _isLoading = true;
    notifyListeners();

    try {
      final id = await _repository.saveBusinessProfile(businessModel);
      _business = businessModel.copyWith(id: id);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
