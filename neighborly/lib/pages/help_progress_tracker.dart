import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:neighborly/models/help_chat_models.dart';
import 'package:neighborly/services/help_chat_service.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class HelpProgressTracker extends StatefulWidget {
  final String helpRequestId;
  final String helpRequestTitle;
  final bool isRequester;

  const HelpProgressTracker({
    super.key,
    required this.helpRequestId,
    required this.helpRequestTitle,
    required this.isRequester,
  });

  @override
  State<HelpProgressTracker> createState() => _HelpProgressTrackerState();
}

class _HelpProgressTrackerState extends State<HelpProgressTracker> {
  final HelpChatService _chatService = HelpChatService();

  @override
  void initState() {
    super.initState();
  }

  Color _getStatusColor(HelpProgressStatus status) {
    switch (status) {
      case HelpProgressStatus.started:
        return Colors.blue;
      case HelpProgressStatus.onTheWay:
        return Colors.orange;
      case HelpProgressStatus.arrived:
        return const Color(0xFF71BB7B);
      case HelpProgressStatus.helping:
        return Colors.indigo;
      case HelpProgressStatus.nearCompletion:
        return Colors.purple;
    }
  }

  IconData _getStatusIcon(HelpProgressStatus status) {
    switch (status) {
      case HelpProgressStatus.started:
        return Icons.check_circle;
      case HelpProgressStatus.onTheWay:
        return Icons.directions_walk;
      case HelpProgressStatus.arrived:
        return Icons.location_on;
      case HelpProgressStatus.helping:
        return Icons.build;
      case HelpProgressStatus.nearCompletion:
        return Icons.schedule;
    }
  }

  String _getStatusTitle(HelpProgressStatus status) {
    switch (status) {
      case HelpProgressStatus.started:
        return 'Help Started';
      case HelpProgressStatus.onTheWay:
        return 'Helper is On the Way';
      case HelpProgressStatus.arrived:
        return 'Helper has Arrived';
      case HelpProgressStatus.helping:
        return 'Help in Progress';
      case HelpProgressStatus.nearCompletion:
        return 'Almost Complete';
    }
  }

  Widget _buildProgressTimeline(List<HelpProgressUpdate> updates) {
    // Add the initial started status if not present
    final allUpdates = <HelpProgressUpdate>[
      if (updates.isEmpty || updates.first.status != HelpProgressStatus.started)
        HelpProgressUpdate(
          id: 'initial',
          helpRequestId: widget.helpRequestId,
          updaterId: '',
          updaterName: 'System',
          status: HelpProgressStatus.started,
          message: 'Help request was accepted and started',
          timestamp: updates.isNotEmpty 
              ? updates.first.timestamp.subtract(const Duration(minutes: 1))
              : DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      ...updates,
    ];

    return ListView.builder(
      itemCount: allUpdates.length,
      itemBuilder: (context, index) {
        final update = allUpdates[index];
        final isLast = index == allUpdates.length - 1;
        final color = _getStatusColor(update.status);

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline indicator
              SizedBox(
                width: 60,
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Icon(
                        _getStatusIcon(update.status),
                        color: color,
                        size: 20,
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: Colors.grey[300],
                          margin: const EdgeInsets.symmetric(vertical: 4),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Container(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: isLast ? 0 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusTitle(update.status),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (update.message.isNotEmpty)
                        Text(
                          update.message,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (update.updaterName.isNotEmpty && update.updaterName != 'System') ...[
                            Icon(
                              Icons.person,
                              size: 14,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              update.updaterName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeago.format(update.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No progress updates yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isRequester
                ? 'Your helper will update you on their progress'
                : 'Start by sending progress updates to keep the requester informed',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverview(List<HelpProgressUpdate> updates) {
    if (updates.isEmpty) return const SizedBox.shrink();

    final currentUpdate = updates.last;
    final color = _getStatusColor(currentUpdate.status);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getStatusIcon(currentUpdate.status),
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Status',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getStatusTitle(currentUpdate.status),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (currentUpdate.message.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    currentUpdate.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            timeago.format(currentUpdate.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF71BB7B),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Progress Tracker',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.helpRequestTitle,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getProgressUpdates(widget.helpRequestId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading progress',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingAnimationWidget.staggeredDotsWave(
                color: const Color(0xFF71BB7B),
                size: 32,
              ),
            );
          }

          final updates = snapshot.data?.docs
              .map((doc) => HelpProgressUpdate.fromJson({
                    'id': doc.id,
                    ...doc.data() as Map<String, dynamic>,
                  }))
              .toList() ?? [];

          if (updates.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildProgressOverview(updates),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildProgressTimeline(updates),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
