import 'package:flutter/material.dart';
import 'api_service.dart';

const teal = Color(0xFF087F8C);
const darkTeal = Color(0xFF123047);
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
      scaffoldBackgroundColor: const Color(0xFFF6F8FA),
      appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF6F8FA)),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFD8E7E8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: teal, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
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
                Image.asset(
                  'assets/reliefroute_logo_mark.png',
                  height: 100,
                  fit: BoxFit.contain,
                  semanticLabel: 'ReliefRoute logo mark',
                ),
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
                        showMessage(context, 'Password reset service is unavailable.'),
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
                  'Your password is protected and is never displayed.',
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
                  Color(0xFF5EC6C5),
                  Color(0xFF087F8C),
                  Color(0xFF123047),
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x44087F8C),
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
            child: Icon(Icons.auto_awesome, color: Color(0xFFD9F2F1), size: 22),
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
                color: teal,
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
              showMessage(context, 'You have 2 new notifications.'),
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
              colors: [Color(0xFF35AEB0), darkTeal],
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
                    'Live tracking',
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
              const Color(0xFFE5F6F2),
            ),
            _QuickCard(
              'Reorder',
              Icons.refresh_rounded,
              const Color(0xFFD9F2F1),
            ),
            _QuickCard(
              'Reminders',
              Icons.alarm_outlined,
              const Color(0xFFDDEBF0),
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
              'Overview',
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
                  backgroundColor: Color(0xFFE5F6F2),
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
                  backgroundColor: Color(0xFFD9F2F1),
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
                      showMessage(context, 'Reorder request started.'),
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
          'View your benefit and eligibility summary',
          Icons.card_membership_outlined,
          const MedicalAidScreen(),
        ),
        _ServiceTile(
          'Find a doctor',
          'Explore providers and request an appointment',
          Icons.local_hospital_outlined,
          const DoctorDirectoryScreen(),
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 1) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogueScreen()));
        } else if (index == 2) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadPrescriptionScreen()));
        } else if (index == 3) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderTrackingScreen()));
        } else if (index == 4) {
          showMessage(context, 'Profile settings are available in the next release.');
        }
      },
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.storefront_outlined), label: 'Shop'),
        NavigationDestination(icon: Icon(Icons.upload_file_outlined), label: 'Upload'),
        NavigationDestination(icon: Icon(Icons.local_shipping_outlined), label: 'Orders'),
        NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    ),
  );
}

class UploadPrescriptionScreen extends StatelessWidget {
  const UploadPrescriptionScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Upload prescription')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Prescription services', style: TextStyle(fontSize: 12, color: teal, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Upload your prescription', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Send it securely so our pharmacy team can review it before your order is confirmed.', style: TextStyle(color: Colors.grey.shade700)),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: teal), color: Colors.white),
          child: Column(children: [
            const CircleAvatar(radius: 32, backgroundColor: Color(0xFFE5F6F2), child: Icon(Icons.upload_rounded, color: teal, size: 32)),
            const SizedBox(height: 14),
            const Text('Add prescription file', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('PDF, JPG or PNG up to 5 MB', style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 18),
            FilledButton(onPressed: () => showMessage(context, 'File picker will be connected to Firebase Storage.'), child: const Text('Choose a file')),
          ]),
        ),
        const SizedBox(height: 16),
        const DemoNote('Your information stays private. A pharmacist can access your prescription only to review your order.'),
        const SizedBox(height: 16),
        FilledButton(onPressed: () => showMessage(context, 'Prescription upload is ready for a file.'), child: const Text('Continue')),
      ],
    ),
  );
}

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Track your order')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Your orders', style: TextStyle(fontSize: 12, color: teal, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Track your order', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 18),
        Card(child: ListTile(leading: const Icon(Icons.local_shipping_outlined, color: teal), title: const Text('Order #RR-20481'), subtitle: const Text('Arriving today, 14:00–16:00'), trailing: Chip(label: Text('In transit')))),
        const SizedBox(height: 22),
        const Text('Delivery progress', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const _ProgressStep('Order confirmed', 'Your order has been received.', true),
        const _ProgressStep('Preparing your order', 'Pharmacy team is packing your items.', true),
        const _ProgressStep('On the way', 'Your rider is heading to you.', true),
        const _ProgressStep('Delivered', 'We will notify you when it arrives.', false),
        const SizedBox(height: 16),
        Card(color: const Color(0xFFE5F6F2), child: const ListTile(leading: CircleAvatar(child: Text('TB')), title: Text('Your delivery partner'), subtitle: Text('Thabo M. · Contact rider'))),
        OutlinedButton(onPressed: () => showMessage(context, 'Support request started.'), child: const Text('Need help with this order? Contact support')),
      ],
    ),
  );
}

