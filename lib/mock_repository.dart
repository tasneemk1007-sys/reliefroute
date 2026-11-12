import 'models.dart';

class MockRepository {
  final medicines = <Medicine>[
    Medicine(
      id: 'm1',
      name: 'Paracetamol 500mg',
      description: 'Pain and fever relief',
      category: 'Pain relief',
      price: 42.90,
    ),
    Medicine(
      id: 'm2',
      name: 'Amoxicillin 500mg',
      description: 'Prescription antibiotic capsules',
      category: 'Prescription',
      price: 89.50,
      prescriptionOnly: true,
    ),
    Medicine(
      id: 'm3',
      name: 'Allergy Relief',
      description: 'Non-drowsy allergy tablets',
      category: 'Allergy',
      price: 65.00,
    ),
    Medicine(
      id: 'm4',
      name: 'Vitamin C 1000mg',
      description: 'Daily immune support supplement',
      category: 'Vitamins',
      price: 119.90,
    ),
    Medicine(
      id: 'm5',
      name: 'Cough Calm Syrup',
      description: 'Soothing cough syrup',
      category: 'Cold & flu',
      price: 74.95,
    ),
    Medicine(
      id: 'm6',
      name: 'Insulin Pen',
      description: 'Prescription insulin device',
      category: 'Prescription',
      price: 249.00,
      prescriptionOnly: true,
      available: false,
    ),
  ];
  final cart = <CartLine>[];
  final orders = <OrderRecord>[];
  final prescriptions = <PrescriptionRecord>[];
  final reminders = <Reminder>[
    Reminder(medicine: 'Vitamin C 1000mg', time: '08:00', frequency: 'Daily'),
  ];
  final notifications = <AppNotification>[
    AppNotification(
      'Welcome to ReliefRoute',
      'Your demonstration account is ready.',
    ),
    AppNotification(
      'Prescription update',
      'Prescription #RX-1042 is awaiting review.',
    ),
  ];
  double get subtotal => cart.fold(0, (sum, line) => sum + line.total);
  double get deliveryFee => cart.isEmpty ? 0 : 35.00;
  double get total => subtotal + deliveryFee;
  void addToCart(Medicine medicine) {
    final existing = cart.where((line) => line.medicine.id == medicine.id);
    if (existing.isEmpty) {
      cart.add(CartLine(medicine));
    } else {
      existing.first.quantity++;
    }
  }

  void adjust(CartLine line, int amount) {
    line.quantity += amount;
    if (line.quantity <= 0) cart.remove(line);
  }

  String createOrder(String address) {
    final reference =
        'RR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    orders.insert(
      0,
      OrderRecord(
        reference: reference,
        items: cart
            .map((line) => CartLine(line.medicine, quantity: line.quantity))
            .toList(),
        deliveryFee: deliveryFee,
        createdAt: DateTime.now(),
        address: address,
      ),
    );
    cart.clear();
    return reference;
  }
}
