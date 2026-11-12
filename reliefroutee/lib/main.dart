import 'package:flutter/material.dart';

import 'api_service.dart';
import 'driver_tracking.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';

import 'firebase_options.dart';
import 'patient_screens.dart';
import 'patient_data_service.dart';
import 'role_dashboards.dart';
import 'live_cart_service.dart';
import 'models.dart';

import 'package:url_launcher/url_launcher.dart';

const teal = Color(0xFF087F8C);
const darkTeal = Color(0xFF123047);
final liveCart = LiveCartService();
bool _firebaseReady = false;

double _money(Object? value) => value is num
    ? value.toDouble()
    : double.tryParse('$value') ?? 0;

int _stock(Object? value) => value is num
    ? value.toInt()
    : int.tryParse('$value') ?? 0;

Medicine _cartMedicine(String id, Map<String, dynamic> data) => Medicine(
  id: id,
  name: '${data['name'] ?? 'Medicine'}',
  description: '${data['description'] ?? ''}',
  category: '${data['category'] ?? 'Other'}',
  price: _money(data['price']),
  prescriptionOnly: data['prescription_required'] == true ||
      data['prescriptionRequired'] == true,
  available: data['active'] != false && _stock(data['stock_quantity']) > 0,
  stockQuantity: _stock(data['stock_quantity']),
);

String _zar(double value) => 'R${value.toStringAsFixed(2)}';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  _firebaseReady = true;
  runApp(const ReliefRouteApp());
}

class ReliefRouteApp extends StatelessWidget {
  const ReliefRouteApp({super.key, this.auth});

  final FirebaseAuth? auth;
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
    home: AuthGate(auth: auth),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.auth});

  final FirebaseAuth? auth;

  @override
  Widget build(BuildContext context) => StreamBuilder<User?>(
    stream: (auth ?? FirebaseAuth.instance).authStateChanges(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final user = snapshot.data;
      if (user == null) return LoginScreen(auth: auth);
      return FutureBuilder<IdTokenResult>(
        future: user.getIdTokenResult(true),
        builder: (context, claims) {
          if (!claims.hasData) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final role = claims.data!.claims?['role'] as String? ?? 'patient';
          if (role == 'admin') return AdminDashboard(auth: auth);
          if (role == 'driver') return DriverDashboard(auth: auth);
          return Dashboard(name: user.displayName ?? user.email ?? 'Patient', auth: auth);
        },
      );
    },
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.auth});

  final FirebaseAuth? auth;
  @override
  State<LoginScreen> createState() => _LoginState();
}

class _LoginState extends State<LoginScreen> {
  final formKey = GlobalKey<FormState>();
  final user = TextEditingController();
  final password = TextEditingController();
  bool hidden = true;
  bool busy = false;
  FirebaseAuth get auth => widget.auth ?? FirebaseAuth.instance;

