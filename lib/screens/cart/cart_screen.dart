import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:winsport/screens/home/ProductDetailPage.dart';

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:uuid/uuid.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void startRazorpayPayment(double amount) {
    var options = {
      'key': 'rzp_test_wV1SxU2CuQLFYL',
      'amount': (amount * 100).toInt(), // Razorpay works in paise
      'name': 'WinSport',
      'description': 'Cart Purchase',
      'prefill': {'contact': '9345471612', 'email': 'subashkaran912@gmail.com'},
      'theme': {'color': '#3399cc'},
      'method': ['upi'], // Restrict to UPI only
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Payment successful')));

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Fetch user name from Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userName = userDoc.data()?['name'] ?? 'UnknownUser';

    final cartDocs = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cart')
        .get();

    final DateTime now = DateTime.now();
    final formattedDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    double totalAmount = 0;
    final List<Map<String, dynamic>> items = [];

    for (var doc in cartDocs.docs) {
      final data = doc.data();
      final price = (data['price'] as num).toDouble();
      final quantity = (data['quantity'] as num).toInt();
      totalAmount += price * quantity;

      items.add({
        'productId': doc.id,
        'name': data['name'],
        'quantity': quantity,
        'price': price,
        'total': price * quantity,
      });
    }

    // Generate a unique invoice ID
    final invoiceId = const Uuid().v4();

    // Generate PDF
    final pdfData = await generatePdfInvoice(
      invoiceId: invoiceId,
      userEmail: user.email!,
      items: items,
      total: totalAmount,
      date: now,
    );

    // Create a file name like "UserName_YYYY-MM-DD.pdf"
    final fileName = '${userName}_$formattedDate.pdf';

    // Upload to Firebase Storage under folder named with userName
    final storageRef = FirebaseStorage.instance.ref().child(
      'invoices/${user.uid}/$fileName', // ✅ now it matches security rules
    );
    await storageRef.putData(pdfData);

    // Optionally store invoice metadata in Firestore
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('invoices')
        .doc(invoiceId)
        .set({
          'url': await storageRef.getDownloadURL(),
          'timestamp': now,
          'total': totalAmount,
          'invoiceId': invoiceId,
        });

    // Clear the cart
    for (var doc in cartDocs.docs) {
      await doc.reference.delete();
    }
  }

  Future<Uint8List> generatePdfInvoice({
    required String invoiceId,
    required String userEmail,
    required List<Map<String, dynamic>> items,
    required double total,
    required DateTime date,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('WinSport Invoice', style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 16),
            pw.Text('Invoice ID: $invoiceId'),
            pw.Text('Email: $userEmail'),
            pw.Text('Date: ${date.toLocal()}'),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ['Product ID', 'Item', 'Qty', 'Price', 'Total'],
              data: items.map((item) {
                return [
                  item['productId'],
                  item['name'],
                  item['quantity'].toString(),
                  '₹${item['price']}',
                  '₹${item['total']}',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellAlignment: pw.Alignment.centerLeft,
            ),
            pw.Divider(),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Total: ₹${total.toStringAsFixed(2)}',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}')),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External Wallet: ${response.walletName}')),
    );
  }

  Future<void> increaseQuantity(
    String userId,
    String productId,
    int currentQty,
  ) async {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(productId);
    await docRef.update({'quantity': currentQty + 1});
  }

  Future<void> decreaseQuantity(
    String userId,
    String productId,
    int currentQty,
  ) async {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(productId);

    if (currentQty > 1) {
      await docRef.update({'quantity': currentQty - 1});
    } else {
      await docRef.delete();
    }
  }

  Future<void> removeItem(String userId, String productId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart')
        .doc(productId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Your Cart')),
        body: const Center(child: Text('Please log in to view your cart')),
      );
    }

    final userId = user.uid;
    final cartCollection = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cart');

    return Scaffold(
      appBar: AppBar(title: const Text('Your Cart')),
      body: StreamBuilder<QuerySnapshot>(
        stream: cartCollection.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }

          final cartDocs = snapshot.data!.docs;

          double totalPrice = 0.0;

          for (var doc in cartDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final price = (data['price'] as num).toDouble();
            final quantity = (data['quantity'] as num).toInt();
            totalPrice += price * quantity;
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: cartDocs.length,
                  itemBuilder: (ctx, i) {
                    final doc = cartDocs[i];
                    final data = doc.data() as Map<String, dynamic>;

                    final productId = doc.id;
                    final name = data['name'] ?? '';
                    final imageUrl = data['imageUrl'] ?? '';
                    final price = (data['price'] as num).toDouble();
                    final quantity = (data['quantity'] as num).toInt();

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: ListTile(
                        leading: Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                        title: Text(name),
                        subtitle: Text('₹$price x $quantity'),
                        trailing: SizedBox(
                          width: 140,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => decreaseQuantity(
                                  userId,
                                  productId,
                                  quantity,
                                ),
                              ),
                              Text('$quantity'),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => increaseQuantity(
                                  userId,
                                  productId,
                                  quantity,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () => removeItem(userId, productId),
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailPage(
                                productId: productId,
                                name: name,
                                imageUrl: imageUrl,
                                price: price,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ₹${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => startRazorpayPayment(totalPrice),
                      child: const Text('Pay with Razorpay'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
