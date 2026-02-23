/// 🚫 GIGMATCH Blocked Users Screen
///
/// Shows all users the current user has blocked.
/// Allows unblocking from this screen.
library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/theme.dart';
import '../core/api/api.dart';
import '../core/services/services.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final client = ApiClient();
      final response = await client.dio.get(Endpoints.blockedUsers);

      if (response.data != null && response.data is List) {
        setState(() {
          _blockedUsers = (response.data as List)
              .map((item) => item as Map<String, dynamic>)
              .toList();
          _isLoading = false;
        });
        debugPrint(
          '🚫 [BlockedUsers] Loaded ${_blockedUsers.length} blocked users',
        );
      } else {
        setState(() {
          _blockedUsers = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ [BlockedUsers] Load error: $e');
      setState(() {
        _error = 'Failed to load blocked users';
        _isLoading = false;
      });
    }
  }

  Future<void> _unblockUser(String matchId, String userName) async {
    // Confirm unblock
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unblock User'),
        content: Text(
          'Are you sure you want to unblock $userName? '
          'They will be able to see your profile and message you again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.crimson),
            child: const Text('Unblock'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) { return; }

    try {
      final chatService = ChatService();
      await chatService.unblockConversation(matchId);

      if (mounted) {
        setState(() {
          _blockedUsers.removeWhere((u) => u['id'] == matchId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$userName has been unblocked'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [BlockedUsers] Unblock error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to unblock user'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Scaffold(
      backgroundColor: AppColors.background(brightness),
      appBar: AppBar(
        title: const Text('Blocked Users'),
        backgroundColor: AppColors.surface(brightness),
        foregroundColor: AppColors.text(brightness),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(brightness)
              : _blockedUsers.isEmpty
                  ? _buildEmpty(brightness)
                  : _buildList(brightness),
    );
  }

  Widget _buildError(Brightness brightness) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.crimson,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Unknown error',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loadBlockedUsers,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.crimson,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(Brightness brightness) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.crimson.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.block_rounded,
                size: 48,
                color: AppColors.textSec(brightness),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Blocked Users',
              style: TextStyle(
                color: AppColors.text(brightness),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t blocked anyone yet.',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(Brightness brightness) {
    return RefreshIndicator(
      onRefresh: _loadBlockedUsers,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _blockedUsers.length,
        separatorBuilder: (_, _) => Divider(
          height: 1,
          indent: 80,
          color: AppColors.divider(brightness),
        ),
        itemBuilder: (context, index) {
          final user = _blockedUsers[index];
          final otherUser =
              user['otherUser'] as Map<String, dynamic>? ?? {};
          final name = otherUser['name']?.toString() ?? 'Unknown User';
          final photo = otherUser['profilePhoto']?.toString();
          final type = otherUser['type']?.toString() ?? '';
          final matchId = user['id']?.toString() ?? '';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 8,
            ),
            leading: CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.crimson.withValues(alpha: 0.1),
              backgroundImage: photo != null && photo.isNotEmpty
                  ? CachedNetworkImageProvider(photo)
                  : null,
              child: photo == null || photo.isEmpty
                  ? Icon(Icons.person_rounded,
                      color: AppColors.textSec(brightness))
                  : null,
            ),
            title: Text(
              name,
              style: TextStyle(
                color: AppColors.text(brightness),
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: Text(
              type.isNotEmpty
                  ? '${type[0].toUpperCase()}${type.substring(1)}'
                  : '',
              style: TextStyle(
                color: AppColors.textSec(brightness),
                fontSize: 13,
              ),
            ),
            trailing: OutlinedButton(
              onPressed: () => _unblockUser(matchId, name),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.crimson,
                side: BorderSide(
                  color: AppColors.crimson.withValues(alpha: 0.5),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: const Text('Unblock'),
            ),
          );
        },
      ),
    );
  }
}
