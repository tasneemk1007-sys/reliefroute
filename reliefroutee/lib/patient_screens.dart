import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'patient_data_service.dart';

final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
final _phonePattern = RegExp(r'^\d{7,15}$');
final _namePattern = RegExp(r"^[A-Za-z][A-Za-z '\-]*$");

String? _validEmail(String? value) => value != null && _emailPattern.hasMatch(value.trim()) ? null : 'Please enter a valid email address.';
String? _validPhone(String? value) => value != null && _phonePattern.hasMatch(value.trim()) ? null : 'Phone number must contain 7-15 digits only.';
String? _validName(String? value) => value != null && _namePattern.hasMatch(value.trim()) ? null : 'This field must contain letters only.';
String? _validMedicationName(String? value) => _validName(value) == null ? null : 'Medication name must contain letters only.';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});
  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final firstName = TextEditingController();
  final surname = TextEditingController();
  final username = TextEditingController();
  final email = TextEditingController();
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
        firstName.text = values['firstName'] as String? ?? '';
        surname.text = values['surname'] as String? ?? '';
        username.text = values['username'] as String? ?? '';
        email.text = values['email'] as String? ?? FirebaseAuth.instance.currentUser?.email ?? '';
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
    firstName.dispose(); surname.dispose(); username.dispose(); email.dispose();
    phone.dispose();
    address.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!_formKey.currentState!.validate()) return;
    if (firstName.text.trim().isEmpty || surname.text.trim().isEmpty) return;
    setState(() => saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && email.text.trim() != (user.email ?? '')) {
        await user.verifyBeforeUpdateEmail(email.text.trim());
      }
      await data.saveProfile({
        'firstName': firstName.text.trim(),
        'surname': surname.text.trim(),
        'username': username.text.trim(),
        'fullName': '${firstName.text.trim()} ${surname.text.trim()}',
        'email': email.text.trim(),
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
        : Form(
            key: _formKey,
            child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(controller: firstName, decoration: const InputDecoration(labelText: 'First name'), validator: _validName),
              const SizedBox(height: 14),
              TextFormField(controller: surname, decoration: const InputDecoration(labelText: 'Surname'), validator: _validName),
              const SizedBox(height: 14),
              TextFormField(controller: username, decoration: const InputDecoration(labelText: 'Username')),
              const SizedBox(height: 14),
              TextFormField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address'), validator: _validEmail),
              const SizedBox(height: 14),
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Phone number'),
                validator: _validPhone,
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
                validator: _validMedicationName,
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
