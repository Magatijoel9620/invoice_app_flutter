import '../models/business_profile.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/product.dart';

class CloudMapper {
  static Map<String, dynamic> business(BusinessProfile b, String userId) => {
    'id': b.id,
    'owner_id': userId,
    'data': b.toJson(),
    'updated_at': b.updatedAt.toUtc().toIso8601String(),
    'deleted_at': null,
  };

  static Map<String, dynamic> customer(Customer c, String userId, String businessId) => {
    'id': c.id,
    'owner_id': userId,
    'business_id': businessId,
    'data': c.toJson(),
    'updated_at': c.updatedAt.toUtc().toIso8601String(),
    'deleted_at': null,
  };

  static Map<String, dynamic> product(ProductItem p, String userId, String businessId) => {
    'id': p.id,
    'owner_id': userId,
    'business_id': businessId,
    'data': p.toJson(),
    'updated_at': p.updatedAt.toUtc().toIso8601String(),
    'deleted_at': null,
  };

  static Map<String, dynamic> invoice(Invoice i, String userId, String businessId) => {
    'id': i.id,
    'owner_id': userId,
    'business_id': businessId,
    'data': i.toJson(),
    'updated_at': i.updatedAt.toUtc().toIso8601String(),
    'deleted_at': null,
  };
}
