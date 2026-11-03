import 'package:flutter/material.dart';

const teal = Color(0xFF8B5CF6);
const darkTeal = Color(0xFF4C1D95);
void main() => runApp(const ReliefRouteApp());

class ReliefRouteApp extends StatelessWidget {
  const ReliefRouteApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'ReliefRoute',
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: teal,
      scaffoldBackgroundColor: const Color(0xFFFCFAFF),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFFCFAFF)),
    ),
    home: const LoginScreen(),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final user = TextEditingController();
  final password = TextEditingController();
  bool hidden = true;

  @override
  void dispose() {
    user.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(26),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BrandLogo(),
                const Text(
                  'ReliefRoute',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Welcome to ReliefRoute',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('Sign in to manage your medicines and orders.'),
                const SizedBox(height: 24),
                TextFormField(
                  controller: user,
                  decoration: const InputDecoration(
                    labelText: 'Username or email',
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Enter your username.' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: password,
                  obscureText: hidden,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => hidden = !hidden),
                      icon: Icon(
                        hidden ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                  ),
                  validator: (v) => v == null || v.length < 4
                      ? 'Enter at least 4 characters.'
                      : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        showMessage(context, 'Password reset is simulated.'),
                    child: const Text('Forgot password?'),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => Dashboard(name: user.text),
                        ),
                      );
                    }
                  },
                  child: const Text('Log in'),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => showMessage(
                    context,
                    'Registration is ready for backend integration.',
                  ),
                  child: const Text('Create an account'),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Demo mode: no password is stored.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: SizedBox(
      width: 112,
      height: 112,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFD8B4FE),
                  Color(0xFF7C3AED),
                  Color(0xFF4C1D95),
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x448B5CF6),
                  blurRadius: 20,
                  offset: Offset(0, 9),
                ),
              ],
            ),
          ),
          Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .14),
              border: Border.all(
                color: Colors.white.withValues(alpha: .45),
                width: 1.5,
              ),
            ),
          ),
          const Icon(
            Icons.volunteer_activism_rounded,
            color: Colors.white,
            size: 52,
          ),
          const Positioned(
            right: 3,
            top: 5,
            child: Icon(Icons.auto_awesome, color: Color(0xFFFFE4F2), size: 22),
          ),
          const Positioned(
            left: 4,
            bottom: 11,
            child: Icon(
              Icons.favorite_rounded,
              color: Color(0xFFFFB7D5),
              size: 18,
            ),
          ),
          Positioned(
            right: 8,
            bottom: 7,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFF7C3AED),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class Dashboard extends StatelessWidget {
  final String name;
  const Dashboard({super.key, required this.name});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'ReliefRoute',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          onPressed: () =>
              showMessage(context, 'You have 2 new demo notifications.'),
          icon: const Badge(
            label: Text('2'),
            child: Icon(Icons.notifications_none),
          ),
        ),
        const SizedBox(width: 8),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: teal,
              child: Text(
                name.isEmpty ? 'R' : name.trim()[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${name.isEmpty ? 'there' : name}!',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Your healthcare journey, all in one place.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFA855F7), Color(0xFF4C1D95)],
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your next delivery',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 8),
              const Text(
                'Order #RR-24018',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Out for delivery',
                    style: TextStyle(color: Colors.white),
                  ),
                  const Spacer(),
                  Text(
                    'Demo tracking',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .75),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const TextField(
          decoration: InputDecoration(
            hintText: 'Search medicines, brands or categories',
            prefixIcon: Icon(Icons.search),
            suffixIcon: Icon(Icons.tune),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => showMessage(
            context,
            'Catalogue search is available from the Medicines section.',
          ),
          icon: const Icon(Icons.medication_outlined),
          label: const Text('Browse medicine catalogue'),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SmartAssistantScreen()),
          ),
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Medicine Finder'),
        ),
        const SizedBox(height: 24),
        const Text(
          'Quick actions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickCard(
              'Medicines',
              Icons.medication_outlined,
              const Color(0xFFF0E7FF),
            ),
            _QuickCard(
              'Reorder',
              Icons.refresh_rounded,
              const Color(0xFFFFE4F2),
            ),
            _QuickCard(
              'Reminders',
              Icons.alarm_outlined,
              const Color(0xFFE4E7FF),
            ),
            _QuickCard(
              'Support',
              Icons.support_agent_outlined,
              const Color(0xFFFFE5D5),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Text(
              'At a glance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              'Sample data',
              style: TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const _MetricCard('3', 'Active orders', Icons.inventory_2_outlined),
            const SizedBox(width: 10),
            const _MetricCard(
              '1',
              'Pending review',
              Icons.description_outlined,
            ),
            const SizedBox(width: 10),
            const _MetricCard(
              '2',
              'Reminders today',
              Icons.notifications_active_outlined,
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Recent activity',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF0E7FF),
                  child: Icon(Icons.check, color: teal),
                ),
                title: const Text('Prescription submitted'),
                subtitle: const Text('RX-1042 is awaiting pharmacist review'),
                trailing: Text(
                  'Today',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFE4F2),
                  child: Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.orange,
                  ),
                ),
                title: const Text('Quick reorder available'),
                subtitle: const Text(
                  'Vitamin C 1000mg from your last purchase',
                ),
                trailing: TextButton(
                  onPressed: () =>
                      showMessage(context, 'Reorder is simulated.'),
                  child: const Text('View'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Healthcare services',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _ServiceTile(
          'Medicine catalogue',
          'Browse products, categories and prices in ZAR',
          Icons.medication_outlined,
          const CatalogueScreen(),
        ),
        _ServiceTile(
          'Medical aid',
          'View a sample benefit and eligibility summary',
          Icons.card_membership_outlined,
          const MedicalAidScreen(),
        ),
        _ServiceTile(
          'Find a doctor',
          'Explore sample providers and request a demo appointment',
          Icons.local_hospital_outlined,
          const DoctorDirectoryScreen(),
        ),
      ],
    ),
  );
}