  static final _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty || !_emailPattern.hasMatch(email)) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  String _firebaseMessage(
    FirebaseAuthException error, {
    bool registering = false,
  }) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-not-found':
        return registering
            ? 'No account was found. Please create an account first.'
            : 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Try logging in.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'network-request-failed':
        return 'Please check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return registering
            ? 'We could not create your account. Please try again.'
            : 'We could not sign you in. Please try again.';
    }
  }

  Future<Map<String, dynamic>> _signInWithFirebase(
    String email,
    String password,
  ) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('We could not sign you in. Please try again.');
    }
    return {
      'id': firebaseUser.uid,
      'name': firebaseUser.displayName ?? firebaseUser.email ?? email,
    };
  }

  Future<void> _resetPassword() async {
    if (_validateEmail(user.text) != null) {
      showMessage(context, 'Please enter a valid email address.');
      return;
    }
    try {
      await auth.sendPasswordResetEmail(email: user.text.trim());
      if (mounted) showMessage(context, 'Password reset email sent.');
    } on FirebaseAuthException catch (e) {
      if (mounted) showMessage(context, _firebaseMessage(e));
    }
  }

  @override
  void dispose() {
    user.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    resizeToAvoidBottomInset: true,
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            26,
            26,
            26,
            26 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/reliefroute_brand_logo.png',
                    height: 170,
                    fit: BoxFit.contain,
                    semanticLabel: 'ReliefRoute — Healthcare, closer to you',
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
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                    ),
                    validator: _validateEmail,
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
                    textInputAction: TextInputAction.done,
                    validator: (v) => v == null || v.length < 6
                        ? 'Enter at least 6 characters.'
                        : null,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () async {
                            if (formKey.currentState!.validate()) {
                              setState(() => busy = true);
                              try {
                                final account = await _signInWithFirebase(
                                  user.text,
                                  password.text,
                                );
                                if (!context.mounted) return;
                                final navigator = Navigator.of(context);
                                navigator.pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => Dashboard(
                                      name:
                                          account['name'] as String? ??
                                          user.text,
                                      auth: widget.auth,
                                    ),
                                  ),
                                );
                              } on FirebaseAuthException catch (e) {
                                if (context.mounted) {
                                  showMessage(context, _firebaseMessage(e));
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  showMessage(
                                    context,
                                    'We could not sign you in. Please try again.',
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => busy = false);
                                }
                              }
                            }
                          },
                    child: Text(busy ? 'Signing in...' : 'Log in'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegistrationScreen(auth: widget.auth),
                      ),
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
    ),
  );
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key, this.auth});

  final FirebaseAuth? auth;

  @override
  State<RegistrationScreen> createState() => _RegistrationState();
}

class _RegistrationState extends State<RegistrationScreen> {
  final formKey = GlobalKey<FormState>();
  final username = TextEditingController();
  final firstName = TextEditingController();
  final surname = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  bool hidden = true;
  bool busy = false;

  FirebaseAuth get auth => widget.auth ?? FirebaseAuth.instance;

  String? requiredValue(String? value, String label) =>
      value == null || value.trim().isEmpty ? '$label is required.' : null;

  String? validEmail(String? value) {
    final valueError = requiredValue(value, 'Email address');
    if (valueError != null) return valueError;
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value!.trim())
        ? null
        : 'Please enter a valid email address.';
  }

  String? validPassword(String? value) => value == null || value.length < 6
      ? 'Password must be at least 6 characters.'
      : null;

  Future<void> register() async {
    if (busy || !formKey.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );
      final firebaseUser = credential.user;
      if (firebaseUser == null) throw StateError('Account creation failed.');
      final fullName = '${firstName.text.trim()} ${surname.text.trim()}';
      await firebaseUser.updateDisplayName(fullName);
      await PatientDataService(auth: auth).saveProfile({
        'username': username.text.trim(),
        'firstName': firstName.text.trim(),
        'surname': surname.text.trim(),
        'fullName': fullName,
        'email': firebaseUser.email ?? email.text.trim(),
        'role': 'patient',
      });
      await firebaseUser.sendEmailVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created. Verify your email before signing in.',
          ),
        ),
      );
      Navigator.pop(context);
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Registration failed.')),
        );
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error.message ?? 'The patient profile could not be saved.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    username.dispose();
    firstName.dispose();
    surname.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Create your account')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(26),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join ReliefRoute',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create your patient account to manage your healthcare.',
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: username,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (v) => requiredValue(v, 'Username'),
                  autocorrect: false,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: firstName,
                  decoration: const InputDecoration(labelText: 'First name'),
                  validator: (v) => requiredValue(v, 'First name'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: surname,
                  decoration: const InputDecoration(labelText: 'Surname'),
                  validator: (v) => requiredValue(v, 'Surname'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email address'),
                  validator: validEmail,
                  autocorrect: false,
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
                  validator: validPassword,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: confirmPassword,
                  obscureText: hidden,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                  ),
                  validator: (v) =>
                      v != password.text ? 'Passwords do not match.' : null,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: busy ? null : register,
                  child: Text(busy ? 'Creating account...' : 'Create account'),
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
              child: const Icon(Icons.add_rounded, color: teal, size: 22),
            ),
          ),
        ],
      ),
    ),
  );
}

