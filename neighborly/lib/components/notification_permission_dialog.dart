import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/push_notification_service.dart';

class NotificationPermissionDialog extends StatefulWidget {
  const NotificationPermissionDialog({super.key});

  @override
  State<NotificationPermissionDialog> createState() =>
      _NotificationPermissionDialogState();
}

class _NotificationPermissionDialogState
    extends State<NotificationPermissionDialog> {
  bool _isLoading = false;
  bool? _permissionStatus;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissionStatus();
  }

  Future<void> _checkCurrentPermissionStatus() async {
    final isGranted =
        await PushNotificationService.isNotificationPermissionGranted();
    setState(() {
      _permissionStatus = isGranted;
    });
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final granted =
          await PushNotificationService.requestNotificationPermission();

      setState(() {
        _permissionStatus = granted;
        _isLoading = false;
      });

      if (granted) {
        _showSuccessSnackBar();
      } else {
        _showErrorDialog();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog();
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Notifications enabled successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'To receive important notifications about help requests and community updates, please enable notifications in your device settings.\n\n'
              'Go to Settings > Apps > Neighborly > Notifications and enable notifications.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active,
                size: 48,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Enable Notifications',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            const Text(
              'Stay updated with important help requests and community updates in your neighborhood.',
              style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Permission Status
            if (_permissionStatus != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color:
                      _permissionStatus!
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _permissionStatus! ? Colors.green : Colors.orange,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _permissionStatus! ? Icons.check_circle : Icons.warning,
                      color: _permissionStatus! ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _permissionStatus!
                          ? 'Notifications Enabled'
                          : 'Notifications Disabled',
                      style: TextStyle(
                        color:
                            _permissionStatus! ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Later'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed:
                        _permissionStatus == true
                            ? null
                            : (_isLoading ? null : _requestPermission),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF71BB7B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : Text(
                              _permissionStatus == true
                                  ? 'Already Enabled'
                                  : 'Enable Notifications',
                            ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper function to show the dialog
void showNotificationPermissionDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const NotificationPermissionDialog(),
  );
}
