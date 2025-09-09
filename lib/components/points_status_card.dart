
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Drop-in widget to display current user's points and a progress bar
/// toward the next Aggie title
class PointsStatusCard extends StatelessWidget {
  const PointsStatusCard({super.key});

  static const _tiers = <int, String>{
    0: 'Fish',
    500: 'Sophomore',
    1500: 'Junior',
    3000: 'Senior',
    5000: 'Aggie Ring',
    10000: '12th Man',
  };

  /// Return the title for a given point total.
  String _titleFor(int pts) {
    String current = 'Fish';
    for (final entry in _tiers.entries) {
      if (pts >= entry.key) current = entry.value;
    }
    return current;
  }

  /// Return the lower and upper bounds for the current tier and next tier.
  /// If already at top, next bound equals current points.
  (int lower, int upper) _boundsFor(int pts) {
    final keys = _tiers.keys.toList()..sort();
    int lower = 0;
    int upper = keys.last;
    for (int i = 0; i < keys.length; i++) {
      final k = keys[i];
      if (pts < k) {
        upper = k;
        break;
      }
      lower = k;
      if (i == keys.length - 1) {
        // at top tier
        upper = pts; // avoids division by zero
      }
    }
    return (lower, upper);
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Card(
        margin: EdgeInsets.all(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('Sign in to view points'),
        ),
      );
    }

    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: userDoc.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Card(
            margin: EdgeInsets.all(12),
            child: SizedBox(
              height: 88,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final data = snap.data?.data() ?? {};
        final pts = (data['points'] ?? 0) as int;
        final title = (data['title'] as String?) ?? _titleFor(pts);
        final (lower, upper) = _boundsFor(pts);
        final denom = (upper - lower) == 0 ? 1 : (upper - lower);
        final progress = ((pts - lower) / denom).clamp(0.0, 1.0);

        String nextLabel;
        if (upper == pts && title == '12th Man') {
          nextLabel = 'Max title reached';
        } else {
          final nextTitle = _titleFor(upper);
          nextLabel = '$pts / $upper to $nextTitle';
        }

        return Card(
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events_outlined),
                    const SizedBox(width: 8),
                    Text(
                      'Leaderboard Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      '$pts points',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Text(
                      nextLabel,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
