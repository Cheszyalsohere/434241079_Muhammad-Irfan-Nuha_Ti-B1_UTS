/// Ticket list screen — Phase 1 placeholder; full list + tabs + search
/// arrive in Phase 3.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TicketListScreen extends StatelessWidget {
  const TicketListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tiket')),
      body: const Center(child: Text('Ticket list (TODO Phase 3)')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/tickets/create'),
        icon: const Icon(Icons.add),
        label: const Text('Tiket Baru'),
      ),
    );
  }
}
