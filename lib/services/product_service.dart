import 'package:cloud_firestore/cloud_firestore.dart';

class ProductService {
  final _productRef = FirebaseFirestore.instance.collection('products');

  Future<List<Map<String, dynamic>>> getProductsByCategory(
    String category,
  ) async {
    final snapshot = await _productRef
        .where('category', isEqualTo: category)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Attach the document ID for reference
      return data;
    }).toList();
  }
}
