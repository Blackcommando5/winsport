import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _logout(context);
    }
  }

  void _logout(BuildContext context) {
    // TODO: Replace with actual logout logic
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Logged out successfully')));

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _onCardTap(BuildContext context, String cardName) {
    switch (cardName) {
      case 'Product Management':
        Navigator.pushNamed(context, '/product_management');
        break;
      case 'Users':
        Navigator.pushNamed(context, '/users');
        break;
      case 'Payment Management':
        Navigator.pushNamed(context, '/payment_management');
        break;
      case 'Reports':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reports tapped')));
        break;
      case 'Settings':
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Settings tapped')));
        break;
    }
  }

  Widget _buildCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onCardTap(context, title),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc('Admin')
          .collection('Admin')
          .doc(user?.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            child: ListTile(
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.deepPurple,
                child: Icon(Icons.admin_panel_settings, color: Colors.white),
              ),
              title: Text('Loading...'),
              subtitle: Text('Loading...'),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.deepPurple,
                child: Icon(Icons.admin_panel_settings, color: Colors.white),
              ),
              title: const Text(
                'Admin',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Email not found'),
            ),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        final email = data?['Email'] ?? 'Email not set';
        final adminName = data?['Name'] ?? 'Admin Name';

        return InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/profile');
          },
          borderRadius: BorderRadius.circular(12),
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.deepPurple,
                child: Icon(Icons.admin_panel_settings, color: Colors.white),
              ),
              title: Text(
                adminName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(email),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      {
        'icon': Icons.production_quantity_limits,
        'title': 'Product Management',
        'color': Colors.deepPurple,
      },
      {'icon': Icons.people, 'title': 'Users', 'color': Colors.teal},
      {
        'icon': Icons.payment,
        'title': 'Payment Management',
        'color': Colors.orange,
      },
      {'icon': Icons.bar_chart, 'title': 'Reports', 'color': Colors.blue},
      {'icon': Icons.settings, 'title': 'Settings', 'color': Colors.grey},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            _buildProfileCard(context),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: cards
                    .map(
                      (card) => _buildCard(
                        context,
                        card['icon'] as IconData,
                        card['title'] as String,
                        card['color'] as Color,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
