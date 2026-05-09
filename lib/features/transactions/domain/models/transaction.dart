class Transaction {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String status; // 'completed', 'pending', 'failed'
  final String type; // 'payment', 'refund'

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.status,
    required this.type,
  });
}

// Mock Data
final mockTransactions = [
  Transaction(id: 'TRX-10294', title: 'Payment from John Doe', amount: 1500.00, date: DateTime.now().subtract(const Duration(hours: 1)), status: 'completed', type: 'payment'),
  Transaction(id: 'TRX-10293', title: 'Payment from Jane Smith', amount: 340.50, date: DateTime.now().subtract(const Duration(hours: 3)), status: 'completed', type: 'payment'),
  Transaction(id: 'TRX-10292', title: 'Refund to Alex', amount: -150.00, date: DateTime.now().subtract(const Duration(hours: 5)), status: 'completed', type: 'refund'),
  Transaction(id: 'TRX-10291', title: 'Payment from Michael', amount: 4200.00, date: DateTime.now().subtract(const Duration(days: 1)), status: 'completed', type: 'payment'),
  Transaction(id: 'TRX-10290', title: 'Payment from Sarah', amount: 890.00, date: DateTime.now().subtract(const Duration(days: 1, hours: 4)), status: 'completed', type: 'payment'),
];