class Dashboard extends StatelessWidget {
  final String name;
  final FirebaseAuth? auth;
  const Dashboard({super.key, required this.name, this.auth});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'ReliefRoute',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        _CartButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        ),
        IconButton(
          onPressed: () =>
              showMessage(context, 'You have 2 new notifications.'),
          icon: const Badge(
            label: Text('2'),
            child: Icon(Icons.notifications_none),
          ),
        ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: () async {
            await (auth ?? FirebaseAuth.instance).signOut();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            }
          },
          icon: const Icon(Icons.logout),
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
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CatalogueScreen())),
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
          'Find a pharmacy',
          'Open nearby pharmacies and contact details',
          Icons.local_pharmacy_outlined,
          const PharmacyDirectoryScreen(),
        ),
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
        _ServiceTile(
          'My medications',
          'Manage your current medicines and dosage instructions',
          Icons.medication_outlined,
          const MedicationsScreen(),
        ),
        _ServiceTile(
          'Appointments',
          'Request and manage your healthcare appointments',
          Icons.calendar_month_outlined,
          const AppointmentsScreen(),
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CatalogueScreen()),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UploadPrescriptionScreen()),
          );
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const OrderTrackingScreen()),
          );
        } else if (index == 4) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PatientProfileScreen()),
          );
        } else if (index == 5) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ComingSoonTabsScreen()),
          );
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          label: 'Shop',
        ),
        NavigationDestination(
          icon: Icon(Icons.upload_file_outlined),
          label: 'Upload',
        ),
        NavigationDestination(
          icon: Icon(Icons.local_shipping_outlined),
          label: 'Orders',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
        NavigationDestination(
          icon: Icon(Icons.more_horiz),
          label: 'More',
        ),
      ],
    ),
  );
}

class ComingSoonTabsScreen extends StatelessWidget {
  const ComingSoonTabsScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Coming soon'),
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(icon: Icon(Icons.payment_outlined), text: 'Payments'),
            Tab(icon: Icon(Icons.my_location_outlined), text: 'Live tracking'),
            Tab(icon: Icon(Icons.fact_check_outlined), text: 'Prescription review'),
          ],
        ),
      ),
      body: const TabBarView(
        children: [
          _ComingSoonFeature(
            icon: Icons.payment_outlined,
            title: 'Payments',
            message: 'Secure in-app payment options are coming soon.',
          ),
          _ComingSoonFeature(
            icon: Icons.my_location_outlined,
            title: 'Live delivery tracking',
            message: 'Real-time driver location and delivery progress are coming soon.',
          ),
          _ComingSoonFeature(
            icon: Icons.fact_check_outlined,
            title: 'Prescription review',
            message: 'Pharmacist review and approval of prescription orders are coming soon.',
          ),
        ],
      ),
    ),
  );
}

