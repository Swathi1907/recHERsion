
import 'package:flutter/material.dart';

import '../models/evidence_item.dart';

class EvidenceItemCard extends StatelessWidget {
  const EvidenceItemCard({
    super.key,
    required this.item,
  });

  final EvidenceItem item;

  static const panel = Color(0xFF211532);
  static const border = Color(0xFF493263);
  static const muted = Color(0xFFB9A9D0);
  static const teal = Color(0xFF14B8A6);
  static const violet = Color(0xFF8955E8);

  IconData get _icon {
    switch (item.type) {
      case EvidenceType.audio:
        return Icons.mic_rounded;
      case EvidenceType.video:
        return Icons.videocam_rounded;
      case EvidenceType.photo:
        return Icons.photo_camera_rounded;
      case EvidenceType.note:
        return Icons.description_rounded;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.day} ${months[date.month - 1]} · '
        '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(_icon, color: const Color(0xFFD0B7FF), size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(item.createdAt),
                  style: const TextStyle(color: muted, fontSize: 10),
                ),
                if (item.sha256 != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'SHA-256: ${item.sha256}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: muted, fontSize: 9),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: (item.isVerified ? teal : violet)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.isVerified ? '✓ Verified' : 'Demo',
              style: TextStyle(
                color: item.isVerified ? teal : const Color(0xFFD0B7FF),
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
