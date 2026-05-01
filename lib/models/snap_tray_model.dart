// ============================================================
// snap_tray_model.dart
// Models for the tray RPCs: get_space_snaps_tray / get_snaps_tray
// ============================================================

/// A single bubble in the snap tray — one per sender.
class SnapTrayItem {
  final String senderId;
  final String senderName;
  final String? avatarKey;    // preset avatar storage key
  final String? photoKey;     // real profile photo storage key (priority)
  final int    totalSnaps;
  final int    unseenCount;
  final String? previewStoragePath; // latest snap's storage_path for thumbnail
  final String storageBucket;       // bucket for preview_storage_path
  String?      previewSignedUrl;   // signed URL filled by service after fetch
  final bool   isMine;
  final bool   hasNew;        // true = has unseen snaps from this sender
  final bool   postedToday;   // true = this sender posted today
  final int    sortKey;       // backend sort order (unseen-first)
  final DateTime latestAt;    // latest snap's created_at

  /// Spaces this sender has snaps in (home tray only).
  /// Each entry: { space_id, space_name, space_type, unseen_count }
  final List<Map<String, dynamic>> spaces;

  SnapTrayItem({
    required this.senderId,
    required this.senderName,
    this.avatarKey,
    this.photoKey,
    required this.totalSnaps,
    required this.unseenCount,
    this.previewStoragePath,
    this.storageBucket = 'habit-snaps',
    this.previewSignedUrl,
    required this.isMine,
    required this.hasNew,
    required this.postedToday,
    required this.sortKey,
    required this.latestAt,
    this.spaces = const [],
  });

  factory SnapTrayItem.fromJson(Map<String, dynamic> j) => SnapTrayItem(
    senderId:
      (j['sender_id'] ??
          (j['sender'] is Map
            ? (j['sender'] as Map)['id']
            : null) ??
          '')
        .toString(),
    senderName:
      (j['sender_name'] as String?) ??
      (j['display_name'] as String?) ??
      ((j['sender'] is Map
          ? (j['sender'] as Map)['display_name']
          : null)
        as String?) ??
      'User',
    avatarKey:
      (j['avatar_key'] as String?) ??
      ((j['sender'] is Map
          ? (j['sender'] as Map)['avatar_key']
          : null)
        as String?),
    photoKey:
      (j['photo_key'] as String?) ??
      ((j['sender'] is Map
          ? (j['sender'] as Map)['photo_key']
          : null)
        as String?),
    totalSnaps:         (j['total_snaps']        as num?)?.toInt() ?? 0,
    unseenCount:        (j['unseen_count']       as num?)?.toInt() ?? 0,
    previewStoragePath: j['preview_storage_path'] as String?,
    storageBucket:      j['storage_bucket']      as String? ?? 'habit-snaps',
    isMine:             j['is_mine']             as bool? ?? false,
    hasNew:             j['has_new']             as bool? ?? false,
    postedToday:        j['posted_today']        as bool? ?? false,
    sortKey:            (j['sort_key']           as num?)?.toInt() ?? 999,
    latestAt:           j['latest_at'] != null
                          ? DateTime.parse(j['latest_at'] as String)
                          : j['latest_snap_at'] != null
                              ? DateTime.parse(j['latest_snap_at'] as String)
                              : DateTime.now(),
    spaces:             j['spaces'] != null
                          ? List<Map<String, dynamic>>.from(
                              (j['spaces'] as List).map(
                                (e) => Map<String, dynamic>.from(e as Map)))
                          : const [],
  );
}

/// Full tray response from get_space_snaps_tray / get_snaps_tray.
class SnapTrayResponse {
  final List<SnapTrayItem> tray;
  final bool   iPostedToday;
  final int    totalActiveSnaps;
  final int    unseenCount;

  SnapTrayResponse({
    required this.tray,
    required this.iPostedToday,
    required this.totalActiveSnaps,
    required this.unseenCount,
  });

  factory SnapTrayResponse.fromJson(Map<String, dynamic> j) => SnapTrayResponse(
    tray: (j['tray'] as List? ?? [])
            .map((e) => SnapTrayItem.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
    iPostedToday:    j['i_posted_today']     as bool? ?? false,
    totalActiveSnaps: (j['total_active_snaps'] as num?)?.toInt() ?? 0,
    unseenCount:      ((j['unseen_count'] ?? j['total_unseen']) as num?)?.toInt() ?? 0,
  );

  /// Whether the tray has any items.
  bool get isEmpty => tray.isEmpty;
  bool get isNotEmpty => tray.isNotEmpty;
}
