import 'package:flutter/material.dart';

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프리미엄 구독')),
      body: const Center(
        child: Text('결제'),
      ),
    );
  }
}