class _ServiceTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final Widget destination;
  const _ServiceTile(this.title, this.subtitle, this.icon, this.destination);
  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFF0E7FF),
        child: Icon(icon, color: teal),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destination),
      ),
    ),
  );
}

class _QuickCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _QuickCard(this.label, this.icon, this.color);
  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: () => showMessage(context, '$label demo view opened.'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(right: 7),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 5),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: teal),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ),
  );
}

class _MetricCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  const _MetricCard(this.value, this.label, this.icon);
  @override
  Widget build(BuildContext context) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: teal, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: darkTeal,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    ),
  );
}

class CatalogueScreen extends StatelessWidget {
  const CatalogueScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Medicine catalogue')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const TextField(
          decoration: InputDecoration(
            labelText: 'Search medicines',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
        ...[
          'Paracetamol 500mg',
          'Allergy Relief',
          'Vitamin C 1000mg',
          'Cough Calm Syrup',
        ].map(
          (item) => Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFF0E7FF),
                child: Icon(Icons.medication_outlined, color: teal),
              ),
              title: Text(item),
              subtitle: const Text('Demo availability • prices shown in ZAR'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  showMessage(context, '$item details opened in demo.'),
            ),
          ),
        ),
      ],
    ),
  );
}

class MedicalAidScreen extends StatelessWidget {
  const MedicalAidScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Medical aid')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageTitle('Medical aid benefits', 'Frontend demonstration only'),
        const DemoNote(
          'ReliefRoute cannot verify membership, benefits or claim eligibility. Connect an authorised medical-aid service for real information.',
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.card_membership_outlined, color: teal),
                title: Text('SampleCare Medical Aid'),
                subtitle: Text('Demo member • **** 4821'),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Medicine benefit'),
                trailing: Text(
                  'R1,250.00',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: darkTeal,
                  ),
                ),
              ),
              const ListTile(
                title: Text('Remaining demonstration balance'),
                trailing: Text('R860.00'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => showMessage(
            context,
            'Benefit verification requires backend integration.',
          ),
          icon: const Icon(Icons.verified_outlined),
          label: const Text('Check eligibility'),
        ),
      ],
    ),
  );
}

