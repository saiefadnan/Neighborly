import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BloodDonationPage extends StatefulWidget {
  const BloodDonationPage({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<BloodDonationPage> createState() => _BloodDonationPageState();
}

class _BloodDonationPageState extends State<BloodDonationPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final String _selectedBloodGroup = 'All';
  final String _selectedAvailability = 'All';
  final String _searchLocation = '';

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _registrationBloodGroup = 'A+';
  bool _isAvailable = true;

  final List<String> bloodGroups = [
    'All', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];
  final List<String> availabilityOptions = ['All', 'Available', 'Unavailable'];

  List<Map<String, dynamic>> allDonors = [];

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 2, vsync: this, initialIndex: widget.initialTabIndex);
    _animationController =
        AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    _nameController.text = 'Ali';
    _locationController.text = 'Dhaka, Bangladesh';

    _fetchDonorsFromFirestore();
  }

  Future<void> _fetchDonorsFromFirestore() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('donors').get();
      final List<Map<String, dynamic>> donors =
          snapshot.docs.map((doc) => doc.data()).toList().cast<Map<String, dynamic>>();
      setState(() {
        allDonors = donors;
      });
    } catch (e) {
      debugPrint('Error fetching donors: $e');
    }
  }

  Future<void> _registerAsDonor() async {
    if (_nameController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final donor = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'location': _locationController.text,
      'bloodGroup': _registrationBloodGroup,
      'isAvailable': _isAvailable,
      'lastDonation': 'Never',
      'totalDonations': 0,
    };

    try {
      await FirebaseFirestore.instance.collection('donors').add(donor);
      setState(() {
        allDonors.add(donor);
      });
      _tabController.animateTo(0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Successfully registered as a blood donor!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      debugPrint('Error registering donor: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to register. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get filteredDonors {
    return allDonors.where((donor) {
      final bloodGroupMatch =
          _selectedBloodGroup == 'All' || donor['bloodGroup'] == _selectedBloodGroup;
      final availabilityMatch = _selectedAvailability == 'All' ||
          (_selectedAvailability == 'Available' && donor['isAvailable']) ||
          (_selectedAvailability == 'Unavailable' && !donor['isAvailable']);
      final locationMatch = _searchLocation.isEmpty ||
          donor['location'].toLowerCase().contains(_searchLocation.toLowerCase());
      return bloodGroupMatch && availabilityMatch && locationMatch;
    }).toList();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to make phone call'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getBloodGroupColor(String bloodGroup) {
    switch (bloodGroup) {
      case 'A+':
      case 'A-':
        return Colors.red.shade600;
      case 'B+':
      case 'B-':
        return Colors.blue.shade600;
      case 'AB+':
      case 'AB-':
        return Colors.purple.shade600;
      case 'O+':
      case 'O-':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildRegistrationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Register as a Blood Donor',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.red),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            decoration:
                const InputDecoration(labelText: 'Location', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _registrationBloodGroup,
            decoration: const InputDecoration(labelText: 'Blood Group', border: OutlineInputBorder()),
            items: bloodGroups.where((bg) => bg != 'All').map((bg) {
              return DropdownMenuItem(value: bg, child: Text(bg));
            }).toList(),
            onChanged: (value) {
              setState(() {
                _registrationBloodGroup = value ?? 'A+';
              });
            },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Available for Donation'),
            value: _isAvailable,
            activeColor: Colors.red,
            onChanged: (value) {
              setState(() {
                _isAvailable = value;
              });
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: _registerAsDonor,
              child: const Text('Register', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonorsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredDonors.length,
      itemBuilder: (context, index) {
        final donor = filteredDonors[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getBloodGroupColor(donor['bloodGroup']),
              child: Text(
                donor['bloodGroup'],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(donor['name']),
            subtitle: Text(
                '${donor['location']} • ${donor['isAvailable'] ? "Available" : "Unavailable"}'),
            trailing: IconButton(
              icon: const Icon(Icons.phone, color: Colors.red),
              onPressed: () => _makePhoneCall(donor['phone']),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.red,
        elevation: 0,
        title: const Text('Blood Donation', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Find Donors'),
            Tab(text: 'Become Donor'),
          ],
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDonorsList(),
            _buildRegistrationForm(),
          ],
        ),
      ),
    );
  }
}