class _ComingSoonFeature extends StatelessWidget {
  const _ComingSoonFeature({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 56, color: teal),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Chip(label: Text('Coming soon')),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class UploadPrescriptionScreen extends StatefulWidget {
  const UploadPrescriptionScreen({super.key});

  @override
  State<UploadPrescriptionScreen> createState() => _UploadPrescriptionState();
}

class _UploadPrescriptionState extends State<UploadPrescriptionScreen> {
  PlatformFile? selected;
  bool busy = false;

  Future<void> chooseFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (!mounted || result.isEmpty) return;
    final file = result.single;
    final size = await file.length();
    if (!mounted) return;
    if (size != null && size > 5 * 1024 * 1024) {
      showMessage(context, 'The file must be 5 MB or smaller.');
      return;
    }
    setState(() => selected = file);
  }

  Future<void> upload() async {
    final file = selected;
    final user = FirebaseAuth.instance.currentUser;
    if (file == null) {
      showMessage(context, 'Choose a prescription file first.');
      return;
    }
    if (user == null) {
      showMessage(context, 'Sign in before uploading a prescription.');
      return;
    }
    setState(() => busy = true);
    try {
      final path =
          'prescriptions/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${file.name}';
      final ref = FirebaseStorage.instance.ref(path);
      await ref.putData(
        await file.readAsBytes(),
        SettableMetadata(contentType: file.extension),
      );
      await PatientDataService().addPrescriptionMetadata(
        fileName: file.name,
        storagePath: path,
      );
      if (!mounted) return;
      setState(() => selected = null);
      if (mounted) showMessage(context, 'Prescription uploaded for review.');
    } on FirebaseException catch (e) {
      if (mounted) showMessage(context, e.message ?? 'Upload failed.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Upload prescription')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Prescription services',
          style: TextStyle(
            fontSize: 12,
            color: teal,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Prescription uploads are coming soon',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Secure prescription file uploads are temporarily unavailable while storage is being configured.',
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 28),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: teal),
            color: Colors.white,
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFFE5F6F2),
                child: Icon(Icons.upload_rounded, color: teal, size: 32),
              ),
              const SizedBox(height: 14),
              const Text(
                'Coming soon',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'File uploads will be enabled in a future release.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 18),
              FilledButton(onPressed: null, child: const Text('Coming soon')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const DemoNote(
          'You can still manage medicines and appointments while prescription uploads are unavailable.',
        ),
        const SizedBox(height: 16),
        FilledButton(onPressed: null, child: const Text('Uploads unavailable')),
      ],
    ),
  );
}

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});
  @override State<OrderTrackingScreen> createState() => _OrderTrackingState();
}
class _OrderTrackingState extends State<OrderTrackingScreen> {
  final reference = TextEditingController();
  final api = const ApiService();
  Map<String, dynamic>? order;
  bool loading = false;
  Future<void> track() async {
    if (reference.text.trim().isEmpty) return;
    setState(() => loading = true);
    try { final result = await api.getOrderTracking(reference.text.trim()); if (mounted) setState(() => order = result); }
    catch (_) { if (mounted) showMessage(context, 'Order not found. Check the reference and try again.'); }
    if (mounted) setState(() => loading = false);
  }
  @override void dispose() { reference.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Track your order')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Live or manual tracking',
          style: TextStyle(
            fontSize: 12,
            color: teal,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Track your order',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 18),
        TextField(controller: reference, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(labelText: 'Order reference', hintText: 'e.g. RR-AB12CD34', suffixIcon: IconButton(onPressed: loading ? null : track, icon: const Icon(Icons.search)))),
        const SizedBox(height: 10),
        FilledButton.icon(onPressed: loading ? null : track, icon: const Icon(Icons.search), label: Text(loading ? 'Looking up...' : 'View order status')),
        if (order?['reference'] != null)
          OpenStreetMapTracking(orderId: '${order!['reference']}'),
        Card(
          child: ListTile(
            leading: const Icon(Icons.local_shipping_outlined, color: teal),
            title: Text('Order #${order?['reference'] ?? reference.text.trim()}'),
            subtitle: Text(order == null ? 'Enter an order reference to see its status.' : 'Status from your order'),
            trailing: Chip(label: Text('${order?['status'] ?? 'Enter a reference'}')),
          ),
        ),
        if (order != null)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Text('A live map appears after a driver is assigned and starts sharing location.'),
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

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});
  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  final search = TextEditingController();
  final api = const ApiService();
  List<Map<String, dynamic>> medicines = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final values = await api.getMedicines(query: search.text);
      if (mounted) setState(() { medicines = values; loading = false; });
    } catch (error) {
      if (mounted) {
        setState(() => loading = false);
        showMessage(context, 'Could not load medicines: $error');
      }
    }
  }

  Future<void> _addToCart(Map<String, dynamic> item) async {
    try {
      await liveCart.add({
        ...item,
        'id': '${item['id'] ?? item['public_id'] ?? ''}',
        'name': '${item['name'] ?? 'Medicine'}',
        'price': _money(item['price']),
        'stock_quantity': _stock(item['stock_quantity']),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to your cart')),
        );
      }
    } catch (error) {
      if (mounted) showMessage(context, 'Could not add this medicine: $error');
    }
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Medicine catalogue'),
      actions: [
        _CartButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CartScreen()),
          ),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: search,
          onSubmitted: (_) => _load(),
          decoration: InputDecoration(
            labelText: 'Search medicines',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(onPressed: _load, icon: const Icon(Icons.search)),
          ),
        ),
        const SizedBox(height: 16),
        if (loading) const Center(child: CircularProgressIndicator()),
        if (!loading && medicines.isEmpty)
          const EmptyState(
            icon: Icons.medication_outlined,
            title: 'No medicines found',
            message: 'Try another medicine or category.',
          ),
        ...medicines.map((item) {
          final stock = _stock(item['stock_quantity']);
          final available = item['active'] != false && stock > 0;
          final prescriptionRequired =
              item['prescription_required'] == true ||
              item['prescriptionRequired'] == true;
          final demoRecord = item['demo_record'] == true;
          final priceText = demoRecord
              ? 'Price not verified'
              : _zar(_money(item['price']));
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE5F6F2),
                child: Icon(Icons.medication_outlined, color: teal),
              ),
              title: Text(item['name'] as String? ?? 'Medicine'),
              subtitle: Text(
                '${available ? 'In stock ($stock)' : 'Unavailable'} • $priceText'
                '${prescriptionRequired ? '\nPrescription required' : ''}',
              ),
              isThreeLine: prescriptionRequired,
              trailing: FilledButton.icon(
                onPressed: !available || prescriptionRequired
                    ? null
                    : () => _addToCart(item),
                icon: const Icon(Icons.add_shopping_cart),
                label: Text(prescriptionRequired ? 'Prescription' : 'Add to cart'),
              ),
            ),
          );
        }),
      ],
    ),
  );
}
class _CartButton extends StatelessWidget {
  const _CartButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final openCart = IconButton(
      tooltip: 'Shopping cart',
      onPressed: onPressed,
      icon: const Icon(Icons.shopping_cart_outlined),
    );
    if (!_firebaseReady) return openCart;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: liveCart.watch(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.fold<int>(
              0,
              (itemCount, doc) => itemCount + _stock(doc.data()['quantity']),
            ) ??
            0;
        return IconButton(
          tooltip: 'Shopping cart',
          onPressed: onPressed,
          icon: Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            child: const Icon(Icons.shopping_cart_outlined),
          ),
        );
      },
    );
  }
}
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _change(BuildContext context, String id, int quantity) async {
    try {
      await liveCart.change(id, quantity);
    } catch (error) {
      if (context.mounted) showMessage(context, 'Could not update cart: $error');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Your cart')),
    body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: liveCart.watch(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        if (snapshot.hasError) {
          return const EmptyState(
            icon: Icons.error_outline,
            title: 'Cart unavailable',
            message: 'Please sign in again and retry.',
          );
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (docs.isEmpty) {
          return const EmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'Your cart is empty',
            message: 'Add medicines from the shop to get started.',
          );
        }

        final lines = docs.map((doc) {
          final data = doc.data();
          return MapEntry(
            doc.id,
            CartLine(_cartMedicine(doc.id, data), quantity: _stock(data['quantity'])),
          );
        }).toList();
        final subtotal = lines.fold<double>(
          0,
          (subtotal, entry) => subtotal + entry.value.total,
        );
        const fee = 35.0;
        final hasPrescription = lines.any((entry) => entry.value.medicine.prescriptionOnly);

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            ...lines.map((entry) {
              final line = entry.value;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(line.medicine.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${_zar(line.medicine.price)} each'),
                            Text('Line total: ${_zar(line.total)}'),
                            if (line.medicine.prescriptionOnly)
                              const Text('Prescription required before checkout'),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Decrease quantity',
                        onPressed: () => _change(context, entry.key, line.quantity - 1),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('${line.quantity}'),
                      IconButton(
                        tooltip: 'Increase quantity',
                        onPressed: line.quantity < line.medicine.stockQuantity
                            ? () => _change(context, entry.key, line.quantity + 1)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                      IconButton(
                        tooltip: 'Remove item',
                        onPressed: () => _change(context, entry.key, 0),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            _CartTotalRow(label: 'Subtotal', value: _zar(subtotal)),
            _CartTotalRow(label: 'Delivery fee', value: _zar(fee)),
            _CartTotalRow(label: 'Total', value: _zar(subtotal + fee), strong: true),
            if (hasPrescription)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('A pharmacist must review prescription items before they can be ordered.'),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: hasPrescription
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                    ),
              icon: const Icon(Icons.lock_outline),
              label: const Text('Continue to checkout'),
            ),
          ],
        );
      },
    ),
  );
}

