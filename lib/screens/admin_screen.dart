import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_profile.dart';
import '../services/firebase_service.dart';
import '../services/family_service.dart';
import '../utils/constants.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  final FamilyService _familyService = FamilyService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    // FIX #1 — normalize email before comparing (toLowerCase + trim)
    // Previously: adminEmails.contains(authProvider.userProfile?.email)
    // This failed for emails stored with capitals or spaces in Firestore
    const adminEmails = ['an2mouth@yahoo.com', 'alerttmenow@gmail.com'];
    final currentEmail = (authProvider.userProfile?.email ?? '').toLowerCase().trim();

    if (!adminEmails.contains(currentEmail)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text(
            'You do not have admin access',
            style: TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),

      // FIX #2 — show loading overlay when an admin action is running
      // Previously: _isLoading was toggled but never shown — admin could double-tap buttons
      body: Stack(
        children: [
          Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade100,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),

              // User List + Stats (single stream)
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No users found'));
                    }

                    final allUsers = snapshot.data!.docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return UserProfile.fromMap(data).copyWith(uid: doc.id);
                    }).toList();

                    final filteredUsers = _searchQuery.isEmpty
                        ? allUsers
                        : allUsers.where((user) {
                      return user.displayName.toLowerCase().contains(_searchQuery) ||
                          user.email.toLowerCase().contains(_searchQuery);
                    }).toList();

                    filteredUsers.sort((a, b) {
                      if (a.isSubscriptionActive != b.isSubscriptionActive) {
                        return a.isSubscriptionActive ? -1 : 1;
                      }
                      return a.displayName.compareTo(b.displayName);
                    });

                    return Column(
                      children: [
                        // FIX #3 — pass allUsers directly to stats instead of opening a second stream
                        // Previously: _buildStatsCards() opened its own StreamBuilder on the same
                        // 'users' collection — two live Firestore listeners for identical data
                        _buildStatsCards(allUsers),

                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              return _buildUserCard(filteredUsers[index]);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),

          // FIX #2 continued — loading overlay blocks all taps while action runs
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.4),
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Updating...', style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // FIX #3 — accepts pre-loaded users list, no second Firestore stream needed
  Widget _buildStatsCards(List<UserProfile> users) {
    final totalUsers = users.length;
    final premiumUsers = users.where((u) => u.isSubscriptionActive).length;
    final freeUsers = totalUsers - premiumUsers;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Users',
              totalUsers.toString(),
              Icons.people,
              AppConstants.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Premium',
              premiumUsers.toString(),
              Icons.star,
              Colors.amber.shade700,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Free',
              freeUsers.toString(),
              Icons.schedule,
              Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserProfile user) {
    // FIX #4 — use isSubscriptionActive only (checks isPremium AND expiry > now)
    // Previously: user.isSubscriptionActive || user.isPremium
    // That showed PREMIUM badge for users with isPremium=true but expired subscriptions
    final isPremium = user.isSubscriptionActive;
    final expiryDate = user.subscriptionExpiryDate;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPremium ? Colors.amber : Colors.grey.shade300,
          width: isPremium ? 2 : 1,
        ),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isPremium ? Colors.amber : AppConstants.primaryColor,
          child: Text(
            user.displayName.substring(0, 1).toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (isPremium)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 12, color: Colors.black),
                    SizedBox(width: 4),
                    Text(
                      'PREMIUM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(user.email, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Joined: ${_formatDate(user.createdAt)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),

                _buildDetailRow('User ID', user.uid),
                _buildDetailRow('Email', user.email),
                _buildDetailRow('Display Name', user.displayName),
                _buildDetailRow('Free Scans Left', '${user.freeScansRemaining}'),
                _buildDetailRow('Subscription Status', isPremium ? 'Premium ✓' : 'Free'),

                if (expiryDate != null)
                  _buildDetailRow(
                    isPremium ? 'Expires On' : 'Expired On',
                    '${expiryDate.day}/${expiryDate.month}/${expiryDate.year}',
                  ),

                if (user.isDiabetic)
                  _buildDetailRow('Health Profile', 'Diabetic'),

                if (user.allergyList.isNotEmpty)
                  _buildDetailRow('Allergies', user.allergyList.join(', ')),

                const SizedBox(height: 16),

                // FIX #2 continued — buttons disabled while loading
                Row(
                  children: [
                    if (isPremium)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _revokeAccess(user),
                          icon: const Icon(Icons.block),
                          label: const Text('Revoke Premium'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.red.shade200,
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : () => _grantAccess(user),
                          icon: const Icon(Icons.star),
                          label: const Text('Grant Premium'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber.shade700,
                            foregroundColor: Colors.black,
                            disabledBackgroundColor: Colors.amber.shade200,
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : () => _resetScans(user),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset Scans'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppConstants.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _grantAccess(UserProfile user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grant Premium Access'),
        content: Text('Grant premium access to ${user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade700),
            child: const Text('Grant Access'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        final expiryDate = DateTime.now().add(const Duration(days: 365));

        // Grant premium to the owner
        await _firebaseService.updateSubscription(user.uid, true, expiryDate);

        // ✅ If this user is a family plan owner, restore premium to all their members too
        await _familyService.restoreFamilyPlan(user.uid, expiryDate);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Premium access granted to ${user.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _revokeAccess(UserProfile user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Revoke Premium Access'),
        content: Text('Revoke premium access from ${user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Revoke Access'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        // Revoke premium from the owner (set to yesterday — unambiguously expired)
        await _firebaseService.updateSubscription(
          user.uid,
          false,
          DateTime.now().subtract(const Duration(days: 1)),
        );

        // ✅ If this user is a family plan owner, revoke premium from all their members too
        await _familyService.revokeFamilyPlan(user.uid);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Premium access revoked from ${user.displayName}'),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetScans(UserProfile user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Free Scans'),
        content: Text('Reset free scans to ${AppConstants.freeScans} for ${user.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);

      try {
        await _firestore.collection('users').doc(user.uid).update({
          'freeScansRemaining': AppConstants.freeScans,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Free scans reset for ${user.displayName}'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}