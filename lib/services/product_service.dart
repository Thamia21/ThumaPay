import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new product
  Future<String> createProduct(ProductModel product) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('products').add(product.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  // Get products for a vendor
  Stream<List<ProductModel>> getVendorProducts(String vendorId) {
    return _firestore
        .collection('products')
        .where('vendorId', isEqualTo: vendorId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Get product by barcode
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('products')
          .where('barcode', isEqualTo: barcode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return ProductModel.fromMap(snapshot.docs.first.id,
            snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get product by barcode: $e');
    }
  }

  // Update product
  Future<void> updateProduct(
      String productId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('products').doc(productId).update(updates);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  // Delete product (soft delete)
  Future<void> deleteProduct(String productId) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  // Update stock quantity
  Future<void> updateStockQuantity(String productId, int newQuantity) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'stockQuantity': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update stock quantity: $e');
    }
  }
}
