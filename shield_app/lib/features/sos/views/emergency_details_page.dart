
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/emergency_alert_model.dart';

class EmergencyDetailsPage extends StatelessWidget {
  const EmergencyDetailsPage({
    super.key,
    required this.alert,
  });

  final EmergencyAlert alert;

  static const Color purple = Color(0xFF6C3FC5);
  static const Color red = Color(0xFFE53950);

  Future<void> _openLink(BuildContext context, Uri uri) async {
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not open the requested app.');
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open app: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationAvailable =
        alert.latitude != null && alert.longitude != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F2FF),
      appBar: AppBar(
        title: const Text('Emergency Details'),
        backgroundColor: const Color(0xFFF6F2FF),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: red,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.sos_rounded,
                    size: 54,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'EMERGENCY ALERT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Someone in your trusted circle may need help.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Card(
              color: Colors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alert details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _detailRow(
                      Icons.person_outline,
                      'Sender',
                      alert.senderName,
                    ),
                    _detailRow(
                      Icons.phone_outlined,
                      'Phone',
                      alert.senderPhone,
                    ),
                    _detailRow(
                      Icons.access_time,
                      'Time',
                      alert.createdAt.toLocal().toString().split('.').first,
                    ),
                    if (alert.message != null &&
                        alert.message!.trim().isNotEmpty)
                      _detailRow(
                        Icons.message_outlined,
                        'Message',
                        alert.message!,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Last shared location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (locationAvailable) ...[
                      Text(
                        '${alert.latitude}, ${alert.longitude}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => _openLink(
                          context,
                          Uri.parse(
                            'https://www.google.com/maps/search/?api=1'
                            '&query=${alert.latitude},${alert.longitude}',
                          ),
                        ),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Open in Maps'),
                      ),
                    ] else
                      const Text(
                        'No location was included in this alert.',
                        style: TextStyle(color: Colors.black54),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _openLink(
                context,
                Uri(scheme: 'tel', path: alert.senderPhone),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: purple,
                minimumSize: const Size.fromHeight(52),
              ),
              icon: const Icon(Icons.call),
              label: const Text('Call sender'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openLink(
                context,
                Uri(
                  scheme: 'sms',
                  path: alert.senderPhone,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              icon: const Icon(Icons.message_outlined),
              label: const Text('Message sender'),
            ),
            const SizedBox(height: 12),
            const Text(
              'Location is only available if it was successfully shared '
              'with this alert. If there is immediate danger, contact '
              'local emergency services.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: purple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
