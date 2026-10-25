
import 'package:flutter/material.dart';

class DigitalShieldPage extends StatelessWidget {
  const DigitalShieldPage({super.key});

  static const Color background = Color(0xFF160D26);
  static const Color cardColor = Color(0xFF241536);
  static const Color borderColor = Color(0xFF3B2557);
  static const Color purple = Color(0xFF7545E8);
  static const Color muted = Color(0xFFB9AACD);
  static const Color yellow = Color(0xFFFFB52E);

  void _showToolMessage(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(
          message,
          style: const TextStyle(color: muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: borderColor, width: 5),
          ),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                  children: [
                    const Text(
                      'Digital shield',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Privacy, harassment and identity protection',
                      style: TextStyle(color: muted, fontSize: 10),
                    ),
                    const SizedBox(height: 10),

                    // Privacy health card
                    Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Privacy health',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  '3 fixes recommended',
                                  style: TextStyle(
                                    color: muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            '71%',
                            style: TextStyle(
                              color: yellow,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    _toolCard(
                      context,
                      emoji: '🕵️',
                      title: 'Stalkerware scan',
                      subtitle: 'Finds hidden tracking apps',
                      action: 'Scan',
                      onTap: () => _showToolMessage(
                        context,
                        'Stalkerware scan',
                        'Scan functionality is not connected yet. '
                            'No device scan has been performed.',
                      ),
                    ),
                    const SizedBox(height: 8),

                    _toolCard(
                      context,
                      emoji: '▧',
                      title: 'Image misuse alert',
                      subtitle: 'Detects morphed or leaked photos',
                      action: 'Check',
                      onTap: () => _showToolMessage(
                        context,
                        'Image misuse alert',
                        'Image checking functionality is not connected yet.',
                      ),
                    ),
                    const SizedBox(height: 8),

                    _toolCard(
                      context,
                      emoji: '☁',
                      title: 'Abuse screenshot saver',
                      subtitle: 'Send to vault with metadata',
                      action: 'Save',
                      onTap: () => _showToolMessage(
                        context,
                        'Abuse screenshot saver',
                        'Screenshot saving and metadata storage '
                            'are not connected yet.',
                      ),
                    ),
                    const SizedBox(height: 8),

                    _toolCard(
                      context,
                      emoji: '⚑',
                      title: 'Report to cybercrime',
                      subtitle: 'Pre-filled for cybercrime.gov.in',
                      action: 'Draft',
                      onTap: () => _showToolMessage(
                        context,
                        'Cybercrime report',
                        'Report drafting is not connected yet. '
                            'Review any report before submitting it.',
                      ),
                    ),
                    const SizedBox(height: 8),

                    // AI legal helper
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _showToolMessage(
                        context,
                        'AI legal helper',
                        'Ask a question about online harassment, '
                            'privacy, or reporting cybercrime. '
                            'Legal guidance functionality is not connected yet.',
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI legal helper',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Ask “Can I file an e-FIR for online threats?”',
                              style: TextStyle(
                                color: muted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom navigation
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 3,
                ),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: borderColor),
                  ),
                ),
                child: Row(
                  children: [
                    _navItem(context, '⌂', 'Home', false),
                    _navItem(context, '◉', 'Route', false),
                    _navItem(context, '🔒', 'Vault', false),
                    _navItem(context, '♟', 'Circle', false),
                    _navItem(context, '♡', 'Shield', true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolCard(
    BuildContext context, {
    required String emoji,
    required String title,
    required String subtitle,
    required String action,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$emoji  $title',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFF12091E),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 9,
                ),
                child: Text(
                  action,
                  style: const TextStyle(
                    color: purple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    String symbol,
    String label,
    bool selected,
  ) {
    return Expanded(
      child: InkWell(
        onTap: selected
            ? null
            : () => _showToolMessage(
                  context,
                  label,
                  'Connect this item to your $label page.',
                ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF302047)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  symbol,
                  style: TextStyle(
                    color: selected ? purple : muted,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: selected ? purple : muted,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
