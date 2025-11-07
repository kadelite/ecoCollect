import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RewardsScreen extends StatefulWidget {
  final String userId;
  const RewardsScreen({super.key, required this.userId});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final List<String> _tips = [
    '💡 Sort your waste into categories (Plastic, Paper, Metal, Glass, Organic) to maximize recycling efficiency.',
    '♻️ Rinse containers before recycling to prevent contamination.',
    '🌱 Compost organic waste like food scraps and yard waste to reduce landfill use.',
    '📦 Break down cardboard boxes to save space and make collection easier.',
    '🚫 Avoid putting recyclables in plastic bags - they should be loose in recycling bins.',
    '🔋 Batteries and electronics need special disposal - find e-waste collection points.',
    '💧 One recycled plastic bottle saves enough energy to power a lightbulb for 3 hours!',
    '📊 Report waste hotspots regularly to help keep your community clean.',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Points Card
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(widget.userId)
                .snapshots(),
            builder: (context, snapshot) {
              int points = 0;
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                points = data?['points'] ?? 0;
              }

              return Card(
                elevation: 4,
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.stars,
                        size: 60,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Your Eco-Points',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$points',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _getPointsMessage(points),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Activity Feed
          const Text(
            'Your Activity',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('waste_reports')
                .where('userId', isEqualTo: widget.userId)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error loading activity: ${snapshot.error}'),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No activity yet. Start reporting waste hotspots!'),
                  ),
                );
              }

              // Sort by timestamp in memory (since composite index might not exist)
              final reports = snapshot.data!.docs.toList()
                ..sort((a, b) {
                  final aTime = a.data() as Map<String, dynamic>;
                  final bTime = b.data() as Map<String, dynamic>;
                  final aTimestamp = aTime['timestamp'] as Timestamp?;
                  final bTimestamp = bTime['timestamp'] as Timestamp?;
                  if (aTimestamp == null && bTimestamp == null) return 0;
                  if (aTimestamp == null) return 1;
                  if (bTimestamp == null) return -1;
                  return bTimestamp.compareTo(aTimestamp);
                });
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final data = reports[index].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.green,
                        child: Icon(Icons.check, color: Colors.white),
                      ),
                      title: Text(
                        'Reported ${data['category'] ?? 'waste'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        data['description'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            '+10',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (data['timestamp'] != null)
                            Text(
                              _formatTimestamp(data['timestamp']),
                              style: const TextStyle(fontSize: 10),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // Environmental Tips
          const Text(
            'Environmental Tips',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._tips.map((tip) => Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Colors.amber,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tip,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  String _getPointsMessage(int points) {
    if (points == 0) {
      return 'Start reporting waste hotspots to earn points!';
    } else if (points < 50) {
      return 'Keep going! You\'re making a difference 🌱';
    } else if (points < 100) {
      return 'Great job! You\'re an eco-warrior! 🌍';
    } else if (points < 200) {
      return 'Amazing! You\'re a recycling champion! 🏆';
    } else {
      return 'Outstanding! You\'re a sustainability hero! 🌟';
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = timestamp is Timestamp 
        ? timestamp.toDate() 
        : DateTime.now();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

