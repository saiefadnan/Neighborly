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

  Widget sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 12),
    child: Text(
      title,
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  );

  Widget cupertinoTile(String label, bool value, Function(bool) onChanged) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            CupertinoSwitch(value: value, onChanged: onChanged),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: BackButton(color: Colors.black),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          sectionHeader("Common"),
          cupertinoTile(
            'General Notification',
            generalNotification,
            (v) => setState(() => generalNotification = v),
          ),
          cupertinoTile('Sound', sound, (v) => setState(() => sound = v)),
          cupertinoTile('Vibrate', vibrate, (v) => setState(() => vibrate = v)),
          const SizedBox(height: 8),
          Divider(thickness: 1, height: 32),

          sectionHeader("System & services update"),
          cupertinoTile(
            'App updates',
            appUpdates,
            (v) => setState(() => appUpdates = v),
          ),
          cupertinoTile(
            'Bill Reminder',
            billReminder,
            (v) => setState(() => billReminder = v),
          ),
          cupertinoTile(
            'Promotion',
            promotion,
            (v) => setState(() => promotion = v),
          ),
          cupertinoTile(
            'Discount Avaible',
            discountAvailable,
            (v) => setState(() => discountAvailable = v),
          ),
          cupertinoTile(
            'Payment Request',
            paymentRequest,
            (v) => setState(() => paymentRequest = v),
          ),
          const SizedBox(height: 8),
          Divider(thickness: 1, height: 32),

          sectionHeader("Others"),
          cupertinoTile(
            'New Service Available',
            newServiceAvailable,
            (v) => setState(() => newServiceAvailable = v),
          ),
          cupertinoTile(
            'New Tips Available',
            newTipsAvailable,
            (v) => setState(() => newTipsAvailable = v),
          ),
        ],
      ),
    );
  }
}
