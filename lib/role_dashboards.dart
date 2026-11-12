import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'driver_tracking.dart';

const teal = Color(0xFF087F8C);

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key, this.auth});
  final FirebaseAuth? auth;
  @override State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  final order = TextEditingController();
  final publisher = DriverLocationPublisher();
  bool sharing = false;

  @override
  void dispose() { order.dispose(); publisher.stop(); super.dispose(); }

  Future<void> toggleSharing() async {
    if (order.text.trim().isEmpty) return;
    try {
      if (sharing) { await publisher.stop(); } else { await publisher.start(order.text.trim()); }
      if (mounted) setState(() => sharing = !sharing);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Driver dashboard'), actions: [
      IconButton(onPressed: () => (widget.auth ?? FirebaseAuth.instance).signOut(), icon: const Icon(Icons.logout)),
    ]),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Delivery control centre', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('Share your live location only while carrying an assigned order.'),
      const SizedBox(height: 20),
      TextField(controller: order, decoration: const InputDecoration(labelText: 'Assigned order reference')),
      const SizedBox(height: 12),
      FilledButton.icon(onPressed: toggleSharing, icon: Icon(sharing ? Icons.stop : Icons.location_on), label: Text(sharing ? 'Stop sharing location' : 'Start delivery tracking')),
      if (sharing) const Card(child: ListTile(leading: Icon(Icons.circle, color: Colors.green), title: Text('Location sharing is active'), subtitle: Text('The customer can now see your position.'))),
    ]),
  );
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key, this.auth});
  final FirebaseAuth? auth;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin dashboard'), actions: [
      IconButton(onPressed: () => (auth ?? FirebaseAuth.instance).signOut(), icon: const Icon(Icons.logout)),
    ]),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Operations overview', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      const SizedBox(height: 16),
      const _AdminCard(Icons.people_outline, 'Users', 'Manage patient and driver access.'),
      const _AdminCard(Icons.medication_outlined, 'Medicine catalogue', 'Review medicines and stock.'),
      const _AdminCard(Icons.local_shipping_outlined, 'Deliveries', 'Assign drivers and monitor active orders.'),
      const _AdminCard(Icons.security_outlined, 'Firebase roles', 'Roles are controlled through Firebase custom claims.'),
    ]),
  );
}

class _AdminCard extends StatelessWidget {
  const _AdminCard(this.icon, this.title, this.detail);
  final IconData icon; final String title, detail;
  @override Widget build(BuildContext context) => Card(child: ListTile(leading: Icon(icon, color: teal), title: Text(title), subtitle: Text(detail), trailing: const Icon(Icons.chevron_right)));
}
