import '../../models/business_model.dart';

abstract class IBusinessRepository {
  Future<BusinessModel?> getBusinessProfile();
  Future<int> saveBusinessProfile(BusinessModel business);
  Future<int> updateBusinessProfile(BusinessModel business);
}
