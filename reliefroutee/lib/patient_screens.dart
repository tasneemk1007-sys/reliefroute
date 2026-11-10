import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'patient_data_service.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});
  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  bool loading = true;
  bool saving = false;
  late final PatientDataService data;

  @override
  void initState() {
    super.initState();
    data = PatientDataService();
    data.watchProfile().listen(
      (snapshot) {
        if (!mounted) return;
        final values = snapshot.data() ?? {};
        name.text = values['fullName'] as String? ?? '';
        phone.text = values['phone'] as String? ?? '';
        address.text = values['address'] as String? ?? '';
        setState(() => loading = false);
      },
      onError: (_) {
        if (mounted) setState(() => loading = false);
      },
    );
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    address.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) return;
    setState(() => saving = true);
    try {
      await data.saveProfile({
        'fullName': name.text.trim(),
        'phone': phone.text.trim(),
        'address': address.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile saved.')));
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Could not save profile.')),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My profile')),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number'),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: address,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 22),
              FilledButton(
                onPressed: saving ? null : save,
                child: Text(saving ? 'Saving...' : 'Save profile'),
              ),
            ],
          ),
  );
}

class MedicationsScreen extends StatelessWidget {
  const MedicationsScreen({super.key});

  Future<void> add(BuildContext context) async {
    final medicine = TextEditingController();
    final dosage = TextEditingController();
    final form = GlobalKey<FormState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add medication'),
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: medicine,
                decoration: const InputDecoration(labelText: 'Medication name'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: dosage,
                decoration: const InputDecoration(
                  labelText: 'Dosage and frequency',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) Navigator.pop(context, true);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await PatientDataService().addMedication({
        'name': medicine.text.trim(),
        'dosage': dosage.text.trim(),
        'status': 'active',
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My medications'),
      actions: [
        IconButton(onPressed: () => add(context), icon: const Icon(Icons.add)),
      ],
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: PatientDataService().watchMedications(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load medications.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const EmptyPatientState(message: 'No medications added yet.');
        }
        return ListView(
          children: docs
              .map(
                (doc) => ListTile(
                  title: Text(doc.data()['name'] as String? ?? 'Medication'),
                  subtitle: Text(doc.data()['dosage'] as String? ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => doc.reference.delete(),
                  ),
                ),
              )
              .toList(),
        );
      },
    ),
  );
}

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  Future<void> add(BuildContext context) async {
    final provider = TextEditingController();
    final date = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request appointment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: provider,
              decoration: const InputDecoration(
                labelText: 'Healthcare provider',
              ),
            ),
            TextField(
              controller: date,
              decoration: const InputDecoration(labelText: 'Date and time'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Request'),
          ),
        ],
      ),
    );
    if (confirmed == true && provider.text.trim().isNotEmpty) {
      await PatientDataService().addAppointment({
        'provider': provider.text.trim(),
        'dateTime': date.text.trim(),
        'type': 'consultation',
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Appointments'),
      actions: [
        IconButton(onPressed: () => add(context), icon: const Icon(Icons.add)),
      ],
    ),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: PatientDataService().watchAppointments(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Could not load appointments.'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const EmptyPatientState(
            message: 'No appointments requested yet.',
          );
        }
        return ListView(
          children: docs
              .map(
                (doc) => ListTile(
                  title: Text(doc.data()['provider'] as String? ?? 'Provider'),
                  subtitle: Text(
                    '${doc.data()['dateTime'] ?? ''} • ${doc.data()['status'] ?? 'requested'}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.cancel_outlined),
                    onPressed: () =>
                        PatientDataService().cancelAppointment(doc.id),
                  ),
                ),
              )
              .toList(),
        );
      },
    ),
  );
}

class EmptyPatientState extends StatelessWidget {
  final String message;
  const EmptyPatientState({required this.message, super.key});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}