class DoctorDirectoryScreen extends StatelessWidget {
  const DoctorDirectoryScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Find a doctor')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageTitle(
          'Sample providers',
          'Availability and bookings are not live',
        ),
        const TextField(
          decoration: InputDecoration(
            labelText: 'Search by specialty or location',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 16),
        ...[
          'Dr. Naledi Mokoena • General practitioner',
          'Dr. Liam Naidoo • Family medicine',
          'Dr. Amara Jacobs • Paediatrics',
        ].map(
          (doctor) => Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFFE4F2),
                child: Icon(Icons.person_outline, color: teal),
              ),
              title: Text(doctor.split(' • ').first),
              subtitle: Text(
                '${doctor.split(' • ').last}\nSample provider • Cape Town',
              ),
              isThreeLine: true,
              trailing: FilledButton(
                onPressed: () =>
                    showMessage(context, 'Appointment request simulated.'),
                child: const Text('Request'),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class PageTitle extends StatelessWidget {
  final String title, subtitle;
  const PageTitle(this.title, this.subtitle, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    ),
  );
}

class DemoNote extends StatelessWidget {
  final String text;
  const DemoNote(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF5E8),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 19),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title, message;
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 42),
    child: Column(
      children: [
        Icon(icon, size: 52, color: Colors.black38),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    ),
  );
}

class SmartAssistantScreen extends StatefulWidget {
  const SmartAssistantScreen({super.key});
  @override
  State<SmartAssistantScreen> createState() => _SmartAssistantState();
}

class _SmartAssistantState extends State<SmartAssistantScreen> {
  final search = TextEditingController();
  String category = 'All';
  final catalogue = const [
    _FinderItem('Allergy Relief', 'Allergy', false),
    _FinderItem('Paracetamol 500mg', 'Pain relief', false),
    _FinderItem('Cough Calm Syrup', 'Cold & flu', false),
    _FinderItem('Amoxicillin 500mg', 'Prescription', true),
  ];

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = catalogue
        .where(
          (item) =>
              (category == 'All' || item.category == category) &&
              item.name.toLowerCase().contains(search.text.toLowerCase()),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Finder')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const DemoNote(
            'Search results come from the local catalogue. This is a demonstration and not medical advice.',
          ),
          const SizedBox(height: 18),
          TextField(
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'What are you looking for?',
              hintText: 'Try “allergy” or “pain”',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children:
                ['All', 'Allergy', 'Pain relief', 'Cold & flu', 'Prescription']
                    .map(
                      (item) => ChoiceChip(
                        label: Text(item),
                        selected: category == item,
                        onSelected: (_) => setState(() => category = item),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Suggested searches',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['allergy', 'pain relief', 'cold and flu']
                .map(
                  (item) => ActionChip(
                    label: Text(item),
                    onPressed: () {
                      search.text = item;
                      setState(() {});
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 22),
          if (results.isEmpty)
            const EmptyState(
              icon: Icons.search_off,
              title: 'No demonstration matches',
              message: 'Try a different term or category.',
            ),
          if (results.isNotEmpty)
            ...results.map(
              (item) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF0E7FF),
                    child: Icon(Icons.medication_outlined, color: teal),
                  ),
                  title: Text(item.name),
                  subtitle: Text(
                    item.prescriptionOnly
                        ? 'Prescription required • pharmacist review'
                        : '${item.category} • demonstration result',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showMessage(
                    context,
                    'Open product details from the connected catalogue.',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FinderItem {
  final String name, category;
  final bool prescriptionOnly;
  const _FinderItem(this.name, this.category, this.prescriptionOnly);
}

void showMessage(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
