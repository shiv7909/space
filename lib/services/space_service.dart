import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/space_model.dart';
import '../models/invite_model.dart';

class SpaceService {
  final SupabaseClient supabaseClient;

  SpaceService({required this.supabaseClient});

  /// Create a new space via the `create_space` RPC (SECURITY DEFINER).
  Future<SpaceModel> createSpace({
    required String name,
    required String type,
    String visibility = 'private',
    String? description,
    String? categoryId,
  }) async {
    try {
      print('🔵 SpaceService: Creating space via RPC...');

      final response = await supabaseClient.rpc(
        'create_space',
        params: {
          'p_name': name,
          'p_type': type,
          'p_visibility': visibility,
          'p_description': description,
          'p_category_id': categoryId,
        },
      );

      final data = Map<String, dynamic>.from(response as Map);
      print('🟢 SpaceService: create_space RPC response: $data');

      final isSuccess = data['success'] == true || data['status'] == 200;
      if (!isSuccess) {
        final code = data['code'] as String? ?? '';
        final message = switch (code) {
          'LOCATION_REQUIRED' =>
            'Enable location to create a Nearby space, or choose Public or Private instead.',
          'SOLO_MUST_BE_PRIVATE' =>
            'Solo spaces must be Private — they can\'t be discovered publicly.',
          _ => data['message'] as String? ?? 'Failed to create space',
        };
        throw Exception(message);
      }

      final spaceJson =
          (data['space'] as Map<String, dynamic>?) ??
          (data['data'] as Map<String, dynamic>?) ??
          (data.containsKey('id') ? data : null);
      if (spaceJson == null) {
        throw Exception('create_space RPC did not return space data');
      }

      print('🟢 SpaceService: Space created: ${spaceJson['id']}');
      return SpaceModel.fromJson(spaceJson);
    } catch (e) {
      print('🔴 SpaceService: Error creating space: $e');
      rethrow;
    }
  }

  /// Get all spaces for a user
  Future<List<SpaceModel>> getUserSpaces(String userId) async {
    try {
      print('🔵 SpaceService: Fetching spaces for user: $userId');

      final response = await supabaseClient
          .from('space_members')
          .select('space_id, spaces(*)')
          .eq('user_id', userId);

      final spaces =
          (response as List)
              .map((item) => SpaceModel.fromJson(item['spaces']))
              .toList();

      print('🟢 SpaceService: Found ${spaces.length} spaces');
      return spaces;
    } catch (e) {
      print('🔴 SpaceService: Error fetching spaces: $e');
      return [];
    }
  }

  /// Get members of a space
  Future<List<String>> getSpaceMembers(String spaceId) async {
    try {
      final response = await supabaseClient
          .from('space_members')
          .select('user_id')
          .eq('space_id', spaceId);

      return (response as List)
          .map((item) => item['user_id'] as String)
          .toList();
    } catch (e) {
      print('🔴 SpaceService: Error fetching space members: $e');
      return [];
    }
  }

  /// Get the real member count for a space directly from space_members.
  Future<int> getSpaceMemberCount(String spaceId) async {
    try {
      final response =
          await supabaseClient
              .from('space_members')
              .select('user_id')
              .eq('space_id', spaceId)
              .count();
      return response.count;
    } catch (e) {
      print('🔴 SpaceService: Error fetching member count: $e');
      return 0;
    }
  }

  /// Add a member to an existing space
  Future<void> addMemberToSpace({
    required String spaceId,
    required String userId,
  }) async {
    try {
      await supabaseClient.from('space_members').insert({
        'space_id': spaceId,
        'user_id': userId,
      });

      print('🟢 SpaceService: Added member $userId to space $spaceId');
    } catch (e) {
      print('🔴 SpaceService: Error adding member to space: $e');
      rethrow;
    }
  }