class _ProgressStep extends StatelessWidget {
  final String title, detail;
  final bool complete;
  const _ProgressStep(this.title, this.detail, this.complete);
  @override
  Widget build(BuildContext context) => ListTile(
    leading: CircleAvatar(radius: 12, backgroundColor: complete ? teal : Colors.white, child: Icon(complete ? Icons.check : Icons.circle_outlined, size: 15, color: complete ? Colors.white : Colors.grey)),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    subtitle: Text(detail),
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
        backgroundColor: const Color(0xFFE5F6F2),
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
      onTap: () => showMessage(context, '$label opened.'),
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
                backgroundColor: Color(0xFFE5F6F2),
                child: Icon(Icons.medication_outlined, color: teal),
              ),
              title: Text(item),
              subtitle: const Text('Availability • prices shown in ZAR'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  showMessage(context, '$item details opened.'),
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
        const PageTitle('Medical aid benefits', 'Your benefits summary'),
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
                subtitle: Text('Member • **** 4821'),
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
                title: Text('Remaining balance'),
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
          'Available providers',
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
                backgroundColor: Color(0xFFD9F2F1),
                child: Icon(Icons.person_outline, color: teal),
              ),
              title: Text(doctor.split(' • ').first),
              subtitle: Text(
                '${doctor.split(' • ').last}\nProvider • Cape Town',
              ),
              isThreeLine: true,
              trailing: FilledButton(
                onPressed: () =>
                    showMessage(context, 'Appointment request submitted.'),
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
  final api = const ApiService();
  String category = 'All';
  bool loading = true;
  bool connected = false;
  final catalogue = <_FinderItem>[
    _FinderItem('Allergy Relief', 'Allergy', false),
    _FinderItem('Paracetamol 500mg', 'Pain relief', false),
    _FinderItem('Cough Calm Syrup', 'Cold & flu', false),
    _FinderItem('Amoxicillin 500mg', 'Prescription', true),
  ];

  @override
  void initState() {
    super.initState();
    _loadCatalogue();
  }

  Future<void> _loadCatalogue() async {
    try {
      final remote = await api.getMedicines();
      if (!mounted || remote.isEmpty) return;
      setState(() {
        catalogue.clear();
        for (final item in remote) {
          catalogue.add(_FinderItem(
            item['name'] as String? ?? 'Medicine',
            item['category'] as String? ?? 'Other',
            item['prescriptionRequired'] as bool? ?? false,
          ));
        }
        connected = true;
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

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
            'Search results come from the medicine catalogue. This information is not medical advice.',
          ),
          const SizedBox(height: 8),
          Text(
            loading
                ? 'Connecting to the backend...'
                : connected
                    ? 'Connected to the Spring Boot catalogue.'
                    : 'Connect to the service to refresh the catalogue.',
            style: TextStyle(
              color: connected ? Colors.green.shade700 : Colors.black54,
              fontSize: 12,
            ),
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
              title: 'No medicines found',
              message: 'Try a different term or category.',
            ),
          if (results.isNotEmpty)
            ...results.map(
              (item) => Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE5F6F2),
                    child: Icon(Icons.medication_outlined, color: teal),
                  ),
                  title: Text(item.name),
                  subtitle: Text(
                    item.prescriptionOnly
                        ? 'Prescription required • pharmacist review'
                        : item.category,
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
