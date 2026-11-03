enum PaymentStatus { pending, successful, failed, cancelled }

enum OrderStatus { placed, processing, dispatched, outForDelivery, delivered }

enum PrescriptionStatus { pending, approved, rejected }

class Medicine {
  final String id, name, description, category;
  final double price;
  final bool prescriptionOnly;
  final bool available;
  bool favourite;
  Medicine({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    this.prescriptionOnly = false,
    this.available = true,
    this.favourite = false,
  });
}

class CartLine {
  final Medicine medicine;
  int quantity;
  CartLine(this.medicine, {this.quantity = 1});
  double get total => medicine.price * quantity;
}

class OrderRecord {
  final String reference;
  final List<CartLine> items;
  final double deliveryFee;
  final DateTime createdAt;
  OrderStatus status;
  PaymentStatus paymentStatus;
  final String address;
  OrderRecord({
    required this.reference,
    required this.items,
    required this.deliveryFee,
    required this.createdAt,
    required this.address,
    this.status = OrderStatus.placed,
    this.paymentStatus = PaymentStatus.pending,
  });
  double get subtotal => items.fold(0, (sum, line) => sum + line.total);
  double get total => subtotal + deliveryFee;
}

class PrescriptionRecord {
  final String reference, fileName;
  PrescriptionStatus status;
  String note;
  final DateTime submittedAt;
  PrescriptionRecord({
    required this.reference,
    required this.fileName,
    required this.status,
    required this.submittedAt,
    this.note = 'Awaiting pharmacist review',
  });
}

class Reminder {
  String medicine, time, frequency;
  bool completed;
  Reminder({
    required this.medicine,
    required this.time,
    required this.frequency,
    this.completed = false,
  });
}

class AppNotification {
  final String title, message;
  final DateTime createdAt;
  bool read;
  AppNotification(this.title, this.message, {this.read = false})
    : createdAt = DateTime.now();
}

String zar(double amount) => 'R${amount.toStringAsFixed(2)}';
String orderStatusLabel(OrderStatus value) => switch (value) {
  OrderStatus.placed => 'Order placed',
  OrderStatus.processing => 'Processing',
  OrderStatus.dispatched => 'Dispatched',
  OrderStatus.outForDelivery => 'Out for delivery',
  OrderStatus.delivered => 'Delivered',
};
String paymentLabel(PaymentStatus value) => switch (value) {
  PaymentStatus.pending => 'Pending',
  PaymentStatus.successful => 'Successful',
  PaymentStatus.failed => 'Failed',
  PaymentStatus.cancelled => 'Cancelled',
};