class _CartTotalRow extends StatelessWidget {
  const _CartTotalRow({required this.label, required this.value, this.strong = false});
  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(fontWeight: strong ? FontWeight.bold : null))),
        Text(value, style: TextStyle(fontWeight: strong ? FontWeight.bold : null)),
      ],
    ),
  );
}
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final address = TextEditingController();
  final api = const ApiService();
  Map<String, dynamic>? quote;
  String? quotedAddress;
  List<String>? quotedCartSignature;
  bool quoting = false;
  bool placing = false;

  @override
  void dispose() {
    address.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _currentItems() async {
    final cartDocs = (await liveCart.items.get()).docs;
    if (cartDocs.isEmpty) throw StateError('Your cart is empty.');
    if (cartDocs.any((doc) =>
        doc.data()['prescription_required'] == true ||
        doc.data()['prescriptionRequired'] == true)) {
      throw StateError('Prescription items require pharmacist review.');
    }
    return cartDocs
        .map((doc) => {
              'medication_id': doc.id,
              'quantity': _stock(doc.data()['quantity']),
            })
        .toList();
  }

  Future<void> _loadQuote() async {
    final deliveryAddress = address.text.trim();
    if (deliveryAddress.length < 8) {
      showMessage(context, 'Please enter a complete delivery address.');
      return;
    }
    if (quoting || placing) return;
    setState(() => quoting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Sign in before checkout.');
      final items = await _currentItems();
      final result = await api.quoteOrder(
        userId: user.uid,
        address: deliveryAddress,
        items: items,
      );
      if (!mounted) return;
      setState(() {
        quote = result;
        quotedAddress = deliveryAddress;
        quotedCartSignature = _cartSignature(items);
      });
    } catch (error) {
      if (mounted) showMessage(context, 'Could not get current prices: $error');
    } finally {
      if (mounted) setState(() => quoting = false);
    }
  }

  Future<void> _place() async {
    final currentAddress = address.text.trim();
    final currentQuote = quote;
    if (currentQuote == null || quotedAddress != currentAddress) {
      showMessage(context, 'Review the current prices and total before placing the order.');
      return;
    }
    if (placing || quoting) return;
    setState(() => placing = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Sign in before placing an order.');
      final items = await _currentItems();
      if (!_sameSignature(_cartSignature(items), quotedCartSignature)) {
        setState(() {
          quote = null;
          quotedCartSignature = null;
        });
        showMessage(context, 'Your cart changed. Review the current prices again.');
        return;
      }
      final result = await api.placeOrder(
        userId: user.uid,
        address: currentAddress,
        items: items,
        expectedTotal: _money(currentQuote['total']),
      );
      final reference = '${result['reference'] ?? result['id'] ?? ''}'.trim();
      if (reference.isEmpty) {
        throw const FormatException('The server did not return an order reference.');
      }
      final total = _money(result['total']);
      await liveCart.clear();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(reference: reference, total: total),
        ),
        (route) => route.isFirst,
      );
    } catch (error) {
      if (mounted) {
        final message = '$error';
        if (message.contains('409') || message.contains('total changed')) {
          setState(() => quote = null);
          showMessage(context, 'The total changed. Review the updated prices before placing the order.');
        } else {
          showMessage(context, 'Could not place the order: $error');
        }
      }
    } finally {
      if (mounted) setState(() => placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pricedItems = quote?['items'] is List
        ? (quote!['items'] as List)
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
        : const <Map<String, dynamic>>[];
    final quoteIsCurrent = quote != null && quotedAddress == address.text.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PageTitle('Delivery details', 'Where should we bring your order?'),
          TextField(
            controller: address,
            maxLines: 3,
            onChanged: (_) => setState(() => quote = null),
            decoration: const InputDecoration(
              labelText: 'Delivery address',
              hintText: 'Street, suburb and city',
            ),
          ),
          if (quoteIsCurrent) ...[
            const SizedBox(height: 20),
            const Text('Current order prices', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ...pricedItems.map((item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${item['medicine_name'] ?? 'Medicine'}'),
              subtitle: Text('Quantity: ${item['quantity']} × ${_zar(_money(item['unit_price']))}'),
              trailing: Text(_zar(_money(item['line_total']))),
            )),
            _CartTotalRow(label: 'Subtotal', value: _zar(_money(quote!['subtotal']))),
            _CartTotalRow(label: 'Delivery fee', value: _zar(_money(quote!['delivery_fee']))),
            _CartTotalRow(label: 'Total', value: _zar(_money(quote!['total'])), strong: true),
          ],
          const SizedBox(height: 16),
          if (!quoteIsCurrent)
            FilledButton(
              onPressed: quoting || placing ? null : _loadQuote,
              child: Text(quoting ? 'Checking prices...' : 'Review current prices and total'),
            )
          else
            FilledButton(
              onPressed: placing ? null : _place,
              child: Text(placing ? 'Placing order...' : 'Place order • ${_zar(_money(quote!['total']))}'),
            ),
        ],
      ),
    );
  }
}

