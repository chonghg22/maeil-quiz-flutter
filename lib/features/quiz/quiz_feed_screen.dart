import 'package:flutter/material.dart';

class QuizFeedScreen extends StatelessWidget {
  const QuizFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('매일퀴즈'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('퀴즈 피드'),
      ),
    );
  }
}
