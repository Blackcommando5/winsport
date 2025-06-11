import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _orderEmailController = TextEditingController();

  String adminName =
      'Admin'; // You can expand to fetch/display full profile later.
  String? adminEmail;
  String? orderEmail;

  @override
  void initState() {
    super.initState();
    fetchAndStoreAdminData();
  }

  Future<void> fetchAndStoreAdminData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Fetch existing order email if any
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('users')
            .doc('Admin')
            .collection('Admin')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            adminEmail = user.email;
            orderEmail = data['OrderEmail'] ?? '';
            _orderEmailController.text = orderEmail ?? '';
          });
        } else {
          setState(() {
            adminEmail = user.email;
          });
        }

        // Save the base user email and UID if not saved
        await FirebaseFirestore.instance
            .collection('users')
            .doc('Admin')
            .collection('Admin')
            .doc(user.uid)
            .set({
              'Email': user.email,
              'UID': user.uid,
              'Timestamp': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('Error fetching admin data: $e');
    }
  }

  Future<void> saveOrderEmail() async {
    if (_formKey.currentState!.validate()) {
      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          String newOrderEmail = _orderEmailController.text.trim();

          await FirebaseFirestore.instance
              .collection('users')
              .doc('Admin')
              .collection('Admin')
              .doc(user.uid)
              .set({
                'OrderEmail': newOrderEmail,
                'Timestamp': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));

          setState(() {
            orderEmail = newOrderEmail;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order Email updated successfully!')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update Order Email: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _orderEmailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Profile'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.deepPurple,
              child: Icon(
                Icons.admin_panel_settings,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              adminName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              adminEmail ?? 'Loading...',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),

            Form(
              key: _formKey,
              child: TextFormField(
                controller: _orderEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Order Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an order email';
                  }
                  final emailRegex = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  if (!emailRegex.hasMatch(value)) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save Order Email'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 40),
              ),
              onPressed: saveOrderEmail,
            ),

            const SizedBox(height: 30),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: const Text('Change Password'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Change Password clicked')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit Profile clicked')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('App Info'),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'WinSport',
                  applicationVersion: '1.0.0',
                  applicationLegalese: '© 2025 BlackCommando Inc.',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
