import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../providers/auth_provider.dart';
import '../services/family_service.dart';
import '../utils/constants.dart';
import '../gen_l10n/app_localizations.dart';

class FamilyManagementScreen extends StatefulWidget {
  const FamilyManagementScreen({Key? key}) : super(key: key);

  @override
  State<FamilyManagementScreen> createState() => _FamilyManagementScreenState();
}

class _FamilyManagementScreenState extends State<FamilyManagementScreen> {
  final FamilyService _familyService = FamilyService();
  final TextEditingController _codeController = TextEditingController();

  List<Map<String, dynamic>> _familyMembers = [];
  bool _isLoading = false;

  // ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ NEW: local fallback if the profile didn't hydrate familyCode after login
  String? _retrievedFamilyCode;

  AppLocalizations get l10n => AppLocalizations.of(context)!;

  int _maxMembers = AppConstants.familyMaxMembers;
  int _extraSlots = 0;

  @override
  void initState() {
    super.initState();
    _loadFamilyMembers();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadFamilyMembers() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;

    if (userProfile == null) return;

    setState(() => _isLoading = true);

    try {
      final ownerId = userProfile.isFamilyPlanOwner
          ? userProfile.uid
          : userProfile.familyPlanOwnerId;

      if (ownerId != null) {
        final capacity = await _familyService.getFamilyCapacity(ownerId);
        setState(() {
          _maxMembers = capacity['maxMembers'] as int;
          _extraSlots = capacity['extraMemberSlots'] as int;
        });

        final members = await _familyService.getFamilyMembers(ownerId);
        setState(() {
          _familyMembers = members;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ NEW: retrieve owner family code directly from Firestore (safe + minimal)
  Future<void> _handleRetrieveFamilyCode(String ownerId) async {
    setState(() => _isLoading = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .get();
      if (!doc.exists) {
        throw Exception('Owner profile not found.');
      }

      final data = doc.data() ?? {};
      final code = (data['familyCode'] ?? '').toString().trim();

      if (code.isEmpty) {
        throw Exception(
            'No family code found. If you just subscribed, create the family plan first.');
      }

      setState(() {
        _retrievedFamilyCode = code;
      });

      // Refresh members + capacity so UI stays accurate
      await _loadFamilyMembers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Family code retrieved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userProfile = authProvider.userProfile;

    if (userProfile == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(l10n.familyPlanTileTitle),
          backgroundColor: Colors.purple.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final isOwner = userProfile.isFamilyPlanOwner;
    final isMember = userProfile.familyPlanOwnerId != null;

    // ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ prefer Firestore-hydrated code, else local retrieved fallback
    final familyCode = userProfile.familyCode ?? _retrievedFamilyCode;

    // ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ Determine ownerId for retrieval & member list
    final ownerId = isOwner ? userProfile.uid : userProfile.familyPlanOwnerId;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.familyPlanTileTitle),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ If owner and we have code -> show normal code card
                  if (isOwner && familyCode != null) ...[
                    _buildFamilyCodeCard(familyCode),
                    const SizedBox(height: 24),
                  ],

                  // ÃƒÂ¢Ã…â€œÃ¢â‚¬Â¦ If owner but code missing -> show retrieve button card
                  if (isOwner &&
                      (familyCode == null || familyCode.trim().isEmpty) &&
                      ownerId != null) ...[
                    _buildRetrieveCodeCard(ownerId),
                    const SizedBox(height: 24),
                  ],

                  // Join flow (only if not owner and not member)
                  if (!isOwner && !isMember) ...[
                    _buildJoinFamilySection(),
                    const SizedBox(height: 24),
                  ],

                  // Members list (if member or owner)
                  if (isMember || isOwner) ...[
                    _buildMembersList(isOwner, _familyMembers.length),
                    const SizedBox(height: 24),
                  ],

                  // Cost breakdown (owner only)
                  if (isOwner)
                    _buildCostBreakdown(userProfile.totalFamilyMembers),
                ],
              ),
            ),
    );
  }

  Widget _buildRetrieveCodeCard(String ownerId) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.key, color: Colors.purple.shade700, size: 28),
                const SizedBox(width: 10),
                Text(
                  l10n.familyPlanTileTitle,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Your family code is not showing after sign-in. Tap below to retrieve it.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _handleRetrieveFamilyCode(ownerId),
                icon: const Icon(Icons.refresh),
                label: const Text('Retrieve Family Code'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyCodeCard(String code) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade700, Colors.purple.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            const Icon(Icons.family_restroom, color: Colors.white, size: 48),
            const SizedBox(height: 12),
            Text(
              l10n.yourFamilyCode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                code,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.familyCodeCopied),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: Text(l10n.copyCode),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    final box = context.findRenderObject() as RenderBox?;
                    Share.share(
                      '${l10n.shareFamilyMessageTitle}\n\n'
                      '${l10n.shareFamilyCodeLabel}: $code\n\n'
                      '${l10n.shareFamilyInstructions}',
                      subject: l10n.shareFamilySubject,
                      sharePositionOrigin:
                          box!.localToGlobal(Offset.zero) & box.size,
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: Text(l10n.shareButton),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinFamilySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.familyPlanTileTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.familyCodeSubtitleJoin,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: l10n.shareFamilyCodeLabel,
                hintText: 'ABC123',
                prefixIcon: const Icon(Icons.vpn_key),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _handleJoinFamily,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(l10n.familyPlanTileTitle),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersList(bool isOwner, int totalMembers) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.familyMembers,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$totalMembers/$_maxMembers',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_familyMembers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('No family members yet'),
                ),
              )
            else
              ..._familyMembers.map((member) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.shade700,
                    child: Text(
                      member['displayName'].substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(member['displayName']),
                  subtitle: Text(member['email']),
                  trailing: member['isOwner']
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.owner,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : (isOwner
                          ? IconButton(
                              icon: const Icon(Icons.remove_circle,
                                  color: Colors.red),
                              onPressed: () =>
                                  _handleRemoveMember(member['uid']),
                            )
                          : null),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCostBreakdown(int totalMembers) {
    final extraCost = _extraSlots * AppConstants.familyExtraMemberPrice;
    final totalCost = AppConstants.familyMonthlyPrice + extraCost;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.monthlyCostBreakdown,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCostRow(
              l10n.basePlan(5),
              '\$${AppConstants.familyMonthlyPrice.toStringAsFixed(2)}',
            ),
            if (_extraSlots > 0) ...[
              const SizedBox(height: 8),
              _buildCostRow(
                'Extra Slots ($_extraSlots ÃƒÆ’Ã¢â‚¬â€ \$${AppConstants.familyExtraMemberPrice.toStringAsFixed(2)})',
                '\$${extraCost.toStringAsFixed(2)}',
              ),
            ],
            const Divider(height: 24),
            _buildCostRow(
              l10n.totalMonthlyCost,
              '\$${totalCost.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, String amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: FontWeight.bold,
            color: isTotal ? Colors.purple.shade700 : Colors.black,
          ),
        ),
      ],
    );
  }

  Future<void> _handleJoinFamily() async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-character code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await _familyService.joinFamilyPlan(authProvider.user!.uid, code);
      await authProvider.loadUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined family plan!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadFamilyMembers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRemoveMember(String memberId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: const Text(
            'Are you sure you want to remove this member from your family plan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await _familyService.removeFamilyMember(authProvider.user!.uid, memberId);
      await authProvider.loadUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Member removed from family plan'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadFamilyMembers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}



