/// Create ticket screen — Phase 1 placeholder; form arrives in Phase 3.
library;

import 'package:flutter/material.dart';

class CreateTicketScreen extends StatelessWidget {
  const CreateTicketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tiket Baru')),
      body: const Center(child: Text('Create ticket (TODO Phase 3)')),
    );
  }
}