  /// Remove a member from a space
  Future<void> removeMemberFromSpace({
    required String spaceId,
    required String userId,
  }) async {
    try {
      await supabaseClient
          .from('space_members')
          .delete()
          .eq('space_id', spaceId)
          .eq('user_id', userId);

      print('🟢 SpaceService: Removed member $userId from space $spaceId');

      // ── Also clean up ALL invite records for this user+space ──
      // This removes the 'accepted' row so they can be re-invited later
      // without hitting the unique constraint (space_id, invited_user, status).
      await supabaseClient
          .from('space_invites')
          .delete()
          .eq('space_id', spaceId)
          .eq('invited_user', userId);

      print(
        '🟢 SpaceService: Cleaned up invite records for $userId in space $spaceId',
      );
    } catch (e) {
      print('🔴 SpaceService: Error removing member from space: $e');
      rethrow;
    }
  }

  /// Delete a space (only by creator)
  Future<void> deleteSpace(String spaceId) async {
    try {
      await supabaseClient.from('spaces').delete().eq('id', spaceId);

      print('🟢 SpaceService: Deleted space $spaceId');
    } catch (e) {
      print('🔴 SpaceService: Error deleting space: $e');
      rethrow;
    }
  }

  /// Add member by QR scan using RPC with status code handling
  Future<Map<String, dynamic>> addMemberByScan({
    required String targetUserId,
    required String targetSpaceId,
  }) async {
    try {
      print(
        '🔵 SpaceService: Adding member via RPC - User: $targetUserId, Space: $targetSpaceId',
      );

      final response = await supabaseClient.rpc(
        'add_member_by_scan',
        params: {
          'target_user_id': targetUserId,
          'target_space_id': targetSpaceId,
        },
      );

      print('🟢 SpaceService: RPC response: $response');

      return {
        'status': response['status'] as int,
        'message': response['message'] as String,
      };
    } catch (e) {
      print('🔴 SpaceService: Error calling add_member_by_scan RPC: $e');
      return {
        'status': 500,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  /// Search for a user by email using RPC (calls search_user_by_email)
  Future<Map<String, dynamic>> searchUserByEmail(String email) async {
    try {
      print('🔵 SpaceService: Searching user by email via RPC...');

      final response = await supabaseClient.rpc(
        'search_user_by_email',
        params: {'p_email': email},
      );

      print('🟢 SpaceService: search_user_by_email response: $response');
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      print('🔴 SpaceService: Error calling search_user_by_email RPC: $e');
      return {
        'success': false,
        'code': 'CLIENT_ERROR',
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  /// Search for a user by UUID using RPC (calls search_user_by_id — for QR scan preview)
  Future<Map<String, dynamic>> searchUserById(String userId) async {
    try {
      print('🔵 SpaceService: Searching user by ID via RPC...');

      final response = await supabaseClient.rpc(
        'search_user_by_id',
        params: {'p_user_id': userId},
      );

      print('🟢 SpaceService: search_user_by_id response: $response');
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      print('🔴 SpaceService: Error calling search_user_by_id RPC: $e');
      return {
        'success': false,
        'code': 'CLIENT_ERROR',
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  /// Add member by email using RPC with full status code handling
  Future<Map<String, dynamic>> addMemberByEmail({
    required String email,
    required String spaceId,
  }) async {
    try {
      print(
        '🔵 SpaceService: Adding member by email via RPC - Email: $email, Space: $spaceId',
      );

      final response = await supabaseClient.rpc(
        'add_member_by_email',
        params: {'p_email': email, 'p_space_id': spaceId},
      );

      print('🟢 SpaceService: add_member_by_email response: $response');

      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      print('🔴 SpaceService: Error calling add_member_by_email RPC: $e');
      return {
        'status': 500,
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  /// Create a new habit (smart habit) - can be solo or in a space
  /// Returns the full RPC response map on success.
  Future<Map<String, dynamic>> addSmartHabit({
    required String name,
    String? whyReason,
    String emoji = '🔥',
    String mode = 'infinite',
    int? targetDays,
    List<int> scheduledDays = const [1, 2, 3, 4, 5, 6, 7],
    String? spaceId,
    String? categoryId,
  }) async {
    try {
      print('🔵 SpaceService: Adding smart habit...');

      final response = await supabaseClient.rpc(
        'add_habit_smart',
        params: {
          'p_name': name,
          'p_why_reason': whyReason,
          'p_emoji': emoji,
          'p_mode': mode,
          'p_target_days': targetDays,
          'p_scheduled_days': scheduledDays,
          'p_space_id': spaceId,
          'p_category_id': categoryId,
        },
      );

      final data = Map<String, dynamic>.from(response as Map);
      print('🟢 SpaceService: Smart habit added: $data');

      // Support both RPC formats:
      //  • New: { success: true/false, ... }
      //  • Old: { status: 200/500, ... }
      final isSuccess = data['success'] == true || data['status'] == 200;

      if (!isSuccess) {
        // Handle duplicate key constraint gracefully
        final code = data['code']?.toString();
        
        if (code == 'HABIT_LIMIT_REACHED') {
          throw Exception(
            'HABIT_LIMIT_REACHED|${data['message'] ?? 'This space already has 5 habits. Delete one before adding a new habit.'}',
          );
        }
        
        if (code == '23505') {
          throw Exception(
            'This habit already exists. Try a different name or check your existing habits.',
          );
        }
        throw Exception(data['message'] ?? 'Unknown error occurred');
      }

      return data;
    } catch (e) {
      print('🔴 SpaceService: Error adding smart habit: $e');
      rethrow;
    }
  }

  /// Fetch habits for a specific space
  /// If spaceId is null, it attempts to find and fetch the user's Solo space habits
  Future<List<Map<String, dynamic>>> getHabits({String? spaceId}) async {
    try {
      print('🔵 SpaceService: Fetching habits...');

      String? targetSpaceId = spaceId;

      // If no space ID provided, allow smart retrieval for "Solo" space
      if (targetSpaceId == null) {
        final userId = supabaseClient.auth.currentUser?.id;
        if (userId == null) return [];

        final soloSpace =
            await supabaseClient
                .from('spaces')
                .select('id')
                .eq('created_by', userId)
                .eq('type', 'solo')
                .maybeSingle();

        if (soloSpace != null) {
          targetSpaceId = soloSpace['id'] as String;
        } else {
          print('🟡 SpaceService: No solo space found for user.');
          return [];
        }
      }

      // Fetch habits for the determined space
      final response = await supabaseClient
          .from('habits')
          .select()
          .eq('space_id', targetSpaceId)
          .eq('is_archived', false) // Only active habits
          .order('created_at', ascending: false);

      print(
        '🟢 SpaceService: Fetched ${response.length} habits for space $targetSpaceId',
      );

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('🔴 SpaceService: Error fetching habits: $e');
      return [];
    }
  }

  /// Fetch the Solo Dashboard — calls get_dashboard_solo() RPC.
  Future<Map<String, dynamic>> getSoloDashboard({
    required String spaceId,
    required String userId,
  }) async {
    try {
      print('🔵 SpaceService: Fetching Solo Dashboard...');

      final response = await supabaseClient.rpc(
        'get_dashboard_solo',
        params: {'p_space_id': spaceId, 'p_user_id': userId},
      );

      print('🟢 SpaceService: Solo Dashboard fetched');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('🟡 SpaceService: Error fetching solo dashboard: $e');
      return {'alerts': [], 'habits': [], 'space_type': 'solo'};
    }
  }

  /// Fetch the Group Dashboard — calls get_dashboard_group() RPC.
  Future<Map<String, dynamic>> getGroupDashboard({
    required String spaceId,
    required String userId,
  }) async {
    try {
      print('🔵 SpaceService: Fetching Group Dashboard...');

      final response = await supabaseClient.rpc(
        'get_dashboard_group',
        params: {'p_space_id': spaceId, 'p_user_id': userId},
      );

      print('🟢 SpaceService: Group Dashboard fetched');
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('🟡 SpaceService: Error fetching group dashboard: $e');
      return {'alerts': [], 'habits': [], 'space_type': 'group'};
    }
  }

  /// Fetch the Couple Dashboard Data — calls get_dashboard_couple()
  /// Returns the full JSON payload including partner stats, combined calendar,
  /// message engine, challenge progress, etc.
  Future<Map<String, dynamic>> getCoupleDashboard({
    required String spaceId,
    required String userId,
  }) async {
    try {
      print('🔵 SpaceService: Fetching Couple Dashboard...');

      final response = await supabaseClient.rpc(
        'get_dashboard_couple',
        params: {'p_space_id': spaceId, 'p_user_id': userId},
      );

      print('🟢 SpaceService: Couple Dashboard fetched');

      if (response == null) {
        print('🟡 SpaceService: Couple dashboard returned null');
        return {
          'space_type': 'couple',
          'partner_id': null,
          'status': 'error',
          'message': 'No data returned from server',
          'habits': [],
        };
      }

      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('🔴 SpaceService: Error fetching couple dashboard: $e');
      return {
        'space_type': 'couple',
        'partner_id': null,
        'status': 'error',
        'message': 'Failed to load duo dashboard: ${e.toString()}',
        'habits': [],
      };
    }
  }

  /// Update an existing habit's name, why reason, and emoji
  Future<void> updateHabit({
    required String habitId,
    required String name,
    String? whyReason,
    required String emoji,
  }) async {
    try {
      print('🔵 SpaceService: Updating habit $habitId...');
      await supabaseClient
          .from('habits')
          .update({'name': name, 'why_reason': whyReason, 'emoji': emoji})
          .eq('id', habitId);
      print('🟢 SpaceService: Habit updated successfully');
    } catch (e) {
      print('🔴 SpaceService: Error updating habit: $e');
      rethrow;
    }
  }

  /// Permanently delete a habit and all its completion records
  Future<void> deleteHabit(String habitId) async {
    try {
      print('🔵 SpaceService: Deleting habit $habitId...');
      await supabaseClient.from('habit_logs').delete().eq('habit_id', habitId);
      await supabaseClient.from('habits').delete().eq('id', habitId);
      print('🟢 SpaceService: Habit deleted successfully');
    } catch (e) {
      print('🔴 SpaceService: Error deleting habit: $e');
      rethrow;
    }
  }

  /// Complete a solo habit — calls complete_solo_habit() RPC.
  /// User identity is taken from the Supabase auth session (auth.uid()).
  /// Returns the full JSON payload from the function.
  Future<Map<String, dynamic>> completeSoloHabit({
    required String habitId,
  }) async {
    try {
      print('🔵 SpaceService: Completing solo habit $habitId...');
      final response = await supabaseClient.rpc(
        'complete_solo_habit',
        params: {'p_habit_id': habitId},
      );

      final data = Map<String, dynamic>.from(response as Map);
      print('🟢 SpaceService: complete_solo_habit response: $data');
      return data;
    } catch (e) {
      print('🔴 SpaceService: Error completing solo habit: $e');
      rethrow;
    }
  }

  /// Complete a couple/duo habit — calls complete_duo_habit() RPC.
  /// User identity is taken from the Supabase auth session (auth.uid()).
  /// Returns the full JSON payload from the function.
  Future<Map<String, dynamic>> completeDuoHabit({
    required String habitId,
  }) async {
    try {
      print('🔵 SpaceService: Completing duo habit $habitId...');
      final response = await supabaseClient.rpc(
        'complete_duo_habit',
        params: {'p_habit_id': habitId},
      );

      final data = Map<String, dynamic>.from(response as Map);
      print('🟢 SpaceService: complete_duo_habit response: $data');
      return data;
    } catch (e) {
      print('🔴 SpaceService: Error completing duo habit: $e');
      rethrow;
    }
  }

  /// Complete a group habit — calls complete_group_habit() RPC.
  /// User identity is taken from the Supabase auth session (auth.uid()).
  /// Returns the full JSON payload from the function.
  Future<Map<String, dynamic>> completeGroupHabit({
    required String habitId,
  }) async {
    try {
      print('🔵 SpaceService: Completing group habit $habitId...');
      final response = await supabaseClient.rpc(
        'complete_group_habit',
        params: {'p_habit_id': habitId},
      );

      final data = Map<String, dynamic>.from(response as Map);
      print('🟢 SpaceService: complete_group_habit response: $data');
      return data;
    } catch (e) {
      print('🔴 SpaceService: Error completing group habit: $e');
      rethrow;
    }
  }

  /// Dismiss a completed/failed challenge result — calls dismiss_challenge_result() RPC.
  /// After this, the habit moves out of ended_habits and into history.
  Future<void> dismissChallengeResult({required String habitId}) async {
    try {
      print('🔵 SpaceService: Dismissing challenge result for $habitId...');
      await supabaseClient.rpc(
        'dismiss_challenge_result',
        params: {'p_habit_id': habitId},
      );
      print('🟢 SpaceService: Challenge result dismissed');
    } catch (e) {
      print('🔴 SpaceService: Error dismissing challenge result: $e');
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // NUDGE SYSTEM
  // ═══════════════════════════════════════════════════════════════════════

  /// Send a nudge to a partner — calls send_nudge(p_habit_id) RPC.
  /// Never insert into couple_nudges directly; always use this method.
  ///
  /// Returns the full JSON response from the function. Callers should inspect
  /// response['code'] to determine what happened:
  ///   'NUDGED'         — nudge sent successfully
  ///   'ALREADY_DONE'   — partner already completed this habit today
  ///   'ALREADY_NUDGED' — current user already nudged today
  ///   'NO_PARTNER'     — space has no partner yet
  ///   'HABIT_NOT_FOUND', 'NOT_COUPLE_HABIT', 'NOT_A_MEMBER' — edge cases
  Future<Map<String, dynamic>> sendNudge({required String habitId}) async {
    try {
      print('🔵 SpaceService: Sending nudge for habit $habitId...');
      final response = await supabaseClient.rpc(
        'send_nudge',
        params: {'p_habit_id': habitId},
      );
      final data = Map<String, dynamic>.from(response as Map);
      print('🟢 SpaceService: send_nudge response: $data');
      return data;
    } catch (e) {
      print('🔴 SpaceService: Error sending nudge: $e');
      return {
        'success': false,
        'code': 'CLIENT_ERROR',
        'message': 'Something went wrong, try again',
      };
    }
  }

  /// Returns true if [userId] has already nudged [habitId] today (IST date).
  /// Uses a direct query on couple_nudges — RLS allows space members to read.
  Future<bool> hasNudgedToday({
    required String habitId,
    required String userId,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final result =
          await supabaseClient
              .from('couple_nudges')
              .select('id')
              .eq('habit_id', habitId)
              .eq('sender_id', userId)
              .eq('nudge_date', today)
              .maybeSingle();
      return result != null;
    } catch (e) {
      print(
        '🟡 SpaceService: hasNudgedToday check failed ($e) — defaulting false',
      );
      return false;
    }
  }

  /// Mark all unseen nudges for [habitId] directed at [userId] as seen.
  /// Uses a direct update — RLS allows target_user_id = auth.uid() updates.
  Future<void> markNudgesSeen({
    required String habitId,
    required String userId,
  }) async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);
      await supabaseClient
          .from('couple_nudges')
          .update({'is_seen': true})
          .eq('target_user_id', userId)
          .eq('habit_id', habitId)
          .eq('nudge_date', today);
    } catch (e) {
      // Non-fatal — silently swallow
      print('🟡 SpaceService: markNudgesSeen failed ($e)');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // INVITE SYSTEM
  // ═══════════════════════════════════════════════════════════════════════

  /// Send an invite by email — calls send_invite_by_email() RPC
  Future<Map<String, dynamic>> sendInviteByEmail({
    required String email,
    required String spaceId,
  }) async {
    try {
      print('🔵 SpaceService: Sending invite by email — $email → $spaceId');

      final response = await supabaseClient.rpc(
        'send_invite_by_email',
        params: {'p_email': email, 'p_space_id': spaceId},
      );

      print('🟢 SpaceService: send_invite_by_email response: $response');
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      print('🔴 SpaceService: Error sending invite by email: $e');
      return {
        'success': false,
        'code': 'CLIENT_ERROR',
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  /// Send an invite by QR scan — calls send_invite_by_scan() RPC
  Future<Map<String, dynamic>> sendInviteByScan({
    required String userId,
    required String spaceId,
  }) async {
    try {
      print('🔵 SpaceService: Sending invite by scan — $userId → $spaceId');

      final response = await supabaseClient.rpc(
        'send_invite_by_scan',
        params: {'p_user_id': userId, 'p_space_id': spaceId},
      );

      print('🟢 SpaceService: send_invite_by_scan response: $response');
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      print('🔴 SpaceService: Error sending invite by scan: $e');
      return {
        'success': false,
        'code': 'CLIENT_ERROR',
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  /// Accept a pending invite — calls accept_invite() RPC
  Future<Map<String, dynamic>> acceptInvite(
    String inviteId, {
    bool force = false,
  }) async {
    try {
      print('🔵 SpaceService: Accepting invite $inviteId (force: $force)');

      final response = await supabaseClient.rpc(
        'accept_invite',
        params: {'p_invite_id': inviteId, 'p_force': force},
      );

      print('🟢 SpaceService: accept_invite response: $response');
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      print('🔴 SpaceService: Error accepting invite: $e');
      return {
        'success': false,
        'code': 'CLIENT_ERROR',
        'message': 'Failed to accept invite: ${e.toString()}',
      };
    }
  }

  /// Reject a pending invite — calls reject_invite() RPC
  Future<Map<String, dynamic>> rejectInvite(String inviteId) async {
    try {
      print('🔵 SpaceService: Rejecting invite $inviteId');

      final response = await supabaseClient.rpc(
        'reject_invite',
        params: {'p_invite_id': inviteId},
      );

      print('🟢 SpaceService: reject_invite response: $response');
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      print('🔴 SpaceService: Error rejecting invite: $e');
      return {
        'success': false,
        'code': 'CLIENT_ERROR',
        'message': 'Failed to reject invite: ${e.toString()}',
      };
    }
  }

  /// Get all pending invites for the current user — calls get_my_pending_invites() RPC
  Future<List<InviteModel>> getMyPendingInvites() async {
    try {
      print('🔵 SpaceService: Fetching pending invites...');

      final response = await supabaseClient.rpc('get_my_pending_invites');

      print('🟢 SpaceService: get_my_pending_invites response: $response');

      if (response == null) return [];

      final List<dynamic> list = response is List ? response : [];
      return list
          .map((item) => InviteModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      print('🔴 SpaceService: Error fetching pending invites: $e');
      return [];
    }
  }

  /// Remove a space member (owner-only) — calls remove_space_member() RPC.
  /// Clears all habit logs, participant stats, and invite records for that user.
  Future<Map<String, dynamic>> removeSpaceMember({
    required String spaceId,
    required String userId,
  }) async {
    try {
      print(
        '🔵 SpaceService: Removing member $userId from space $spaceId via RPC...',
      );

      final response = await supabaseClient.rpc(
        'remove_space_member',
        params: {'p_space_id': spaceId, 'p_user_id': userId},
      );

      print('🟢 SpaceService: remove_space_member response: $response');
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      print('��� SpaceService: Error calling remove_space_member RPC: $e');
      return {
        'success': false,
        'code': 'CLIENT_ERROR',
        'message': 'An unexpected error occurred: ${e.toString()}',
      };
    }
  }

  /// Fetch home screen analytics — best streak, completions, this week %, habits, space types
  Future<Map<String, dynamic>> getMyFullAnalytics() async {
    try {
      print('🔵 SpaceService: Fetching full analytics via get_my_full_analytics...');
      final response = await supabaseClient.rpc('get_my_full_analytics');
      final data = Map<String, dynamic>.from(response as Map);
      print('🟢 SpaceService: get_my_full_analytics OK');
      return data;
    } catch (e) {
      print('🔴 SpaceService: Error fetching analytics: $e');
      return {};
    }
  }

  /// Fetch members of a space with their profile info (display_name, avatar_id).
  Future<List<Map<String, dynamic>>> getSpaceMembersWithProfiles(
    String spaceId,
  ) async {
    try {
      print(
        '🔵 SpaceService: Fetching members with profiles for space $spaceId...',
      );

      final response = await supabaseClient
          .from('space_members')
          .select('''
            user_id,
            profiles (
              id,
              display_name,
              avatar_id,
              photo_id,

              profile_photos ( photo_key )
            )
          ''')
          .eq('space_id', spaceId);

      print('🟢 SpaceService: Got ${(response as List).length} members');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('🔴 SpaceService: Error fetching space members with profiles: $e');
      return [];
    }
  }

  /// Update the visibility of a space (owner-only) — calls update_space_visibility() RPC.
  Future<void> updateSpaceVisibility({
    required String spaceId,
    required String visibility,
  }) async {
    try {
      print(
        '🔵 SpaceService: Updating space $spaceId visibility → $visibility',
      );
      await supabaseClient.rpc(
        'update_space_visibility',
        params: {'p_space_id': spaceId, 'p_visibility': visibility},
      );
      print('🟢 SpaceService: Space visibility updated');
    } catch (e) {
      print('🔴 SpaceService: Error updating space visibility: $e');
      rethrow;
    }
  }

  /// Update the description of a space (owner-only).
  Future<void> updateSpaceDescription({
    required String spaceId,
    required String description,
  }) async {
    try {
      print('🔵 SpaceService: Updating space $spaceId description');
      await supabaseClient
          .from('spaces')
          .update({'description': description})
          .eq('id', spaceId);
      print('🟢 SpaceService: Space description updated');
    } catch (e) {
      print('🔴 SpaceService: Error updating space description: $e');
      rethrow;
    }
  }

  /// Fetch one month of habit completion data — calls get_habit_full_calendar() RPC.
  /// Only hits a single DB partition (max 31 rows returned).
  /// [year] and [month] default to the current month when omitted.
  Future<HabitCalendarMonth> getHabitCalendar({
    required String habitId,
    int? year,
    int? month,
  }) async {
    final now = DateTime.now();
    final y = year ?? now.year;
    final m = month ?? now.month;

    try {
      print('🔵 SpaceService: getHabitCalendar $habitId → $y/$m');
      final response = await supabaseClient.rpc(
        'get_habit_full_calendar',
        params: {'p_habit_id': habitId, 'p_year': y, 'p_month': m},
      );
      final data = Map<String, dynamic>.from(response as Map);
      print(
        '🟢 SpaceService: getHabitCalendar OK — ${data['completed_dates']?.length ?? 0} dates',
      );
      return HabitCalendarMonth.fromJson(data, y, m);
    } catch (e) {
      print('🔴 SpaceService: getHabitCalendar error: $e');
      return HabitCalendarMonth.empty(y, m);
    }
  }
}

// ── Value object returned by getHabitCalendar ─────────────────────────────
class HabitCalendarMonth {
  final int year;
  final int month;
  final List<DateTime> completedDates;
  final bool hasPrevMonth;
  final bool hasNextMonth;
  final List<int> scheduledDays;
  final String? mode;
  final int? targetDays;
  final int totalLogs;
  final DateTime? habitStartDate;

  const HabitCalendarMonth({
    required this.year,
    required this.month,
    required this.completedDates,
    required this.hasPrevMonth,
    required this.hasNextMonth,
    required this.scheduledDays,
    this.mode,
    this.targetDays,
    this.totalLogs = 0,
    this.habitStartDate,
  });

  factory HabitCalendarMonth.fromJson(
    Map<String, dynamic> json,
    int year,
    int month,
  ) {
    final dates =
        (json['completed_dates'] as List? ?? [])
            .map((e) => DateTime.parse(e.toString()))
            .toList();

    final scheduled =
        (json['scheduled_days'] as List? ?? [1, 2, 3, 4, 5, 6, 7])
            .map((e) => e as int)
            .toList();

    DateTime? habitStart;
    if (json['habit_start_date'] != null) {
      habitStart = DateTime.tryParse(json['habit_start_date'].toString());
    }

    return HabitCalendarMonth(
      year: json['year'] as int? ?? year,
      month: json['month'] as int? ?? month,
      completedDates: dates,
      hasPrevMonth: json['has_prev_month'] as bool? ?? true,
      hasNextMonth: json['has_next_month'] as bool? ?? false,
      scheduledDays: scheduled,
      mode: json['mode'] as String?,
      targetDays: json['target_days'] as int?,
      totalLogs: json['total_logs'] as int? ?? 0,
      habitStartDate: habitStart,
    );
  }

  factory HabitCalendarMonth.empty(int year, int month) {
    return HabitCalendarMonth(
      year: year,
      month: month,
      completedDates: [],
      hasPrevMonth: false,
      hasNextMonth: false,
      scheduledDays: [1, 2, 3, 4, 5, 6, 7],
      totalLogs: 0,
    );
  }

  /// Check if a specific date was completed
  bool isCompleted(DateTime date) => completedDates.any(
    (d) => d.year == date.year && d.month == date.month && d.day == date.day,
  );

  DateTime get monthStart => DateTime(year, month, 1);
  DateTime get monthEnd => DateTime(year, month + 1, 0);
}