List<String> _cartSignature(List<Map<String, dynamic>> items) {
  final signature = items
      .map((item) => '${item['medication_id']}:${item['quantity']}')
      .toList()
    ..sort();
  return signature;
}

bool _sameSignature(List<String> current, List<String>? quoted) {
  if (quoted == null || current.length != quoted.length) return false;
  for (var index = 0; index < current.length; index++) {
    if (current[index] != quoted[index]) return false;
  }
  return true;
}

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.reference, required this.total});
  final String reference;
  final double total;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Order confirmed')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: teal, size: 72),
            const SizedBox(height: 16),
            const Text(
              'Your order has been received',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Order reference: $reference'),
            const SizedBox(height: 6),
            Text('Order total: ${_zar(total)}'),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to shop'),
            ),
          ],
        ),
      ),
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

class DoctorDirectoryScreen extends StatefulWidget {
  const DoctorDirectoryScreen({super.key});

  @override
  State<DoctorDirectoryScreen> createState() => _DoctorDirectoryScreenState();
}

class _DoctorDirectoryScreenState extends State<DoctorDirectoryScreen> {
  late final Future<List<Map<String, dynamic>>> doctors = const ApiService().getDoctors();
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Find a doctor')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageTitle('Available providers', 'Provider records from the ReliefRoute database.'),
        const Text('Demo provider records are fictional and are not available for booking.'),
        const SizedBox(height: 12),
        TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Search name or specialty', prefixIcon: Icon(Icons.search)),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: doctors,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const EmptyState(icon: Icons.error_outline, title: 'Doctors unavailable', message: 'Check the backend connection and try again.');
            }
            final query = search.text.trim().toLowerCase();
            final records = (snapshot.data ?? const <Map<String, dynamic>>[])
                .where((doctor) => query.isEmpty || '${doctor['name']} ${doctor['specialty']} ${doctor['practice_name']} ${doctor['address']}'.toLowerCase().contains(query))
                .toList();
            if (records.isEmpty) {
              return const EmptyState(icon: Icons.person_search_outlined, title: 'No doctors found', message: 'No provider records are available yet.');
            }
            return Column(
              children: records.map((doctor) {
                final name = '${doctor['name'] ?? 'Provider'}';
                final specialty = '${doctor['specialty'] ?? 'Specialty not listed'}';
                final practice = '${doctor['practice_name'] ?? ''}';
                final address = '${doctor['address'] ?? 'Address not listed'}';
                final phone = '${doctor['phone'] ?? 'Phone not provided'}';
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person_outline, color: teal)),
                    title: Text(name),
                    subtitle: Text('$specialty\n$practice - $address\n$phone'),
                    isThreeLine: true,
                    trailing: const Chip(label: Text('Demo only')),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    ),
  );
}

