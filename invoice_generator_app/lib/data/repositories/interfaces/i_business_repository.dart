import '../../models/business_model.dart';

abstract class IBusinessRepository {
  Future<List<BusinessModel>> getAllBusinesses();
  Future<BusinessModel?> getBusinessById(int id);
  Future<BusinessModel?> getActiveBusiness();
  Future<int> createBusiness(BusinessModel business);
  Future<int> saveBusinessProfile(BusinessModel business);
  Future<int> updateBusinessProfile(BusinessModel business);
  Future<int> deleteBusiness(int id);
  Future<int?> getActiveBusinessId();
  Future<void> setActiveBusinessId(int businessId);
}
