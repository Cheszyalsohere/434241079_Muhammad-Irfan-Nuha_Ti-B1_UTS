/// Ticket detail screen — Phase 1 placeholder; full detail with
/// timeline + comments arrives in Phase 3/6.
library;

import 'package:flutter/material.dart';

class TicketDetailScreen extends StatelessWidget {
  const TicketDetailScreen({required this.ticketId, super.key});

  final String ticketId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Tiket $ticketId')),
      body: Center(
        child: Text('Ticket detail $ticketId (TODO Phase 3)'),
      ),
    );
  }
}