class PharmacyDirectoryScreen extends StatefulWidget {
  const PharmacyDirectoryScreen({super.key});

  @override
  State<PharmacyDirectoryScreen> createState() => _PharmacyDirectoryScreenState();
}

class _PharmacyDirectoryScreenState extends State<PharmacyDirectoryScreen> {
  late final Future<List<Map<String, dynamic>>> pharmacies = const ApiService().getPharmacies();
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Find a pharmacy')),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageTitle('Pharmacy directory', 'Pharmacy records from the ReliefRoute database.'),
        const Text('Demo pharmacy records are fictional and are not real locations or available stock.'),
        const SizedBox(height: 12),
        TextField(
          controller: search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(labelText: 'Search name or location', prefixIcon: Icon(Icons.search)),
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: pharmacies,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const EmptyState(icon: Icons.error_outline, title: 'Pharmacies unavailable', message: 'Check the backend connection and try again.');
            }
            final query = search.text.trim().toLowerCase();
            final records = (snapshot.data ?? const <Map<String, dynamic>>[])
                .where((pharmacy) => query.isEmpty || '${pharmacy['name']} ${pharmacy['city']} ${pharmacy['address']}'.toLowerCase().contains(query))
                .toList();
            if (records.isEmpty) {
              return const EmptyState(icon: Icons.local_pharmacy_outlined, title: 'No pharmacies found', message: 'No pharmacy records are available yet.');
            }
            return Column(
              children: records.map((pharmacy) {
                final name = '${pharmacy['name'] ?? 'Pharmacy'}';
                final city = '${pharmacy['city'] ?? ''}';
                final address = '${pharmacy['address'] ?? 'Address not listed'}';
                final phone = '${pharmacy['phone'] ?? 'Phone not provided'}';
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.local_pharmacy_outlined, color: teal)),
                    title: Text(name),
                    subtitle: Text('$address${city.isEmpty ? '' : ', $city'}\n$phone'),
                    isThreeLine: true,
                    trailing: const Chip(label: Text('Demo only')),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    ),
  );
}
Future<void> openExternalLink(
  BuildContext context,
  String value,
  String message,
) async {
  final uri = Uri.parse(value);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else if (context.mounted) {
    showMessage(context, 'The link could not be opened.');
  }
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
      if (!mounted) return;
      if (remote.isEmpty) {
        setState(() => loading = false);
        return;
      }
      setState(() {
        catalogue.clear();
        for (final item in remote) {
          catalogue.add(
            _FinderItem(
              item['name'] as String? ?? 'Medicine',
              item['category'] as String? ?? 'Other',
              item['prescriptionRequired'] as bool? ?? false,
            ),
          );
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
