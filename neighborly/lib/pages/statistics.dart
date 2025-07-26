import 'package:flutter/material.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Helped Requests & Neighborhood Rank
          Row(
            children: [
              _statCard(
                iconPath: 'assets/images/helped.png',
                iconData: null,
                label: '55',
                subLabel: 'Helped Requests',
              ),
              const SizedBox(width: 16),
              _statCard(
                iconPath: null,
                iconData: Icons.leaderboard,
                label: '#2',
                subLabel: 'Neighborhood\nRank',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Help Response Success & Help Range Radius
          Row(
            children: [
              _statCard(
                iconPath: 'assets/images/accuracy.png',
                iconData: null,
                label: '83%',
                subLabel: 'Help Response\nSuccess',
              ),
              const SizedBox(width: 16),
              _statCard(
                iconPath: 'assets/images/map-marker.png',
                iconData: null,
                label: '86%',
                subLabel: 'Help Range\nRadius',
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Strongest Topics (all in one card)
          // Most Frequent Help Types (all in one card)
          const Text(
            'MOST REQUESTED HELP TYPES',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5B5B7E),
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _strongestTopicsCard(),
          const SizedBox(height: 28),
          // Least Contributed Areas (single card)
          const Text(
            'CONTRIBUTIONS',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5B5B7E),
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _topicCard(
            iconPath: null,
            iconData: Icons.traffic,
            label: 'Traffic Updates',
            percent: 0.95,
            percentLabel: '95%',
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    String? iconPath,
    IconData? iconData,
    required String label,
    required String subLabel,
  }) {
    return Expanded(
      child: Container(
        height: 80,
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: const Color(0xFFF2F2F7), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(10),
              child:
                  iconPath != null
                      ? SizedBox(
                        width: 36, // set your desired width
                        height: 36, // set your desired height
                        child: Align(
                          alignment: Alignment.center,
                          child: Image.asset(
                            iconPath,
                            width: 28,
                            height: 28,
                            fit: BoxFit.contain,
                          ),
                        ),
                      )
                      : Icon(
                        iconData,
                        color: const Color(0xFF5B5B7E),
                        size: 28,
                      ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                Text(
                  subLabel,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _strongestTopicsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF2F2F7), width: 1.5),
      ),
      child: Column(
        children: [
          _topicRow(
            iconPath: null,
            iconData: Icons.directions_car,
            label: 'Transportation',
            percent: 0.28,
            percentLabel: '28%',
            color: Colors.redAccent,
          ),
          const SizedBox(height: 14),
          _topicRow(
            iconPath: null,
            iconData: Icons.shopping_cart,
            label: 'Groceries',
            percent: 0.35,
            percentLabel: '35%',
            color: Colors.red,
          ),
          const SizedBox(height: 14),
          _topicRow(
            iconPath: null,
            iconData: Icons.directions,
            label: 'Directional Help',
            percent: 0.40,
            percentLabel: '40%',
            color: Colors.deepOrange,
          ),
        ],
      ),
    );
  }

  Widget _topicRow({
    String? iconPath,
    IconData? iconData,
    required String label,
    required double percent,
    required String percentLabel,
    required Color color,
  }) {
    return Row(
      children: [
        iconPath != null
            ? SizedBox(
              width: 36, // set your desired width
              height: 36, // set your desired height
              child: Align(
                alignment:
                    Alignment
                        .center, // change to .topLeft, .bottomRight, etc. as needed
                child: Image.asset(
                  iconPath,
                  width: 28, // inner image size
                  height: 28,
                  fit: BoxFit.contain, // or BoxFit.cover, BoxFit.fill, etc.
                ),
              ),
            )
            : Icon(iconData, size: 32, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percent,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFF2F2F7),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$percentLabel ',
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _topicCard({
    String? iconPath,
    IconData? iconData,
    required String label,
    required double percent,
    required String percentLabel,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFF2F2F7), width: 1.5),
      ),
      child: Row(
        children: [
          iconPath != null
              ? Image.asset(iconPath, width: 32, height: 32, fit: BoxFit.cover)
              : Icon(iconData, size: 32, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFF2F2F7),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$percentLabel ',
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
