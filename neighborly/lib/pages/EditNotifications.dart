import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class EditNotificationsPage extends StatefulWidget {
  const EditNotificationsPage({super.key});

  @override
  _EditNotificationsPageState createState() => _EditNotificationsPageState();
}

class _EditNotificationsPageState extends State<EditNotificationsPage> {
  bool generalNotification = true;
  bool sound = false;
  bool vibrate = true;

  bool appUpdates = false;
  bool billReminder = true;
  bool promotion = true;
  bool discountAvailable = false;
  bool paymentRequest = false;

  bool newServiceAvailable = false;
  bool newTipsAvailable = true;

  Widget _notificationTile(String label, bool value, Function(bool) onChanged) {
    return ListTile(
      title: Text(label, style: const TextStyle(fontSize: 16)),
      trailing: Transform.scale(
        scale: 0.85,
        child: CupertinoSwitch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.green,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  Widget _profileSection(String title, List<Widget> children) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF7F7FA,
      ), // Match editProfile.dart background
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(
          0xFFEFF3F9,
        ), // Match editProfile.dart AppBar color
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          _profileSection('Common', [
            _notificationTile(
              'General Notification',
              generalNotification,
              (v) => setState(() => generalNotification = v),
            ),
            _notificationTile('Sound', sound, (v) => setState(() => sound = v)),
            _notificationTile(
              'Vibrate',
              vibrate,
              (v) => setState(() => vibrate = v),
            ),
          ]),

          const SizedBox(height: 16),

          _profileSection('System & services update', [
            _notificationTile(
              'App updates',
              appUpdates,
              (v) => setState(() => appUpdates = v),
            ),
            _notificationTile(
              'Bill Reminder',
              billReminder,
              (v) => setState(() => billReminder = v),
            ),
            _notificationTile(
              'Promotion',
              promotion,
              (v) => setState(() => promotion = v),
            ),
            _notificationTile(
              'Discount Available',
              discountAvailable,
              (v) => setState(() => discountAvailable = v),
            ),
            _notificationTile(
              'Payment Request',
              paymentRequest,
              (v) => setState(() => paymentRequest = v),
            ),
          ]),

          const SizedBox(height: 16),

          _profileSection('Others', [
            _notificationTile(
              'New Service Available',
              newServiceAvailable,
              (v) => setState(() => newServiceAvailable = v),
            ),
            _notificationTile(
              'New Tips Available',
              newTipsAvailable,
              (v) => setState(() => newTipsAvailable = v),
            ),
          ]),
        ],
      ),
    );
  }
}
